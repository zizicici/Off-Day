import Foundation
import Testing
import ZCCalendar
@testable import Off_Day

@MainActor
struct WidgetPeriodTests {
    @Test func outerCornerArcsShouldSurviveMissingSystemCornerInformation() {
        let metrics = WidgetCalendarLayoutMetrics(size: CGSize(width: 300, height: 316), inset: 16)
        let cell = metrics.gridCellSize(rows: 5, headerHeight: 60)
        let plain = metrics.shape(size: cell)
        #expect(plain.bottomLeading == 6 && plain.bottomTrailing == 6)
        let left = metrics.shape(size: cell, bottomLeading: true)
        #expect(left.bottomLeading == 12 && left.bottomTrailing == 6)
        let right = metrics.shape(size: cell, bottomTrailing: true)
        #expect(right.bottomLeading == 6 && right.bottomTrailing == 12)
        let known = WidgetCalendarLayoutMetrics(size: metrics.size, inset: 16, bottomLeadingRadius: 36, bottomTrailingRadius: 36)
        #expect(known.shape(size: cell, bottomLeading: true).bottomLeading > left.bottomLeading)
        #expect(known.shape(size: cell, bottomLeading: true).bottomLeading <= cell.width / 2)
    }

    @Test(arguments: ["Asia/Singapore", "America/Los_Angeles", "Pacific/Auckland"])
    func periodsShouldFollowWeekStartAndIgnoreTheBrowsedMonth(zone: String) throws {
        let calendar = WidgetCalendarTimeline.calendar(timeZone: try #require(TimeZone(identifier: zone)))
        for (year, month, day) in [(2026, 12, 31), (2027, 1, 1), (2026, 3, 8)] {
            let now = try #require(calendar.date(from: .init(year: year, month: month, day: day, hour: 12)))
            let today = GregorianDay(year: year, month: try #require(Month(rawValue: month)), day: day)
            for firstWeekday in 1...7 {
                let snapshot = WidgetCalendarSnapshot(cycleStartDay: 0, cycle: [false, true], overrides: [:],
                    display: .init(firstWeekday: firstWeekday),
                    displayedMonthStart: GregorianDay(year: 2097, month: .nov, day: 1).julianDay)
                let weeks = WidgetPeriodEntry(date: now, surface: .twoWeeks, snapshot: snapshot, calendar: calendar)
                #expect(weeks.days.count == 14)
                #expect(weeks.days.first!.day.weekdayOrder().rawValue % 7 + 1 == firstWeekday)
                #expect(weeks.days.filter(\.isToday).map(\.id) == [today.julianDay])
                #expect(weeks.days.allSatisfy { $0.isCurrentMonth })
                #expect(zip(weeks.days, weeks.days.dropFirst()).allSatisfy { $1.id == $0.id + 1 })
                let three = WidgetPeriodEntry(date: now, surface: .threeDays, snapshot: snapshot, calendar: calendar)
                #expect(three.days.map(\.id) == [today.julianDay, today.julianDay + 1, today.julianDay + 2])
                #expect(three.days.map(\.value) == three.days.map { snapshot.day(at: $0.id) })
            }
        }
    }

    @Test func periodsShouldAdvanceAtMidnightAndKeepEditorStateScoped() throws {
        let calendar = WidgetCalendarTimeline.calendar(timeZone: try #require(TimeZone(identifier: "Asia/Singapore")))
        let now = try #require(calendar.date(from: .init(year: 2026, month: 11, day: 8, hour: 23, minute: 59)))
        let today = GregorianDay(year: 2026, month: .nov, day: 8).julianDay
        for surface in [WidgetCalendarSurface.twoWeeks, .threeDays] {
            let snapshot = WidgetCalendarSnapshot(cycleStartDay: 0, cycle: [false], overrides: [:], display: .init(firstWeekday: 2),
                interaction: .init(selectedDay: today, expiresAt: now.addingTimeInterval(180), surface: surface))
            let entries = WidgetPeriodTimeline.entries(surface: surface, snapshot: snapshot, from: now, calendar: calendar)
            #expect(entries.first?.selectedDay?.id == today)
            #expect(entries[1].days[0].id == today + 1)
            #expect(entries.last?.selectedDay == nil)
            let other: WidgetCalendarSurface = surface == .twoWeeks ? .threeDays : .twoWeeks
            #expect(WidgetPeriodEntry(date: now, surface: other, snapshot: snapshot, calendar: calendar).selectedDay == nil)
            #expect(WidgetMonthEntry(date: now, snapshot: snapshot, calendar: calendar).selectedDay == nil)
        }
    }
}
