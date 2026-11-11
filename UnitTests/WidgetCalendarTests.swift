import Foundation
import AppIntents
import GRDB
import Testing
import ZCCalendar
@testable import Off_Day

// ZCCalendar uses a blocking cache queue; avoid saturating the cooperative executor in parallel tests.
@MainActor
struct WidgetCalendarTests {
    @Test func snapshotShouldPreserveManualPublicAndBasePriority() throws {
        let friday = GregorianDay(year: 2026, month: .nov, day: 6)
        let saturday = friday + 1
        let sunday = friday + 2
        var plan = PublicPlanInfo(
            plan: .custom(CustomPublicPlan(name: "Test", start: friday, end: sunday)),
            days: [
                friday.julianDay: JSONPublicDay(name: "Holiday", date: friday, type: .offDay, localizedNames: ["zh-Hans": "假日"]),
                saturday.julianDay: JSONPublicDay(name: "Make-up day", date: saturday, type: .workDay),
            ])
        plan.language = "zh-Hans"
        let snapshot = WidgetCalendarSnapshot.make(
            baseCalendar: .standard(.default), publicPlan: plan,
            customDays: [CustomDay(dayIndex: Int64(friday.julianDay), dayType: .workDay),
                         CustomDay(dayIndex: Int64(saturday.julianDay), dayType: .offDay)])
        #expect(snapshot.day(at: friday.julianDay) == WidgetCalendarDay(isOffDay: false, name: "假日"))
        #expect(snapshot.day(at: saturday.julianDay) == WidgetCalendarDay(isOffDay: true, name: "Make-up day"))
        #expect(snapshot.day(at: sunday.julianDay)?.isOffDay == true)
        #expect(snapshot.day(at: sunday.julianDay + 1)?.isOffDay == false)
        let withoutMarks = WidgetCalendarSnapshot.make(baseCalendar: .standard(.default), publicPlan: plan, customDays: [])
        #expect(withoutMarks.day(at: friday.julianDay)?.isOffDay == true)
        #expect(withoutMarks.day(at: saturday.julianDay)?.isOffDay == false)
    }

    @Test func snapshotsShouldRepeatEveryCalendarPatternWithoutAnExpiry() {
        let configurations: [BaseCalendarManager.Config] = [
            .standard(.default),
            .standard(StandardConfig(weekdayOrders: [])),
            .standard(StandardConfig(weekdayOrders: [.mon, .tue, .wed, .thu, .fri, .sat, .sun])),
            .weeksCircle(WeeksCircleConfig(offset: 0, weekCount: .three, indexs: [1, 6, 10, 17])),
            .daysCircle(DaysCircleConfig(start: GregorianDay(year: 2026, month: .nov, day: 6).julianDay, workCount: 3, offCount: 2)),
        ]
        for config in configurations {
            let snapshot = WidgetCalendarSnapshot.make(baseCalendar: config, publicPlan: nil, customDays: [])
            // Both sides of the anchor exercise negative modulo and dates years after publication.
            for index in [-10_000, -1, 0, 1, 10_000] {
                for offset in 0..<config.length {
                    let day = GregorianDay(JDN: snapshot.cycleStartDay + index + offset)
                    #expect(snapshot.day(at: day.julianDay)?.isOffDay == config.isOff(day: day))
                }
            }
        }
    }

