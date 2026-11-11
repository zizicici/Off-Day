import Foundation
import GRDB
import MoreKit
import os
import UIKit
import WidgetKit
import ZCCalendar

extension WidgetCalendarSnapshot {
    static func make(baseCalendar: BaseCalendarManager.Config, publicPlan: PublicPlanInfo?, customDays: [CustomDay],
                     comments: [CustomComment] = [], display: WidgetCalendarDisplay? = nil,
                     interaction: WidgetCalendarInteraction? = nil, displayedMonthStart: Int? = nil) -> Self {
        let anchor = GregorianDay(year: 2000, month: .jan, day: 1).julianDay
        let cycle = (0..<baseCalendar.length).map { baseCalendar.isOff(day: GregorianDay(JDN: anchor + $0)) }
        var overrides = publicPlan?.days.mapValues { day in
            WidgetCalendarDay(isOffDay: day.type == .offDay, name: publicPlan?.displayDay(day).name)
        } ?? [:]
        var details = publicPlan?.days.mapValues { WidgetCalendarDayDetail(publicIsOffDay: $0.type == .offDay) } ?? [:]
        // Match fetchOne's first record if a restored database contains duplicate marks.
        for (index, days) in Dictionary(grouping: customDays, by: \.dayIndex) {
            guard let day = days.first else { continue }
            let key = Int(index)
            overrides[key] = WidgetCalendarDay(isOffDay: day.dayType == .offDay, name: overrides[key]?.name)
            var detail = details[key] ?? WidgetCalendarDayDetail()
            detail.customIsOffDay = day.dayType == .offDay
            details[key] = detail
        }
        var snapshot = Self(cycleStartDay: anchor, cycle: cycle, overrides: overrides, details: details,
                            display: display, interaction: interaction, displayedMonthStart: displayedMonthStart)
        snapshot.includeComments(comments)
        return snapshot
    }

    mutating func includeComments(_ comments: [CustomComment]) {
        for (index, values) in Dictionary(grouping: comments, by: \.dayIndex) {
            var detail = details?[Int(index)] ?? WidgetCalendarDayDetail()
            detail.comment = values.first?.content
            if details == nil { details = [:] }
            details?[Int(index)] = detail
        }
    }
}

extension WidgetCalendarDisplay {
    static func chineseCalendarNames(for indices: Set<Int>) -> [Int: String] {
        var names: [Int: String] = [:]
        for index in indices {
            let day = GregorianDay(JDN: index)
            guard (1901...2099).contains(day.year) else { continue }
            names[index] = ChineseCalendarManager.shared.getSolarTerm(for: day)?.name
                ?? ChineseCalendarManager.shared.findChineseDayInfo(day, variant: .chinese)?.shortDisplayString()
        }
        return names
    }
}

// The extension target has no snapshot-writing API. The app is the only publisher.
extension WidgetCalendarStore {
    @discardableResult
    static func saveSummary(_ snapshot: WidgetCalendarSnapshot, to url: URL? = nil) throws -> Bool {
        try save(snapshot.summary, to: url ?? summaryFileURL())
    }

    @discardableResult
    static func save(_ snapshot: WidgetCalendarSnapshot, to url: URL? = nil) throws -> Bool {
        guard snapshot.isValid else { throw CocoaError(.fileWriteInapplicableStringEncoding) }
        let url = try url ?? fileURL()
        guard snapshot != load(from: url) else { return false }
        let data = try JSONEncoder().encode(snapshot)
        try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        return true
    }
}

final class WidgetCalendarPublisher {
    static let shared = WidgetCalendarPublisher()

    private var pendingRefresh: DispatchWorkItem?
    private var alternativeNamesCache: (range: ClosedRange<Int>, month: Int?, locale: String, names: [Int: String])?
    private let logger = Logger(subsystem: "com.zizicici.zzz", category: "Widget")

