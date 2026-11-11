import Foundation
import SwiftUI
import Testing
import UIKit
import WidgetKit
import ZCCalendar
@testable import Off_Day

@MainActor
struct LockScreenThreeDayWidgetTests {
    @Test func dateCardsShouldUseTheFullHeightWithUniformBottomCorners() throws {
        let calendar = WidgetCalendarTimeline.calendar(timeZone: TimeZone(secondsFromGMT: 8 * 3600)!)
        let date = try #require(calendar.date(from: .init(year: 2026, month: 12, day: 31, hour: 12)))
        let snapshot = WidgetCalendarSnapshot(cycleStartDay: 0, cycle: [false], overrides: [:])
        let entry = WidgetPeriodEntry(date: date, surface: .threeDays, snapshot: snapshot, calendar: calendar)
        for size in [CGSize(width: 158, height: 72), .init(width: 172, height: 84)] {
            let view = LockScreenThreeDayWidgetView(entry: entry)
                .frame(width: size.width, height: size.height)
                .containerShape(RoundedRectangle(cornerRadius: 36))
                .background(Color.black)
                .environment(\.colorScheme, .dark)
                .environment(\.widgetRenderingMode, .vibrant)
            let renderer = ImageRenderer(content: view)
            renderer.scale = 3
            let image = try #require(renderer.uiImage?.cgImage)
            func crop(_ rect: CGRect) throws -> Data {
                let cropped = try #require(image.cropping(to: rect))
                return try #require(UIImage(cgImage: cropped).pngData())
            }
            // Preserve the existing 2-point horizontal inset and 4-point column gaps.
            let width = (CGFloat(image.width) - 12 - 24) / 3
            let bottom = CGFloat(image.height) - 27
            let center = try crop(CGRect(x: 6 + width + 12, y: bottom, width: width, height: 27))
            #expect(try crop(CGRect(x: 6, y: bottom, width: width, height: 27)) == center)
            #expect(try crop(CGRect(x: 6 + (width + 12) * 2, y: bottom, width: width, height: 27)) == center)
            // The bottom center of each card is filled, while the outer horizontal inset stays empty.
            let outside = try crop(CGRect(x: 0, y: CGFloat(image.height - 1), width: 1, height: 1))
            for column in 0..<3 {
                let x = 6 + CGFloat(column) * (width + 12) + width / 2
                #expect(try crop(CGRect(x: x, y: CGFloat(image.height - 1), width: 1, height: 1)) != outside)
            }
        }
    }

    @Test(arguments: ["Asia/Singapore", "America/Los_Angeles", "Pacific/Auckland"])
    func datesShouldAdvanceAcrossMidnightAndYearBoundaries(zone: String) throws {
        let calendar = WidgetCalendarTimeline.calendar(timeZone: try #require(TimeZone(identifier: zone)))
        for (year, month, day) in [(2026, 12, 31), (2026, 3, 7)] {
            let date = try #require(calendar.date(from: .init(year: year, month: month, day: day, hour: 23, minute: 59)))
            let today = GregorianDay(year: year, month: Month(rawValue: month)!, day: day).julianDay
            let snapshot = WidgetCalendarSnapshot(cycleStartDay: today, cycle: [false, true, true],
                overrides: [today + 2: .init(isOffDay: false, name: "Make-up workday")])
            let entries = WidgetPeriodTimeline.entries(surface: .threeDays, snapshot: snapshot, from: date, calendar: calendar)
            #expect(entries[0].days.map(\.id) == [today, today + 1, today + 2])
            #expect(entries[0].days.map(\.value) == [snapshot.day(at: today), snapshot.day(at: today + 1), snapshot.day(at: today + 2)])
            #expect(entries[1].days.map(\.id) == [today + 1, today + 2, today + 3])
            #expect(entries[1].date == calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: date)!))
        }
    }

    @Test func renderWorkdaysHolidaysAndMissingDataInAllSupportedLanguages() throws {
        let calendar = WidgetCalendarTimeline.calendar(timeZone: TimeZone(secondsFromGMT: 8 * 3600)!)
        let date = try #require(calendar.date(from: .init(year: 2026, month: 12, day: 31, hour: 12)))
        let today = GregorianDay(year: 2026, month: .dec, day: 31).julianDay
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("WidgetPreviews/LockScreenThreeDays")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for language in ["en", "ja", "ko", "zh-Hans", "zh-Hant", "zh-HK"] {
            for scenario in ["workdays", "holiday", "lunar", "missing"] {
                let name = language.hasPrefix("zh") ? "元旦公共假期" : "New Year's Day"
                let snapshot: WidgetCalendarSnapshot? = scenario == "missing" ? nil : .init(
                    cycleStartDay: today, cycle: [false, true, true],
                    overrides: scenario == "holiday" || scenario == "lunar" ? [today + 1: .init(isOffDay: true, name: name)] : [:],
                    details: scenario == "lunar" ? [today: .init(customIsOffDay: false, comment: "Note"), today + 1: .init(publicIsOffDay: true)] : nil,
                    display: .init(alternativeDays: scenario == "lunar"
                        ? WidgetCalendarDisplay.chineseCalendarNames(for: Set(today..<(today + 3))) : [:]))
                let entry = WidgetPeriodEntry(date: date, surface: .threeDays, snapshot: snapshot, calendar: calendar)
                if scenario != "missing" {
                    #expect(entry.days.map { $0.value?.isOffDay } == [false, true, true])
                }
                for dark in [false, true] {
                    for size in [CGSize(width: 158, height: 72), .init(width: 172, height: 76), .init(width: 172, height: 84)] {
                        let view = LockScreenThreeDayWidgetView(entry: entry)
                            .frame(width: size.width, height: size.height)
                            .background(dark ? Color.black : Color.white)
                            .environment(\.locale, Locale(identifier: language))
                            .environment(\.timeZone, calendar.timeZone)
                            .environment(\.colorScheme, dark ? .dark : .light)
                            .environment(\.widgetRenderingMode, .vibrant)
                        let renderer = ImageRenderer(content: view)
                        renderer.scale = 3
                        let image = try #require(renderer.uiImage)
                        #expect(image.size == size)
                        let suffix = size.width == 158 ? "" : "-\(Int(size.width))x\(Int(size.height))"
                        try #require(image.pngData()).write(to: folder.appendingPathComponent(
                            "\(language)-\(scenario)-\(dark ? "dark" : "light")\(suffix).png"))
                    }
                }
            }
        }
    }
}
