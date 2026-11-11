import SwiftUI
import Testing
import UIKit
@testable import Off_Day

/// Covers the original accessory widgets as well as the calendar-based lock-screen view.
@MainActor
struct WidgetAccessoryRenderingTests {
    @Test func renderStatusWidgetsWithHolidaysAndMissingData() throws {
        let calendar = WidgetCalendarTimeline.calendar(timeZone: TimeZone(secondsFromGMT: 8 * 3600)!)
        let date = try #require(calendar.date(from: .init(year: 2026, month: 11, day: 9, hour: 12)))
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("WidgetPreviews/AccessoryStatus")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for language in ["en", "ja", "ko", "zh-Hans", "zh-Hant", "zh-HK"] {
            for dark in [false, true] {
                for state in ["work", "holiday", "missing"] {
                    let today: WidgetCalendarDay? = state == "missing" ? nil : .init(isOffDay: state == "holiday", name: state == "holiday" ? "公共假期 Public holiday" : nil)
                    let tomorrow: WidgetCalendarDay? = state == "missing" ? nil : .init(isOffDay: true)
                    let entry = WidgetCalendarEntry(date: date, today: today, tomorrow: tomorrow)
                    for size in [CGSize(width: 158, height: 72), .init(width: 172, height: 76), .init(width: 172, height: 84)] {
                        let suffix = size.width == 158 ? "" : "-\(Int(size.width))x\(Int(size.height))"
                        try render(LockScreenWidgetView(entry: entry), size: size,
                                   name: "two-days\(suffix)", language: language, dark: dark, state: state, folder: folder)
                    }
                    try render(SingleDayWidgetView(title: "widget.today", day: today), size: .init(width: 72, height: 72),
                               name: "today", language: language, dark: dark, state: state, folder: folder)
                    try render(SingleDayWidgetView(title: "widget.tomorrow", day: tomorrow), size: .init(width: 72, height: 72),
                               name: "tomorrow", language: language, dark: dark, state: state, folder: folder)
                }
            }
        }
    }

    private func render(_ content: some View, size: CGSize, name: String, language: String, dark: Bool,
                        state: String, folder: URL) throws {
        let view = content
            .frame(width: size.width, height: size.height)
            .environment(\.locale, Locale(identifier: language))
            .environment(\.calendar, WidgetCalendarTimeline.calendar())
            .environment(\.colorScheme, dark ? .dark : .light)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3
        let image = try #require(renderer.uiImage)
        #expect(image.size == size)
        let data = try #require(image.pngData())
        try data.write(to: folder.appendingPathComponent("\(name)-\(language)-\(state)-\(dark ? "dark" : "light").png"))
    }
}
