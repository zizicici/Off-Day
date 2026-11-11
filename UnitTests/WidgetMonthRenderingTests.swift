import Foundation
import SwiftUI
import Testing
import UIKit
import ZCCalendar
@testable import Off_Day

@MainActor
struct WidgetMonthRenderingTests {
    @Test func renderMonthlyCalendarAndDetails() throws {
        var calendar = WidgetCalendarTimeline.calendar(timeZone: TimeZone(secondsFromGMT: 8 * 3600)!)
        calendar.locale = Locale(identifier: "zh-Hans")
        let date = calendar.date(from: .init(year: 2026, month: 11, day: 9, hour: 12))!
        let today = GregorianDay(year: 2026, month: .nov, day: 9).julianDay
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("WidgetPreviews")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        // November needs six rows; browsing December fits in five.
        for month in [Month.nov, .dec] {
            let day = GregorianDay(year: 2026, month: month, day: 9).julianDay
            let first = GregorianDay(year: 2026, month: month, day: 1).julianDay
            let browsedMonth = month == .nov ? nil : first
            let alternativeDays = WidgetCalendarDisplay.chineseCalendarNames(for: Set(first..<(first + 42)))
            var snapshot = WidgetCalendarSnapshot(cycleStartDay: today, cycle: [false, false, false, false, false, true, true], overrides: [
                day + 2: .init(isOffDay: true, name: "公共假日"),
                day + 3: .init(isOffDay: false, name: "调休上班"),
                day + 4: .init(isOffDay: true)
            ], details: [
                day + 2: .init(publicIsOffDay: true),
                day + 3: .init(publicIsOffDay: false),
                day + 4: .init(customIsOffDay: true, comment: "和家人一起出游")
            ], display: .init(firstWeekday: 2, alternativeDays: alternativeDays),
               displayedMonthStart: browsedMonth)
            let prefix = month == .nov ? "month" : "month-five-rows"
            for dark in [false, true] {
                for selected in [false, true] {
                    for width: CGFloat in [300, 338] {
                        snapshot.interaction = selected ? .init(selectedDay: day + 4, expiresAt: date.addingTimeInterval(300)) : nil
                        let view = MonthCalendarWidgetView(entry: .init(date: date, snapshot: snapshot, calendar: calendar))
                            .frame(width: width, height: width + 16)
                            .background(Color("BackgroundColor"))
                            .modifier(WidgetRoundedPreviewContainer(radius: 28))
                            .environment(\.colorScheme, dark ? .dark : .light)
                            .environment(\.locale, Locale(identifier: "zh-Hans"))
                        let renderer = ImageRenderer(content: view)
                        renderer.scale = 3
                        let data = try #require(renderer.uiImage?.pngData())
                        try data.write(to: folder.appendingPathComponent("\(prefix)-\(Int(width))-\(dark ? "dark" : "light")-\(selected ? "detail" : "calendar").png"))
                    }
                }
            }
        }
    }

    @Test func renderBottomCornerDatesWithSystemContainerShapes() throws {
        var calendar = WidgetCalendarTimeline.calendar(timeZone: TimeZone(secondsFromGMT: 8 * 3600)!)
        calendar.locale = Locale(identifier: "zh-Hans")
        let first = GregorianDay(year: 2025, month: .nov, day: 1).julianDay
        let left = GregorianDay(year: 2025, month: .nov, day: 24).julianDay
        let right = GregorianDay(year: 2025, month: .nov, day: 30).julianDay
        let names = WidgetCalendarDisplay.chineseCalendarNames(for: Set(first..<(first + 42)))
        let snapshot = WidgetCalendarSnapshot(cycleStartDay: left, cycle: [false, false, false, false, false, true, true],
            overrides: [left: .init(isOffDay: true, name: "示例假日"), right: .init(isOffDay: false)],
            details: [left: .init(publicIsOffDay: true, customIsOffDay: true, comment: "备注"),
                      right: .init(customIsOffDay: false, comment: "备注")],
            display: .init(firstWeekday: 2, alternativeDays: names))
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("WidgetPreviews")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for (label, day) in [("left", 24), ("right", 30)] {
            let date = try #require(calendar.date(from: .init(year: 2025, month: 11, day: day, hour: 12)))
            let entry = WidgetMonthEntry(date: date, snapshot: snapshot, calendar: calendar)
            #expect(entry.rowCount == 5)
            for radius: CGFloat in [28, 36] {
                let view = MonthCalendarWidgetView(entry: entry)
                    .frame(width: 300, height: 316)
                    .background(Color("BackgroundColor"))
                    .modifier(WidgetRoundedPreviewContainer(radius: radius))
                    .environment(\.colorScheme, .light)
                    .environment(\.locale, Locale(identifier: "zh-Hans"))
                let renderer = ImageRenderer(content: view)
                renderer.scale = 3
                let data = try #require(renderer.uiImage?.pngData())
                try data.write(to: folder.appendingPathComponent("month-corner-\(label)-\(Int(radius)).png"))
            }
        }
    }
    @Test func renderMediumAndSmallCalendarsAndEditors() throws {
        var calendar = WidgetCalendarTimeline.calendar(timeZone: TimeZone(secondsFromGMT: 8 * 3600)!)
        calendar.locale = Locale(identifier: "zh-Hans")
        let date = try #require(calendar.date(from: .init(year: 2026, month: 11, day: 9, hour: 12)))
        let today = GregorianDay(year: 2026, month: .nov, day: 9).julianDay
        let alternativeDays = WidgetCalendarDisplay.chineseCalendarNames(for: Set((today - 7)..<(today + 22)))
        var snapshot = WidgetCalendarSnapshot(cycleStartDay: today, cycle: [false, false, false, false, false, true, true],
            overrides: [today: .init(isOffDay: true), today + 2: .init(isOffDay: true, name: "公共假日")],
            details: [today: .init(customIsOffDay: true, comment: "和家人一起出游"), today + 2: .init(publicIsOffDay: true)],
            display: .init(firstWeekday: 2, alternativeDays: alternativeDays))
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("WidgetPreviews")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for surface in [WidgetCalendarSurface.twoWeeks, .threeDays] {
            let size = surface == .twoWeeks ? CGSize(width: 338, height: 158) : CGSize(width: 158, height: 158)
            for dark in [false, true] {
                for selected in [false, true] {
                    snapshot.interaction = selected ? .init(selectedDay: today, expiresAt: date.addingTimeInterval(300), surface: surface) : nil
                    let entry = WidgetPeriodEntry(date: date, surface: surface, snapshot: snapshot, calendar: calendar)
                    let view = PeriodCalendarWidgetView(entry: entry)
                        .frame(width: size.width, height: size.height)
                        .background(Color("BackgroundColor"))
                        .modifier(WidgetRoundedPreviewContainer(radius: 28))
                        .environment(\.colorScheme, dark ? .dark : .light)
                        .environment(\.locale, Locale(identifier: "zh-Hans"))
                    let renderer = ImageRenderer(content: view)
                    renderer.scale = 3
                    let data = try #require(renderer.uiImage?.pngData())
                    try data.write(to: folder.appendingPathComponent("\(surface.rawValue)-\(dark ? "dark" : "light")-\(selected ? "detail" : "calendar").png"))
                }
            }
        }
    }