    @Test(arguments: ["Asia/Singapore", "America/Los_Angeles", "Pacific/Auckland"])
    func timelineShouldAdvanceAtLocalMidnightAcrossDSTAndYearBoundaries(zone: String) throws {
        let calendar = WidgetCalendarTimeline.calendar(timeZone: try #require(TimeZone(identifier: zone)))
        for (year, month, day) in [(2026, 3, 7), (2026, 10, 31), (2026, 12, 31)] {
            let now = try #require(calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 23, minute: 59)))
            let today = GregorianDay(year: year, month: try #require(Month(rawValue: month)), day: day)
            let snapshot = WidgetCalendarSnapshot(cycleStartDay: today.julianDay, cycle: [false], overrides: [
                today.julianDay: .init(isOffDay: false, name: "Today"),
                today.julianDay + 1: .init(isOffDay: true, name: "Tomorrow"),
                today.julianDay + 2: .init(isOffDay: false, name: "Next"),
            ])
            let entries = WidgetCalendarTimeline.entries(snapshot: snapshot, from: now, calendar: calendar)
            #expect(entries.count == 8)
            #expect(entries[0].date == now)
            #expect(entries[0].today?.name == "Today")
            #expect(entries[0].tomorrow?.name == "Tomorrow")
            #expect(entries[1].today?.name == "Tomorrow")
            #expect(entries[1].tomorrow?.name == "Next")
            for entry in entries.dropFirst() {
                #expect(calendar.component(.hour, from: entry.date) == 0)
                #expect(calendar.component(.minute, from: entry.date) == 0)
            }
        }
    }

    @Test func theSameInstantShouldUseTheDevicesLocalDate() throws {
        let now = try #require(ISO8601DateFormatter().date(from: "2026-11-06T23:30:00Z"))
        let friday = GregorianDay(year: 2026, month: .nov, day: 6)
        let snapshot = WidgetCalendarSnapshot(cycleStartDay: friday.julianDay, cycle: [false, true, true], overrides: [:])
        let singapore = WidgetCalendarEntry(date: now, snapshot: snapshot, calendar: WidgetCalendarTimeline.calendar(timeZone: try #require(TimeZone(identifier: "Asia/Singapore"))))
        let losAngeles = WidgetCalendarEntry(date: now, snapshot: snapshot, calendar: WidgetCalendarTimeline.calendar(timeZone: try #require(TimeZone(identifier: "America/Los_Angeles"))))
        #expect(singapore.today?.isOffDay == true)
        #expect(losAngeles.today?.isOffDay == false)
    }

    @Test(arguments: ["America/Santiago", "America/Havana", "Africa/Cairo"])
    func timelineShouldSwitchDaysAtMidnightAfterAMidnightDSTJump(zone: String) throws {
        let calendar = WidgetCalendarTimeline.calendar(timeZone: try #require(TimeZone(identifier: zone)))
        let month: Int
        let day: Int
        switch zone {
        case "America/Santiago": (month, day) = (9, 6)
        case "America/Havana": (month, day) = (3, 8)
        default: (month, day) = (4, 24)
        }
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 12)))
        #expect(calendar.component(.hour, from: calendar.startOfDay(for: now)) == 1)
        let today = GregorianDay(year: 2026, month: try #require(Month(rawValue: month)), day: day)
        let snapshot = WidgetCalendarSnapshot(cycleStartDay: today.julianDay, cycle: [false, true], overrides: [:])
        let entries = WidgetCalendarTimeline.entries(snapshot: snapshot, from: now, calendar: calendar)
        let nextMidnight = try #require(calendar.date(from: DateComponents(year: 2026, month: month, day: day + 1, hour: 0)))
        #expect(entries.count == 8)
        #expect(entries[1].date == nextMidnight)
        for entry in entries.dropFirst() {
            #expect(calendar.component(.hour, from: entry.date) == 0)
        }
        let halfPastMidnight = nextMidnight.addingTimeInterval(30 * 60)
        let visibleEntry = try #require(entries.last { $0.date <= halfPastMidnight })
        #expect(visibleEntry.today?.isOffDay == true)
        #expect(visibleEntry.tomorrow?.isOffDay == false)
    }

    @Test func legacySnapshotShouldRemainSmallAndIndependentOfCalendarDetails() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        let today = GregorianDay(year: 2026, month: .nov, day: 10).julianDay
        var snapshot = WidgetCalendarSnapshot(cycleStartDay: today, cycle: [false, true],
            overrides: [today: .init(isOffDay: true, name: "Holiday")],
            details: [today: .init(comment: String(repeating: "Long history ", count: 10_000))],
            display: .init(alternativeDays: [today: "初二"]),
            interaction: .init(selectedDay: today, expiresAt: Date().addingTimeInterval(300)), displayedMonthStart: today - 9)
        #expect(try WidgetCalendarStore.saveSummary(snapshot, to: url))
        let summary = try #require(WidgetCalendarStore.load(from: url))
        #expect(summary.details == nil && summary.display == nil && summary.interaction == nil && summary.displayedMonthStart == nil)
        let calendar = WidgetCalendarTimeline.calendar()
        let now = try #require(calendar.date(from: .init(year: 2026, month: 11, day: 10)))
        let original = WidgetCalendarTimeline.entries(snapshot: snapshot, from: now, calendar: calendar)
        let legacy = WidgetCalendarTimeline.entries(snapshot: summary, from: now, calendar: calendar)
        #expect(zip(original, legacy).allSatisfy { $0.today == $1.today && $0.tomorrow == $1.tomorrow })
        let data = try Data(contentsOf: url)
        #expect(data.count < 1024)
        snapshot.details?[today]?.comment = "Changed comment"
        snapshot.interaction = nil
        #expect(try !WidgetCalendarStore.saveSummary(snapshot, to: url))
        #expect(try Data(contentsOf: url) == data)
    }

    @Test(arguments: ["Asia/Singapore", "America/Los_Angeles", "Pacific/Auckland"])
    func commentWindowShouldCoverAllVisibleFallbackDatesWithoutIncludingDistantHistory(zone: String) throws {
        let calendar = WidgetCalendarTimeline.calendar(timeZone: try #require(TimeZone(identifier: zone)))
        let browsed = GregorianDay(year: 2020, month: .feb, day: 1).julianDay
        for (year, month, day) in [(2026, 11, 1), (2026, 12, 31), (2028, 2, 28)] {
            let date = try #require(calendar.date(from: .init(year: year, month: month, day: day, hour: 23, minute: 59)))
            let ranges = WidgetCalendarPublisher.commentRanges(at: date, calendar: calendar, displayedMonthStart: browsed)
            let contains: (Int) -> Bool = { index in ranges.contains { $0.contains(index) } }
            #expect(!contains(GregorianDay(year: 1999, month: .jan, day: 1).julianDay))
            #expect(ranges.reduce(0) { $0 + $1.count } <= 31 + 42 + 42)
            for entry in WidgetCalendarTimeline.entries(snapshot: nil, from: date, calendar: calendar) {
                for firstWeekday in 1...7 {
                    let snapshot = WidgetCalendarSnapshot(cycleStartDay: 0, cycle: [false], overrides: [:], display: .init(firstWeekday: firstWeekday))
                    #expect(WidgetMonthEntry(date: entry.date, snapshot: snapshot, calendar: calendar).days.allSatisfy { contains($0.id) })
                    for surface in [WidgetCalendarSurface.twoWeeks, .threeDays] {
                        #expect(WidgetPeriodEntry(date: entry.date, surface: surface, snapshot: snapshot, calendar: calendar).days.allSatisfy { contains($0.id) })
                    }
                }
            }
            let snapshot = WidgetCalendarSnapshot(cycleStartDay: 0, cycle: [false], overrides: [:], displayedMonthStart: browsed)
            #expect(WidgetMonthEntry(date: date, snapshot: snapshot, calendar: calendar).days.allSatisfy { contains($0.id) })
        }
    }

    @Test func storeShouldReplaceSnapshotsAndRejectMissingOrInvalidData() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        #expect(WidgetCalendarStore.load(from: url) == nil)
        let snapshot = WidgetCalendarSnapshot(cycleStartDay: 0, cycle: [false, true], overrides: [2: .init(isOffDay: true, name: "Holiday")])
        #expect(try WidgetCalendarStore.save(snapshot, to: url))
        #expect(WidgetCalendarStore.load(from: url) == snapshot)
        #expect(try !WidgetCalendarStore.save(snapshot, to: url))
        let replacement = WidgetCalendarSnapshot(cycleStartDay: 0, cycle: [true], overrides: [:])
        #expect(try WidgetCalendarStore.save(replacement, to: url))
        #expect(WidgetCalendarStore.load(from: url) == replacement)
        for data in [Data("corrupt".utf8),
                     try JSONEncoder().encode(WidgetCalendarSnapshot(cycleStartDay: 0, cycle: [], overrides: [:])),
                     try JSONEncoder().encode(WidgetCalendarSnapshot(version: 2, cycleStartDay: 0, cycle: [true], overrides: [:]))] {
            try data.write(to: url)
            #expect(WidgetCalendarStore.load(from: url) == nil)
        }
        let entry = WidgetCalendarEntry(date: Date(), snapshot: nil, calendar: WidgetCalendarTimeline.calendar())
        #expect(entry.today == nil)
        #expect(entry.tomorrow == nil)
    }
}

@Suite(.serialized)
@MainActor
struct WidgetCalendarPublishingTests {
    @Test(arguments: [1, 10_000])
    func updateCommentIntentShouldPublishBeforeReturning(dayOffset: Int) async throws {
        try await withCommentDay(offset: dayOffset) { index, date in
            let intent = UpdateDayCommentIntent()
            intent.date = date
            for content in ["Created comment", "Updated comment", ""] {
                intent.content = content
                #expect(try await intent.perform().value == true)
                // Read immediately: a delayed notification refresh must not satisfy this check.
                let snapshot = try #require(WidgetCalendarStore.load())
                let expected = content.isEmpty ? nil : content
                #expect(CustomDayManager.shared.fetchCustomComment(by: index)?.content == expected)
                #expect((snapshot.details?[index]?.hasComment ?? false) == !content.isEmpty)
                if dayOffset == 1 || content.isEmpty {
                    #expect(snapshot.details?[index]?.comment == expected)
                }
            }
        }
    }

    @Test(arguments: [1, 10_000])
    func deleteCommentIntentShouldPublishBeforeReturning(dayOffset: Int) async throws {
        try await withCommentDay(offset: dayOffset) { index, date in
            #expect(AppDatabase.shared.add(customComment: CustomComment(dayIndex: Int64(index), content: "Delete this comment")))
            #expect(WidgetCalendarPublisher.shared.publishNow())
            #expect(WidgetCalendarStore.load()?.details?[index]?.hasComment == true)

            let intent = DeleteDayCommentIntent()
            intent.date = date
            // Also retain the successful no-op behavior when the comment is already gone.
            for _ in 0..<2 {
                #expect(try await intent.perform().value == true)
                let snapshot = try #require(WidgetCalendarStore.load())
                #expect(CustomDayManager.shared.fetchCustomComment(by: index) == nil)
                #expect(snapshot.details?[index]?.comment == nil)
                #expect(snapshot.details?[index]?.hasComment != true)
            }
        }
    }

    private func withCommentDay(offset: Int, operation: (Int, Date) async throws -> Void) async throws {
        let calendar = WidgetCalendarTimeline.calendar()
        let date = try #require(calendar.date(byAdding: .day, value: offset, to: Date()))
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        let year = try #require(parts.year)
        let monthNumber = try #require(parts.month)
        let month = try #require(Month(rawValue: monthNumber))
        let day = try #require(parts.day)
        let index = GregorianDay(year: year, month: month, day: day).julianDay
        let writer = try #require(AppDatabase.shared.dbWriter)
        let request = CustomComment.filter(CustomComment.Columns.dayIndex == index)
        let saved = try await writer.read { try request.fetchAll($0) }
        defer {
            do {
                try writer.write { db in
                    try request.deleteAll(db)
                    for var comment in saved { try comment.insert(db) }
                }
            } catch {
                Issue.record(error, "Could not restore comment records")
            }
            WidgetCalendarPublisher.shared.publishNow()
        }
        _ = try await writer.write { try request.deleteAll($0) }
        #expect(WidgetCalendarPublisher.shared.publishNow())
        try await operation(index, date)
    }

    @Test func markIntentShouldPublishBeforeReturning() async throws {
        _ = WidgetCalendarPublisher.shared
        let first = GregorianDay(year: 2098, month: .nov, day: 6).julianDay
        let index = try #require((first..<(first + 100)).first {
            CustomDayManager.shared.fetchCustomDay(by: $0) == nil && PublicPlanManager.shared.publicDay(at: $0) == nil
        })
        defer {
            if let saved = CustomDayManager.shared.fetchCustomDay(by: index) {
                _ = AppDatabase.shared.delete(customDay: saved)
            }
        }
        let intent = UpdateDayMarkIntent()
        intent.date = try #require(GregorianDay(JDN: index).generateDate(secondsFromGMT: TimeZone.current.secondsFromGMT()))
        for mark in [DayMark.off, .work, .blank] {
            intent.mark = mark
            let result = try await intent.perform()
            #expect(result.value == true)
            let snapshot = try #require(WidgetCalendarStore.load())
            let expected: Bool? = mark == .blank ? nil : mark == .off
            #expect(snapshot.overrides[index]?.isOffDay == expected)
            let saved = CustomDayManager.shared.fetchCustomDay(by: index)
            #expect(saved.map { $0.dayType == .offDay } == expected)
        }
    }

    @Test func databaseChangesShouldPublishToTheAppGroup() async throws {
        _ = WidgetCalendarPublisher.shared
        let first = GregorianDay(year: 2100, month: .jan, day: 1).julianDay
        let index = try #require((first..<(first + 100)).first { CustomDayManager.shared.fetchCustomDay(by: $0) == nil })
        defer {
            if let day = CustomDayManager.shared.fetchCustomDay(by: index) {
                _ = AppDatabase.shared.delete(customDay: day)
            }
        }
        #expect(AppDatabase.shared.add(customDay: CustomDay(dayIndex: Int64(index), dayType: .offDay)))
        try await waitForMark(at: index, isOffDay: true)
        var saved = try #require(CustomDayManager.shared.fetchCustomDay(by: index))
        saved.dayType = .workDay
        #expect(AppDatabase.shared.update(customDay: saved))
        try await waitForMark(at: index, isOffDay: false)
        #expect(AppDatabase.shared.delete(customDay: saved))
        try await waitForMark(at: index, isOffDay: PublicPlanManager.shared.publicDay(at: index).map { $0.type == .offDay })
    }

    private func waitForMark(at index: Int, isOffDay: Bool?) async throws {
        for _ in 0..<40 {
            if WidgetCalendarStore.load()?.overrides[index]?.isOffDay == isOffDay { return }
            try await Task.sleep(for: .milliseconds(50))
        }
        #expect(WidgetCalendarStore.load()?.overrides[index]?.isOffDay == isOffDay)
    }
}
