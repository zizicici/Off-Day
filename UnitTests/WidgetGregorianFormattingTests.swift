import Foundation
import SwiftUI
import Testing
import UIKit
import ZCCalendar
@testable import Off_Day

@MainActor
struct WidgetGregorianFormattingTests {
    @Test(arguments: [Calendar.Identifier.islamic, .buddhist, .japanese])
    func widgetDatesShouldStayGregorianInNonGregorianEnvironments(identifier: Calendar.Identifier) throws {
        let gregorian = WidgetCalendarTimeline.calendar(timeZone: TimeZone(secondsFromGMT: 0)!)
        var systemCalendar = Calendar(identifier: identifier)
        systemCalendar.timeZone = gregorian.timeZone
        for locale in [Locale(identifier: "en_US"), Locale(identifier: "zh_Hans_CN"),
                       Locale(identifier: "en_US@calendar=\(identifier)")] {
            for (month, day) in [(11, 10), (11, 30), (12, 31)] {
                let date = try #require(gregorian.date(from: .init(year: 2026, month: month, day: day, hour: 12)))
                let today = GregorianDay(year: 2026, month: Month(rawValue: month)!, day: day).julianDay
                let snapshot = WidgetCalendarSnapshot(cycleStartDay: 0, cycle: [false, true],
                    overrides: [today + 3: .init(isOffDay: true, name: "Holiday")], details: [today + 3: .init(publicIsOffDay: true)])
                try expectSameRendering(
                    MonthCalendarWidgetView(entry: .init(date: date, snapshot: snapshot, calendar: gregorian))
                        .frame(width: 338, height: 354),
                    gregorian: gregorian, systemCalendar: systemCalendar, locale: locale)
                try expectSameRendering(
                    LockScreenThreeDayWidgetView(entry: .init(date: date, surface: .threeDays, snapshot: snapshot, calendar: gregorian))
                        .frame(width: 158, height: 72),
                    gregorian: gregorian, systemCalendar: systemCalendar, locale: locale)
                try expectSameRendering(
                    PeriodCalendarWidgetView(entry: .init(date: date, surface: .threeDays, snapshot: snapshot, calendar: gregorian))
                        .frame(width: 158, height: 158),
                    gregorian: gregorian, systemCalendar: systemCalendar, locale: locale)
                for target in WidgetCountdownTarget.allCases {
                    try expectSameRendering(
                        WidgetCountdownView(entry: .init(date: date, snapshot: snapshot, calendar: gregorian, target: target))
                            .frame(width: 158, height: 158),
                        gregorian: gregorian, systemCalendar: systemCalendar, locale: locale)
                }
            }
        }
    }

    @Test(arguments: ["en_US@calendar=buddhist", "en_US@calendar=islamic", "en_US@calendar=japanese"])
    func localeCalendarPreferenceShouldNotReplaceGregorianYear(localeIdentifier: String) throws {
        let date = try #require(ISO8601DateFormatter().date(from: "2026-11-10T12:00:00Z"))
        let style = Date.FormatStyle.dateTime.year().month(.wide)
            .widgetGregorian(locale: Locale(identifier: localeIdentifier), timeZone: TimeZone(secondsFromGMT: 0)!)
        #expect(style.calendar.identifier == .gregorian)
        #expect(style.format(date) == "November 2026")
    }

    @Test func explicitGregorianFormattingShouldKeepLocalizationAndLocalDateBoundaries() throws {
        let instant = try #require(ISO8601DateFormatter().date(from: "2026-12-31T17:00:00Z"))
        let singapore = try #require(TimeZone(identifier: "Asia/Singapore"))
        let losAngeles = try #require(TimeZone(identifier: "America/Los_Angeles"))
        var systemStyle = Date.FormatStyle.dateTime.year().month(.wide)
        systemStyle.calendar = Calendar(identifier: .buddhist)
        let english = systemStyle.widgetGregorian(locale: Locale(identifier: "en_US"), timeZone: singapore)
        let chinese = systemStyle.widgetGregorian(locale: Locale(identifier: "zh_Hans_CN"), timeZone: singapore)
        let previousMonth = systemStyle.widgetGregorian(locale: Locale(identifier: "en_US"), timeZone: losAngeles)
        #expect(english.format(instant) == "January 2027")
        #expect(chinese.format(instant) == "2027年1月")
        #expect(previousMonth.format(instant) == "December 2026")
        #expect(english.calendar.identifier == .gregorian)
    }

    private func expectSameRendering<V: View>(_ view: V, gregorian: Calendar, systemCalendar: Calendar,
                                              locale: Locale,
                                              sourceLocation: SourceLocation = #_sourceLocation) throws {
        let expected = try render(view, calendar: gregorian, locale: locale)
        let actual = try render(view, calendar: systemCalendar, locale: locale)
        #expect(actual == expected, "Widget text changed with the system calendar: \(systemCalendar.identifier)",
                sourceLocation: sourceLocation)
    }

    private func render<V: View>(_ view: V, calendar: Calendar, locale: Locale) throws -> Data {
        let renderer = ImageRenderer(content: view
            .background(Color("BackgroundColor"))
            .environment(\.locale, locale)
            .environment(\.calendar, calendar)
            .environment(\.timeZone, calendar.timeZone)
            .environment(\.colorScheme, .light))
        renderer.scale = 1
        return try #require(renderer.uiImage?.pngData())
    }
}
