import Foundation
import Testing
import ZCCalendar
@testable import Off_Day

@MainActor
struct WidgetCountdownTests {
    @Test func eachInstanceShouldKeepItsTargetAndStyleAcrossMidnight() throws {
        if #available(iOS 17.0, *) {
            let defaults = WidgetCountdownConfigurationIntent()
            #expect(defaults.style == WidgetCountdownStyle(palette: .classic, font: .rounded))
            for palette in ["mint", "blue", "peach", "lilac", "automatic"] {
                let data = Data("{\"palette\":\"\(palette)\",\"font\":\"rounded\"}".utf8)
                #expect(try JSONDecoder().decode(WidgetCountdownStyle.self, from: data) == defaults.style)
            }
            #expect(defaults.target == .publicHoliday)
            let calendar = WidgetCalendarTimeline.calendar(timeZone: TimeZone(secondsFromGMT: 8 * 3600)!)
            let date = try #require(calendar.date(from: .init(year: 2026, month: 11, day: 9, hour: 23, minute: 59)))
            let today = GregorianDay(year: 2026, month: .nov, day: 9).julianDay
            let snapshot = WidgetCalendarSnapshot(cycleStartDay: today, cycle: [false, false, true],
                overrides: [today + 4: .init(isOffDay: true, name: "Holiday")], details: [today + 4: .init(publicIsOffDay: true)])
            for target in WidgetCountdownTarget.allCases {
                for palette in WidgetCountdownPalette.allCases {
                    for font in WidgetCountdownFont.allCases {
                        let configuration = WidgetCountdownConfigurationIntent(target: target, palette: palette, font: font)
                        let entries = WidgetCountdownTimeline.entries(snapshot: snapshot, from: date, calendar: calendar,
                                                                      style: configuration.style, target: configuration.target)
                        #expect(entries.allSatisfy { $0.style == configuration.style })
                        #expect(entries.allSatisfy { $0.target == target })
                        #expect(entries[0].countdown?.daysRemaining == (target == .publicHoliday ? 4 : 2))
                        #expect(entries[1].countdown?.daysRemaining == (target == .publicHoliday ? 3 : 1))
                        #expect(defaults.style.palette == .classic && defaults.style.font == .rounded)
                    }
                }
            }
        }
    }

    @Test func publicCountdownShouldUseThePlanWhileOffCountdownUsesTheFinalMark() throws {
        let today = GregorianDay(year: 2026, month: .nov, day: 9)
        let holiday = today + 2
        let makeup = today + 1
        let plan = PublicPlanInfo(plan: .custom(CustomPublicPlan(name: "Test", start: today, end: today + 30)), days: [
            today.julianDay: JSONPublicDay(name: "Today", date: today, type: .offDay),
            makeup.julianDay: JSONPublicDay(name: "Make-up", date: makeup, type: .workDay),
            holiday.julianDay: JSONPublicDay(name: "Holiday", date: holiday, type: .offDay)
        ])
        let snapshot = WidgetCalendarSnapshot.make(baseCalendar: .standard(.default), publicPlan: plan,
            customDays: [CustomDay(dayIndex: Int64(makeup.julianDay), dayType: .offDay),
                         CustomDay(dayIndex: Int64(holiday.julianDay), dayType: .workDay)])
        #expect(snapshot.nextPublicHoliday(after: today.julianDay) == holiday.julianDay)
        #expect(snapshot.nextOffDay(after: today.julianDay) == makeup.julianDay)
        let calendar = WidgetCalendarTimeline.calendar(timeZone: TimeZone(secondsFromGMT: 8 * 3600)!)
        let date = try #require(calendar.date(from: .init(year: 2026, month: 11, day: 9, hour: 12)))
        let entry = WidgetCountdownEntry(date: date, snapshot: snapshot, calendar: calendar)
        #expect(entry.countdown?.daysRemaining == 2)
        #expect(entry.countdown?.name == "Holiday")
        let offEntry = WidgetCountdownEntry(date: date, snapshot: snapshot, calendar: calendar, target: .offDay)
        #expect(offEntry.countdown?.daysRemaining == 1)
        #expect(offEntry.countdown?.name == nil)
        var publicRest = snapshot
        publicRest.overrides[makeup.julianDay]?.isOffDay = false
        publicRest.overrides[holiday.julianDay]?.isOffDay = true
        let holidayEntry = WidgetCountdownEntry(date: date, snapshot: publicRest, calendar: calendar, target: .offDay)
        #expect(holidayEntry.countdown?.name == "Holiday")
        #expect(snapshot.nextPublicHoliday(after: holiday.julianDay) == nil)
    }

    @Test func nextOffDayShouldHandleBlockedCyclesAndAnAllWorkCalendar() {
        let start = GregorianDay(year: 2026, month: .nov, day: 9).julianDay
        var snapshot = WidgetCalendarSnapshot(cycleStartDay: start, cycle: [false, true, true], overrides: [
            start + 1: .init(isOffDay: false), start + 2: .init(isOffDay: false), start + 4: .init(isOffDay: false)
        ])
        #expect(snapshot.nextOffDay(after: start) == start + 5)
        snapshot.overrides[start + 3] = .init(isOffDay: true)
        #expect(snapshot.nextOffDay(after: start) == start + 3)
        snapshot.cycle = [false]
        #expect(snapshot.nextOffDay(after: start) == start + 3)
        #expect(snapshot.nextOffDay(after: start + 3) == nil)
        snapshot.overrides[start + 800] = .init(isOffDay: true)
        #expect(snapshot.nextOffDay(after: start + 3) == start + 800)
        snapshot.cycle = []
        #expect(snapshot.nextOffDay(after: start) == nil)
        #expect(snapshot.nextPublicHoliday(after: start) == nil)
    }

    @Test(arguments: ["America/Los_Angeles", "Asia/Singapore", "Pacific/Auckland"])
    func countdownsShouldAdvanceByCalendarDaysAcrossDSTAndYearChanges(zone: String) throws {
        let calendar = WidgetCalendarTimeline.calendar(timeZone: try #require(TimeZone(identifier: zone)))
        for (year, month, day) in [(2026, 3, 7), (2026, 10, 31), (2026, 12, 31)] {
            let date = try #require(calendar.date(from: .init(year: year, month: month, day: day, hour: 23, minute: 59)))
            let today = GregorianDay(year: year, month: try #require(Month(rawValue: month)), day: day).julianDay
            let snapshot = WidgetCalendarSnapshot(cycleStartDay: today, cycle: [false], overrides: [
                today + 3: .init(isOffDay: true, name: "Holiday")
            ], details: [today + 3: .init(publicIsOffDay: true)])
            for target in WidgetCountdownTarget.allCases {
                let entries = WidgetCountdownTimeline.entries(snapshot: snapshot, from: date, calendar: calendar, target: target)
                #expect(entries.count == 8)
                #expect(entries.prefix(3).map { $0.countdown?.daysRemaining } == [3, 2, 1])
                #expect(entries[3].countdown == nil)
                #expect(entries.dropFirst().allSatisfy { calendar.component(.hour, from: $0.date) == 0 })
            }
        }
        let empty = WidgetCountdownEntry(date: Date(), snapshot: nil, calendar: calendar)
        #expect(!empty.isReady && empty.countdown == nil)
    }
}
