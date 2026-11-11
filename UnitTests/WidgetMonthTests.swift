import AppIntents
import Foundation
import GRDB
import SwiftUI
import Testing
import UIKit
import ZCCalendar
@testable import Off_Day

@MainActor
struct WidgetMonthTests {
    @Test func tappingTheSelectedMarkShouldClearItInBothCalendars() {
        #expect(CalendarDayMarkInteraction.nextValue(current: nil, tapped: true) == true)
        #expect(CalendarDayMarkInteraction.nextValue(current: nil, tapped: false) == false)
        #expect(CalendarDayMarkInteraction.nextValue(current: true, tapped: true) == nil)
        #expect(CalendarDayMarkInteraction.nextValue(current: false, tapped: false) == nil)
        #expect(CalendarDayMarkInteraction.nextValue(current: true, tapped: false) == false)
        #expect(CalendarDayMarkInteraction.nextValue(current: false, tapped: true) == true)
    }

    @Test func calendarsShouldShareTheSameBackgroundRules() {
        let normal = CalendarDayAppearance.palette(baseIsOffDay: false, publicIsOffDay: nil, blueWeekends: true, paperHolidayWorkdays: false)
        #expect(normal == .init(backgroundAsset: "PaperColor", whiteText: false))
        let weekend = CalendarDayAppearance.palette(baseIsOffDay: true, publicIsOffDay: nil, blueWeekends: true, paperHolidayWorkdays: false)
        #expect(weekend == .init(backgroundAsset: "WeekEndColor", whiteText: true))
        let holiday = CalendarDayAppearance.palette(baseIsOffDay: false, publicIsOffDay: true, blueWeekends: true, paperHolidayWorkdays: true)
        #expect(holiday == .init(backgroundAsset: "OffDayColor", whiteText: true))
        let work = CalendarDayAppearance.palette(baseIsOffDay: true, publicIsOffDay: false, blueWeekends: true, paperHolidayWorkdays: false)
        #expect(work == .init(backgroundAsset: "WorkDayColor", whiteText: true))
        let paper = CalendarDayAppearance.palette(baseIsOffDay: true, publicIsOffDay: false, blueWeekends: true, paperHolidayWorkdays: true)
        #expect(paper == normal)
    }