    private init() {
        let center = NotificationCenter.default
        for name in [Notification.Name.DatabaseUpdated, .SettingsUpdate] {
            center.addObserver(self, selector: #selector(scheduleRefresh), name: name, object: nil)
        }
        for name in [UIApplication.didBecomeActiveNotification, UIApplication.significantTimeChangeNotification,
                     NSNotification.Name.NSSystemTimeZoneDidChange, NSLocale.currentLocaleDidChangeNotification] {
            center.addObserver(self, selector: #selector(refreshTimeline), name: name, object: nil)
        }
        center.addObserver(self, selector: #selector(refreshBeforeBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        refresh(forceReload: true)
    }

    @MainActor
    @discardableResult
    func publishNow() -> Bool {
        // Background intents must finish writing the shared snapshot before returning.
        refresh()
    }

    @objc private func scheduleRefresh() {
        // Run after the calendar managers process the same notification, and coalesce batch edits.
        DispatchQueue.main.async {
            self.pendingRefresh?.cancel()
            let work = DispatchWorkItem { self.refresh() }
            self.pendingRefresh = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: work)
        }
    }

    @objc private func refreshTimeline() {
        // The same calendar data needs new entry dates after a time-zone change.
        DispatchQueue.main.async { self.refresh(forceReload: true) }
    }

    @objc private func refreshBeforeBackground() {
        refresh()
    }

    @discardableResult
    private func refresh(forceReload: Bool = false) -> Bool {
        pendingRefresh?.cancel()
        pendingRefresh = nil
        do {
            guard let reader = AppDatabase.shared.reader else { return false }
            // Resolve the selected plan before publishing, independent of notification delivery order.
            PublicPlanManager.shared.load()
            let displayedMonthStart = WidgetCalendarMonthStore.current
            let snapshot = try reader.read { db -> WidgetCalendarSnapshot? in
                guard let stored = try BaseCalendarConfig.fetchOne(db) else { return nil }
                let config = BaseCalendarManager.Config.generate(by: stored)
                guard config.length > 0 else { return nil }
                return .make(baseCalendar: config, publicPlan: PublicPlanManager.shared.dataSource,
                             customDays: try CustomDay.order(CustomDay.Columns.id).fetchAll(db))
            }
            guard var snapshot else { return false }
            // Legacy widgets never need to decode comments, lunar names or editor state.
            // Publish them first so an extended-calendar cache failure cannot block them.
            let summaryChanged = try WidgetCalendarStore.saveSummary(snapshot)
            if summaryChanged || forceReload {
                for kind in WidgetKind.summaryKinds {
                    WidgetCenter.shared.reloadTimelines(ofKind: kind.rawValue)
                }
            }
            let ranges = Self.commentRanges(at: Date(), calendar: WidgetCalendarTimeline.calendar(), displayedMonthStart: displayedMonthStart)
            let comments = try reader.read { db in
                var predicate = ranges[0].contains(CustomComment.Columns.dayIndex)
                for range in ranges.dropFirst() { predicate = predicate || range.contains(CustomComment.Columns.dayIndex) }
                return (indices: try CustomComment.select(CustomComment.Columns.dayIndex).distinct().asRequest(of: Int.self).fetchAll(db),
                        values: try CustomComment.filter(predicate).order(CustomComment.Columns.id).fetchAll(db))
            }
            // Keep future comment badges correct even when the app stays closed. Full text
            // is refreshed by the main-app intent before a date's detail panel appears.
            for index in comments.indices {
                var detail = snapshot.details?[index] ?? WidgetCalendarDayDetail()
                detail.commentAvailable = true
                snapshot.details?[index] = detail
            }
            snapshot.includeComments(comments.values)
            snapshot.display = makeDisplay(displayedMonthStart: displayedMonthStart)
            snapshot.interaction = WidgetCalendarInteractionStore.current
            snapshot.displayedMonthStart = displayedMonthStart
            let changed = try WidgetCalendarStore.save(snapshot)
            if changed || forceReload {
                for kind in WidgetKind.detailedKinds {
                    WidgetCenter.shared.reloadTimelines(ofKind: kind.rawValue)
                }
            }
            return true
        } catch {
            logger.error("Failed to update widget calendar: \(error.localizedDescription)")
            return false
        }
    }

    static func commentRanges(at date: Date, calendar: Calendar, displayedMonthStart: Int?) -> [Range<Int>] {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let today = GregorianDay(year: components.year!, month: Month(rawValue: components.month!)!, day: components.day!)
        let first = GregorianDay(year: today.year, month: today.month, day: 1).julianDay
        let last = GregorianDay(JDN: today.julianDay + 7)
        let lastMonth = GregorianDay(year: last.year, month: last.month, day: 1).julianDay
        // Cover every month/period entry in the seven-day fallback timeline.
        let current = min(first, today.julianDay - 6)..<(lastMonth + 42)
        var ranges = [current]
        if let displayedMonthStart, WidgetCalendarMonthNavigation.isValid(displayedMonthStart) {
            let browsed = displayedMonthStart..<(displayedMonthStart + 42)
            if !current.contains(browsed.lowerBound) || browsed.upperBound > current.upperBound { ranges.append(browsed) }
        }
        return ranges
    }

    private func makeDisplay(displayedMonthStart: Int?) -> WidgetCalendarDisplay {
        let start = WeekStartType.getValue()
        var display = WidgetCalendarDisplay(
            firstWeekday: start == .followSystem ? nil : start.rawValue % 7 + 1,
            blueWeekends: WeekEndColorType.getValue() == .blue,
            paperHolidayWorkdays: HolidayWorkColorType.getValue() == .paper)
        if AlternativeCalendarType.getValue() == .chineseCalendar {
            let calendar = WidgetCalendarTimeline.calendar()
            let first = calendar.dateInterval(of: .month, for: Date())!.start
            let end = calendar.date(byAdding: .month, value: 14, to: first)!
            let from = calendar.dateComponents([.year, .month, .day], from: first)
            let to = calendar.dateComponents([.year, .month, .day], from: end)
            let leading = GregorianDay(year: from.year!, month: Month(rawValue: from.month!)!, day: 1).julianDay - 7
            let trailing = GregorianDay(year: to.year!, month: Month(rawValue: to.month!)!, day: 1).julianDay + 7
            let range = leading...trailing
            let locale = Locale.current.identifier
            if let cache = alternativeNamesCache, cache.range == range, cache.month == displayedMonthStart, cache.locale == locale {
                display.alternativeDays = cache.names
                return display
            }
            var indices = Set(leading...trailing)
            if let displayedMonthStart {
                indices.formUnion(displayedMonthStart..<(displayedMonthStart + 42))
            }
            display.alternativeDays = WidgetCalendarDisplay.chineseCalendarNames(for: indices)
            alternativeNamesCache = (range, displayedMonthStart, locale, display.alternativeDays)
        }
        return display
    }
}