    @Test func renderCountdownsWithMissingDatesAndLocalizedLabels() throws {
        let calendar = WidgetCalendarTimeline.calendar(timeZone: TimeZone(secondsFromGMT: 8 * 3600)!)
        let date = try #require(calendar.date(from: .init(year: 2026, month: 11, day: 9, hour: 12)))
        let today = GregorianDay(year: 2026, month: .nov, day: 9).julianDay
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("WidgetPreviews")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for language in ["zh-Hans", "en"] {
            for missing in [false, true] {
                let distance = language == "en" ? 365 : 27
                let snapshot = WidgetCalendarSnapshot(cycleStartDay: today, cycle: missing ? [false] : [false, true],
                    overrides: missing ? [:] : [today + distance: .init(isOffDay: true, name: language == "zh-Hans" ? "公共假期" : "Public holiday")],
                    details: missing ? [:] : [today + distance: .init(publicIsOffDay: true)])
                for dark in [false, true] {
                    let view = WidgetCountdownView(entry: .init(date: date, snapshot: snapshot, calendar: calendar))
                        .frame(width: 158, height: 158)
                        .background(WidgetCountdownPalette.classic.colors(for: dark ? .dark : .light).background)
                        .modifier(WidgetRoundedPreviewContainer(radius: 28))
                        .environment(\.colorScheme, dark ? .dark : .light)
                        .environment(\.locale, Locale(identifier: language))
                    let renderer = ImageRenderer(content: view)
                    renderer.scale = 3
                    let data = try #require(renderer.uiImage?.pngData())
                    try data.write(to: folder.appendingPathComponent("countdown-\(language)-\(missing ? "empty" : "dates")-\(dark ? "dark" : "light").png"))
                }
            }
        }
    }

    @Test func renderCountdownColorAndFontOptions() throws {
        let calendar = WidgetCalendarTimeline.calendar(timeZone: TimeZone(secondsFromGMT: 8 * 3600)!)
        let date = try #require(calendar.date(from: .init(year: 2026, month: 11, day: 9, hour: 12)))
        let today = GregorianDay(year: 2026, month: .nov, day: 9).julianDay
        let snapshot = WidgetCalendarSnapshot(cycleStartDay: today, cycle: [false, false, true],
            overrides: [today + 27: .init(isOffDay: true, name: "公共假期")], details: [today + 27: .init(publicIsOffDay: true)])
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("WidgetPreviews")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let styles = WidgetCountdownPalette.allCases.map { WidgetCountdownStyle(palette: $0) }
            + WidgetCountdownFont.allCases.filter { $0 != .rounded }.map { WidgetCountdownStyle(font: $0) }
        for style in styles {
            for target in WidgetCountdownTarget.allCases {
                for dark in [false, true] {
                    let view = WidgetCountdownView(entry: .init(date: date, snapshot: snapshot, calendar: calendar, style: style, target: target))
                        .frame(width: 158, height: 158)
                        .background(style.palette.colors(for: dark ? .dark : .light).background)
                        .modifier(WidgetRoundedPreviewContainer(radius: 28))
                        .environment(\.colorScheme, dark ? .dark : .light)
                        .environment(\.locale, Locale(identifier: "zh-Hans"))
                    let renderer = ImageRenderer(content: view)
                    renderer.scale = 3
                    let data = try #require(renderer.uiImage?.pngData())
                    try data.write(to: folder.appendingPathComponent("countdown-\(style.palette.rawValue)-\(style.font.rawValue)-\(target.rawValue)-\(dark ? "dark" : "light").png"))
                }
            }
        }
    }
}

private struct WidgetRoundedPreviewContainer: ViewModifier {
    var radius: CGFloat

    @ViewBuilder func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.containerShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        } else {
            content.containerShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        }
    }
}