    @Test(arguments: ["Asia/Singapore", "America/Los_Angeles", "Pacific/Auckland"])
    func gridShouldLeaveLeadingSlotsEmptyAndIncludeNextMonthForEveryWeekStart(zone: String) throws {
        let calendar = WidgetCalendarTimeline.calendar(timeZone: try #require(TimeZone(identifier: zone)))
        for year in [2024, 2026, 2027] {
            for month in 1...12 {
                let date = try #require(calendar.date(from: .init(year: year, month: month, day: 15)))
                for firstWeekday in 1...7 {
                    let snapshot = WidgetCalendarSnapshot(cycleStartDay: 0, cycle: [false, true], overrides: [:],
                                                          display: .init(firstWeekday: firstWeekday))
                    let entry = WidgetMonthEntry(date: date, snapshot: snapshot, calendar: calendar)
                    let dayCount = calendar.range(of: .day, in: .month, for: date)!.count
                    let expectedRows = entry.leadingEmptyCount + dayCount > 35 ? 6 : 5
                    #expect(entry.rowCount == expectedRows)
                    #expect(entry.days.count + entry.leadingEmptyCount == expectedRows * 7)
                    #expect(entry.days.first?.isCurrentMonth == true)
                    #expect(entry.days.first?.day.day == 1)
                    #expect(entry.days.last?.isCurrentMonth == (entry.leadingEmptyCount + dayCount == expectedRows * 7))
                    let weekday = entry.days.first!.day.weekdayOrder().rawValue % 7 + 1
                    #expect(entry.leadingEmptyCount == (weekday - firstWeekday + 7) % 7)
                    #expect(entry.days.allSatisfy { $0.id >= entry.days.first!.id })
                    #expect(entry.days.filter(\.isCurrentMonth).count == dayCount)
                    #expect(entry.days.filter(\.isToday).count == 1)
                    #expect(Set(entry.days.map(\.id)).count == entry.days.count)
                    #expect(zip(entry.days, entry.days.dropFirst()).allSatisfy { $1.id == $0.id + 1 })
                }
            }
        }
    }

    @Test func browsingShouldUseTheSelectedMonthAndKeepTodaysHighlightAccurate() throws {
        let calendar = WidgetCalendarTimeline.calendar()
        let now = try #require(calendar.date(from: .init(year: 2026, month: 11, day: 9)))
        let february = GregorianDay(year: 2028, month: .feb, day: 1).julianDay
        let snapshot = WidgetCalendarSnapshot(cycleStartDay: 0, cycle: [false], overrides: [:], displayedMonthStart: february)
        let entry = WidgetMonthEntry(date: now, snapshot: snapshot, calendar: calendar)
        #expect(entry.monthStartDay == february)
        #expect(entry.days.filter(\.isCurrentMonth).count == 29)
        #expect(entry.rowCount == 5)
        #expect(!entry.days.contains { $0.isToday })
        #expect(entry.previousMonthStart == GregorianDay(year: 2028, month: .jan, day: 1).julianDay)
        #expect(entry.nextMonthStart == GregorianDay(year: 2028, month: .mar, day: 1).julianDay)
        #expect(WidgetCalendarMonthNavigation.adjacent(to: GregorianDay(year: 2026, month: .dec, day: 1).julianDay, offset: 1)
                == GregorianDay(year: 2027, month: .jan, day: 1).julianDay)
        #expect(WidgetCalendarMonthNavigation.adjacent(to: GregorianDay(year: 2027, month: .jan, day: 1).julianDay, offset: -1)
                == GregorianDay(year: 2026, month: .dec, day: 1).julianDay)
        #expect(WidgetCalendarMonthNavigation.adjacent(to: GregorianDay(year: 1, month: .jan, day: 1).julianDay, offset: -1) == nil)
        #expect(WidgetCalendarMonthNavigation.adjacent(to: GregorianDay(year: 9999, month: .dec, day: 1).julianDay, offset: 1) == nil)
    }

    @Test func aMonthEndingOnTheLastSlotShouldNotGainAnExtraRow() throws {
        let calendar = WidgetCalendarTimeline.calendar()
        let date = try #require(calendar.date(from: .init(year: 2026, month: 11, day: 9)))
        let snapshot = WidgetCalendarSnapshot(cycleStartDay: 0, cycle: [false], overrides: [:], display: .init(firstWeekday: 1))
        let entry = WidgetMonthEntry(date: date, snapshot: snapshot, calendar: calendar)
        #expect(entry.rowCount == 5)
        let november2025 = GregorianDay(year: 2025, month: .nov, day: 1).julianDay
        var full = snapshot
        full.displayedMonthStart = november2025
        full.display?.firstWeekday = 2
        let fullEntry = WidgetMonthEntry(date: date, snapshot: full, calendar: calendar)
        #expect(fullEntry.rowCount == 5)
        #expect(fullEntry.days.last?.day == GregorianDay(year: 2025, month: .nov, day: 30))
        #expect(fullEntry.days.last?.isCurrentMonth == true)
    }

    @Test func hiddenPreviousMonthSelectionShouldNotShowADetailPanel() throws {
        let calendar = WidgetCalendarTimeline.calendar()
        let date = try #require(calendar.date(from: .init(year: 2026, month: 11, day: 9)))
        let previous = GregorianDay(year: 2026, month: .oct, day: 31).julianDay
        let snapshot = WidgetCalendarSnapshot(cycleStartDay: 0, cycle: [false], overrides: [:],
                                              interaction: .init(selectedDay: previous, expiresAt: date.addingTimeInterval(300)))
        let entry = WidgetMonthEntry(date: date, snapshot: snapshot, calendar: calendar)
        #expect(entry.selectedDay == nil)
    }

    @Test func monthAndSelectionShouldAdvanceAtMidnightAndExpire() throws {
        let calendar = WidgetCalendarTimeline.calendar(timeZone: try #require(TimeZone(identifier: "Asia/Singapore")))
        let now = try #require(calendar.date(from: .init(year: 2026, month: 12, day: 31, hour: 23, minute: 59)))
        let target = GregorianDay(year: 2027, month: .jan, day: 1).julianDay
        let expiry = now.addingTimeInterval(180)
        let snapshot = WidgetCalendarSnapshot(cycleStartDay: 0, cycle: [true], overrides: [:],
                                              interaction: .init(selectedDay: target, expiresAt: expiry))
        let entries = WidgetMonthTimeline.entries(snapshot: snapshot, from: now, calendar: calendar)
        #expect(entries[0].selectedDay?.id == target)
        #expect(entries[1].days.first(where: \.isCurrentMonth)?.day.year == 2027)
        #expect(entries[1].days.first(where: \.isCurrentMonth)?.day.month == .jan)
        #expect(entries.first(where: { $0.date == expiry })?.selectedDay == nil)
    }

    @Test func oldSnapshotsShouldRemainReadableAndNewDetailsShouldPreservePriority() throws {
        let data = Data(#"{"version":1,"cycleStartDay":0,"cycle":[false,true],"overrides":{}}"#.utf8)
        let old = try JSONDecoder().decode(WidgetCalendarSnapshot.self, from: data)
        #expect(old.isValid)
        #expect(old.display == nil)
        #expect(old.displayedMonthStart == nil)
        #expect(old.day(at: 1)?.isOffDay == true)
        let day = GregorianDay(year: 2026, month: .nov, day: 9)
        let plan = PublicPlanInfo(plan: .custom(.init(name: "Plan", start: day, end: day)),
                                  days: [day.julianDay: JSONPublicDay(name: "Holiday", date: day, type: .offDay)])
        let snapshot = WidgetCalendarSnapshot.make(baseCalendar: .standard(.default), publicPlan: plan,
            customDays: [.init(dayIndex: Int64(day.julianDay), dayType: .workDay)],
            comments: [.init(dayIndex: Int64(day.julianDay), content: "Meeting")])
        #expect(snapshot.baseIsOffDay(at: day.julianDay) == false)
        #expect(snapshot.details?[day.julianDay]?.publicIsOffDay == true)
        #expect(snapshot.details?[day.julianDay]?.customIsOffDay == false)
        #expect(snapshot.details?[day.julianDay]?.comment == "Meeting")
        #expect(snapshot.day(at: day.julianDay)?.isOffDay == false)
        #expect(snapshot.day(at: day.julianDay)?.name == "Holiday")
        #expect(try JSONDecoder().decode(WidgetCalendarSnapshot.self, from: JSONEncoder().encode(snapshot)) == snapshot)
    }

    @Test func assignmentsShouldBeTransactionalIdempotentAndRemoveAllDuplicateMarks() throws {
        let queue = try DatabaseQueue()
        let database = try AppDatabase(queue)
        let index = GregorianDay(year: 2036, month: .feb, day: 29).julianDay
        try queue.write { db in
            for type in [DayType.offDay, .workDay, .offDay] {
                var day = CustomDay(dayIndex: Int64(index), dayType: type)
                try day.save(db)
            }
        }
        try database.setCustomDay(.workDay, at: index)
        let first = try queue.read { try CustomDay.fetchAll($0) }
        #expect(first.count == 1)
        #expect(first.first?.dayType == .workDay)
        try database.setCustomDay(.workDay, at: index)
        #expect(try queue.read { try CustomDay.fetchAll($0) } == first)
        try database.setCustomDay(nil, at: index)
        try database.setCustomDay(nil, at: index)
        #expect(try queue.read { try CustomDay.fetchCount($0) } == 0)
        database.disconnect()
        #expect(throws: (any Error).self) { try database.setCustomDay(.offDay, at: index) }
    }
}

@Suite(.serialized)
@MainActor
struct WidgetMonthIntentTests {
    @Test @available(iOS 17.0, *)
    func editorShouldOpenOnlyInTheSelectedWidgetType() async throws {
        let previousMonth = WidgetCalendarMonthStore.current
        let previousInteraction = WidgetCalendarInteractionStore.current
        defer {
            WidgetCalendarMonthStore.current = previousMonth
            WidgetCalendarInteractionStore.current = previousInteraction
            WidgetCalendarPublisher.shared.publishNow()
        }
        WidgetCalendarMonthStore.current = nil
        let now = Date()
        let calendar = WidgetCalendarTimeline.calendar()
        let month = WidgetMonthEntry(date: now, snapshot: nil, calendar: calendar)
        let today = try #require(month.days.first { $0.isToday }).id
        for surface in WidgetCalendarSurface.allCases {
            _ = try await SelectWidgetCalendarDayIntent(dayIndex: today, surface: surface).perform()
            let snapshot = try #require(WidgetCalendarStore.load())
            #expect(snapshot.interaction?.surface == surface)
            #expect((WidgetMonthEntry(date: now, snapshot: snapshot, calendar: calendar).selectedDay != nil) == (surface == .month))
            for period in [WidgetCalendarSurface.twoWeeks, .threeDays] {
                let entry = WidgetPeriodEntry(date: now, surface: period, snapshot: snapshot, calendar: calendar)
                #expect((entry.selectedDay != nil) == (surface == period))
            }
        }
    }

    @Test @available(iOS 17.0, *)
    func allWidgetTypesShouldCommitAndDismissTheirEditors() async throws {
        let index = GregorianDay(year: 2095, month: .nov, day: 9).julianDay
        let previousMark = CustomDayManager.shared.fetchCustomDay(by: index)?.dayType
        let previousInteraction = WidgetCalendarInteractionStore.current
        defer {
            try? AppDatabase.shared.setCustomDay(previousMark, at: index)
            WidgetCalendarInteractionStore.current = previousInteraction
            WidgetCalendarPublisher.shared.publishNow()
        }
        for surface in WidgetCalendarSurface.allCases {
            for mark in [WidgetDayMark.off, .work, .automatic] {
                _ = try await SelectWidgetCalendarDayIntent(dayIndex: index, surface: surface).perform()
                _ = try await SetWidgetCalendarDayMarkIntent(dayIndex: index, mark: mark, surface: surface).perform()
                #expect(WidgetCalendarStore.load()?.interaction == nil)
                let expected: Bool? = mark == .automatic ? nil : mark == .off
                #expect(CustomDayManager.shared.fetchCustomDay(by: index).map { $0.dayType == .offDay } == expected)
                #expect(WidgetCalendarStore.load()?.details?[index]?.customIsOffDay == expected)
            }
        }
    }

    @Test func lunarSettingShouldPublishEveryVisibleDayWhenBrowsingPastMonths() throws {
        let key = UserDefaults.Settings.AlternativeCalendarType.rawValue
        let previous = UserDefaults.standard.object(forKey: key)
        let previousMonth = WidgetCalendarMonthStore.current
        defer {
            if let previous { UserDefaults.standard.set(previous, forKey: key) }
            else { UserDefaults.standard.removeObject(forKey: key) }
            WidgetCalendarMonthStore.current = previousMonth
            WidgetCalendarPublisher.shared.publishNow()
        }
        UserDefaults.standard.set(AlternativeCalendarType.chineseCalendar.rawValue, forKey: key)
        WidgetCalendarMonthStore.current = GregorianDay(year: 2025, month: .nov, day: 1).julianDay
        #expect(WidgetCalendarPublisher.shared.publishNow())
        let snapshot = try #require(WidgetCalendarStore.load())
        let entry = WidgetMonthEntry(date: Date(), snapshot: snapshot, calendar: WidgetCalendarTimeline.calendar())
        #expect(entry.days.allSatisfy { $0.alternativeName != nil })
        UserDefaults.standard.set(AlternativeCalendarType.off.rawValue, forKey: key)
        #expect(WidgetCalendarPublisher.shared.publishNow())
        #expect(WidgetCalendarStore.load()?.display?.alternativeDays.isEmpty == true)
    }

    @Test @available(iOS 17.0, *)
    func monthIntentShouldPublishAnExplicitTargetAndClearTheSelectedDate() async throws {
        let previousMonth = WidgetCalendarMonthStore.current
        let previousInteraction = WidgetCalendarInteractionStore.current
        defer {
            WidgetCalendarMonthStore.current = previousMonth
            WidgetCalendarInteractionStore.current = previousInteraction
            WidgetCalendarPublisher.shared.publishNow()
        }
        let calendar = WidgetCalendarTimeline.calendar()
        let current = WidgetMonthEntry(date: Date(), snapshot: nil, calendar: calendar)
        let next = try #require(current.nextMonthStart)
        _ = try await SelectWidgetCalendarDayIntent(dayIndex: current.monthStartDay).perform()
        for _ in 0..<2 {
            _ = try await ShowWidgetCalendarMonthIntent(monthStartDay: next).perform()
            let snapshot = try #require(WidgetCalendarStore.load())
            #expect(snapshot.displayedMonthStart == next)
            #expect(snapshot.interaction == nil)
            #expect(WidgetMonthEntry(date: Date(), snapshot: snapshot, calendar: calendar).monthStartDay == next)
        }
        _ = try await ShowWidgetCalendarMonthIntent(monthStartDay: current.monthStartDay).perform()
        #expect(WidgetCalendarMonthStore.current == nil)
        #expect(WidgetCalendarStore.load()?.displayedMonthStart == nil)
        if #available(iOS 27.0, *) {
            #expect(ShowWidgetCalendarMonthIntent.allowedExecutionTargets == .main)
        }
        await #expect(throws: WidgetCalendarIntentError.invalidDay) {
            _ = try await ShowWidgetCalendarMonthIntent(monthStartDay: next + 1).perform()
        }
        #expect(WidgetCalendarMonthStore.current == nil)
    }

    @Test @available(iOS 17.0, *)
    func widgetIntentsShouldPublishSelectionAndDatabaseChangesBeforeReturning() async throws {
        let first = GregorianDay(year: 2097, month: .nov, day: 9).julianDay
        let index = try #require((first..<(first + 100)).first {
            CustomDayManager.shared.fetchCustomDay(by: $0) == nil && PublicPlanManager.shared.publicDay(at: $0) == nil
        })
        let previous = WidgetCalendarInteractionStore.current
        defer {
            try? AppDatabase.shared.setCustomDay(nil, at: index)
            WidgetCalendarInteractionStore.current = previous
            WidgetCalendarPublisher.shared.publishNow()
        }
        _ = try await SelectWidgetCalendarDayIntent(dayIndex: index).perform()
        #expect(WidgetCalendarStore.load()?.interaction?.selectedDay == index)
        for mark in [WidgetDayMark.off, .work, .work, .automatic, .automatic] {
            _ = try await SelectWidgetCalendarDayIntent(dayIndex: index).perform()
            #expect(WidgetCalendarStore.load()?.interaction?.selectedDay == index)
            _ = try await SetWidgetCalendarDayMarkIntent(dayIndex: index, mark: mark).perform()
            let expected: Bool? = mark == .automatic ? nil : mark == .off
            #expect(CustomDayManager.shared.fetchCustomDay(by: index).map { $0.dayType == .offDay } == expected)
            #expect(WidgetCalendarStore.load()?.details?[index]?.customIsOffDay == expected)
            #expect(WidgetCalendarStore.load()?.interaction == nil)
        }
        _ = try await SelectWidgetCalendarDayIntent(dayIndex: 0).perform()
        #expect(WidgetCalendarStore.load()?.interaction == nil)
        #expect(!SetWidgetCalendarDayMarkIntent.openAppWhenRun)
        if #available(iOS 27.0, *) {
            #expect(SetWidgetCalendarDayMarkIntent.allowedExecutionTargets == .main)
            #expect(SelectWidgetCalendarDayIntent.allowedExecutionTargets == .main)
        }
    }

    @Test @available(iOS 17.0, *)
    func malformedDateShouldNotChangeTheSelection() async throws {
        let previous = WidgetCalendarInteractionStore.current
        await #expect(throws: WidgetCalendarIntentError.invalidDay) {
            _ = try await SelectWidgetCalendarDayIntent(dayIndex: -1).perform()
        }
        #expect(WidgetCalendarInteractionStore.current == previous)
        await #expect(throws: WidgetCalendarIntentError.invalidDay) {
            _ = try await SetWidgetCalendarDayMarkIntent(dayIndex: Int.max, mark: .off).perform()
        }
    }
}
