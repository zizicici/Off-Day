import Foundation
import GRDB
import MoreKit
import os
import UIKit
import WidgetKit
import ZCCalendar

extension WidgetCalendarSnapshot {
    static func make(baseCalendar: BaseCalendarManager.Config, publicPlan: PublicPlanInfo?, customDays: [CustomDay]) -> Self {
        let anchor = GregorianDay(year: 2000, month: .jan, day: 1).julianDay
        let cycle = (0..<baseCalendar.length).map { baseCalendar.isOff(day: GregorianDay(JDN: anchor + $0)) }
        var overrides = publicPlan?.days.mapValues { day in
            WidgetCalendarDay(isOffDay: day.type == .offDay, name: publicPlan?.displayDay(day).name)
        } ?? [:]
        // Match fetchOne's first record if a restored database contains duplicate marks.
        for (index, days) in Dictionary(grouping: customDays, by: \.dayIndex) {
            guard let day = days.first else { continue }
            let key = Int(index)
            overrides[key] = WidgetCalendarDay(isOffDay: day.dayType == .offDay, name: overrides[key]?.name)
        }
        return Self(cycleStartDay: anchor, cycle: cycle, overrides: overrides)
    }
}

final class WidgetCalendarPublisher {
    static let shared = WidgetCalendarPublisher()

    private var pendingRefresh: DispatchWorkItem?
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
    func publishNow() {
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

    private func refresh(forceReload: Bool = false) {
        pendingRefresh?.cancel()
        pendingRefresh = nil
        do {
            guard let reader = AppDatabase.shared.reader else { return }
            let snapshot = try reader.read { db -> WidgetCalendarSnapshot? in
                guard let stored = try BaseCalendarConfig.fetchOne(db) else { return nil }
                let config = BaseCalendarManager.Config.generate(by: stored)
                guard config.length > 0 else { return nil }
                return .make(baseCalendar: config, publicPlan: PublicPlanManager.shared.dataSource,
                             customDays: try CustomDay.fetchAll(db))
            }
            guard let snapshot else { return }
            let changed = try WidgetCalendarStore.save(snapshot)
            if changed || forceReload {
                WidgetCenter.shared.reloadAllTimelines()
            }
        } catch {
            logger.error("Failed to update widget calendar: \(error.localizedDescription)")
        }
    }
}
