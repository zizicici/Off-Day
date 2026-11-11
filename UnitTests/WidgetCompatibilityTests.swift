import Foundation
import Testing
import ZCCalendar
@testable import Off_Day

@MainActor
struct WidgetCompatibilityTests {
    @Test func installedWidgetIdentifiersAndReloadGroupsShouldRemainStable() {
        let identifiers: [WidgetKind: String] = [
            .lockScreen: "LockScreenWidget", .lockScreenThreeDays: "LockScreenThreeDayWidget",
            .today: "TodayWidget", .tomorrow: "TomorrowWidget", .month: "MonthCalendarWidget",
            .twoWeeks: "TwoWeekCalendarWidget", .threeDays: "ThreeDayCalendarWidget", .countdown: "CalendarCountdownWidget"
        ]
        #expect(Set(identifiers.keys) == Set(WidgetKind.allCases))
        for (kind, identifier) in identifiers { #expect(kind.rawValue == identifier) }
        #expect(WidgetKind.summaryKinds.map(\.rawValue) == ["LockScreenWidget", "TodayWidget", "TomorrowWidget"])
        #expect(WidgetKind.detailedKinds.map(\.rawValue) == ["MonthCalendarWidget", "TwoWeekCalendarWidget", "ThreeDayCalendarWidget", "CalendarCountdownWidget", "LockScreenThreeDayWidget"])
    }

    @Test(arguments: ["Asia/Singapore", "America/Los_Angeles", "Pacific/Auckland"])
    func editorExpiryShouldOnlyAddCalendarRefreshesAndKeepMidnightDataCorrect(zone: String) throws {
        let calendar = WidgetCalendarTimeline.calendar(timeZone: try #require(TimeZone(identifier: zone)))
        for (year, month, day) in [(2026, 12, 31), (2026, 3, 7)] {
            let now = try #require(calendar.date(from: .init(year: year, month: month, day: day, hour: 23, minute: 59)))
            let today = GregorianDay(year: year, month: try #require(Month(rawValue: month)), day: day).julianDay
            let midnight = try #require(calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)))
            let horizon = try #require(calendar.date(byAdding: .day, value: 7, to: calendar.startOfDay(for: now)))
            for expiry in [now.addingTimeInterval(-1), now, now.addingTimeInterval(180), horizon, horizon.addingTimeInterval(1)] {
                let snapshot = WidgetCalendarSnapshot(cycleStartDay: today, cycle: [false],
                    overrides: [today + 1: .init(isOffDay: true, name: "Holiday")],
                    details: [today + 1: .init(publicIsOffDay: true)],
                    interaction: .init(selectedDay: today, expiresAt: expiry))
                let summary = WidgetCalendarTimeline.entries(snapshot: snapshot.summary, from: now, calendar: calendar)
                let countdown = WidgetCountdownTimeline.entries(snapshot: snapshot, from: now, calendar: calendar)
                #expect(summary.count == 8 && countdown.count == 8)
                #expect(summary[1].date == midnight && summary[1].today?.name == "Holiday")
                #expect(countdown[0].countdown?.daysRemaining == 1)
                #expect(countdown[1].countdown == nil)
                let expected = summary.map(\.date) + (expiry > now && expiry < horizon ? [expiry] : [])
                let month = WidgetMonthTimeline.entries(snapshot: snapshot, from: now, calendar: calendar)
                #expect(month.map(\.date) == expected.sorted())
                #expect(month.first { $0.date == midnight }?.days.first { $0.id == today + 1 }?.value?.name == "Holiday")
                for surface in [WidgetCalendarSurface.twoWeeks, .threeDays] {
                    let period = WidgetPeriodTimeline.entries(surface: surface, snapshot: snapshot, from: now, calendar: calendar)
                    #expect(period.map(\.date) == expected.sorted())
                    #expect(period.first { $0.date == midnight }?.days.first { $0.id == today + 1 }?.value?.name == "Holiday")
                }
            }
        }
    }
}
