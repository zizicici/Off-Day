import Foundation
import SwiftUI
import Testing
import UIKit
import WidgetKit
import ZCCalendar
@testable import Off_Day

@MainActor
struct WidgetCalendarStyleTests {
    @Test func todayIndicatorShouldStayInEachConfigurationAcrossTimelineRefreshes() throws {
        if #available(iOS 17.0, *) {
            #expect(MonthCalendarConfigurationIntent().showsTodayIndicator)
            #expect(TwoWeekCalendarConfigurationIntent().showsTodayIndicator)
            #expect(!ThreeDayCalendarConfigurationIntent().showsTodayIndicator)
            let calendar = WidgetCalendarTimeline.calendar(timeZone: TimeZone(secondsFromGMT: 8 * 3600)!)
            let now = try #require(calendar.date(from: .init(year: 2026, month: 11, day: 10, hour: 23, minute: 59)))
            let today = GregorianDay(year: 2026, month: .nov, day: 10).julianDay
            let expiry = now.addingTimeInterval(180)
            let snapshot = WidgetCalendarSnapshot(cycleStartDay: today, cycle: [false, true],
                overrides: [today: .init(isOffDay: false, name: "Holiday")],
                details: [today: .init(customIsOffDay: false, comment: "Keep this record")],
                interaction: .init(selectedDay: today, expiresAt: expiry, surface: .month))
            let encoded = try JSONEncoder().encode(snapshot)
            let baseline = WidgetMonthTimeline.entries(snapshot: snapshot, from: now, calendar: calendar)
            for enabled in [false, true] {
                let month = MonthCalendarConfigurationIntent(palette: .mono, showsTodayIndicator: enabled)
                let weeks = TwoWeekCalendarConfigurationIntent(palette: .classic, showsTodayIndicator: !enabled)
                let monthly = WidgetMonthTimeline.entries(snapshot: snapshot, from: now, calendar: calendar,
                    palette: month.palette, showsTodayIndicator: month.showsTodayIndicator)
                let fortnightly = WidgetPeriodTimeline.entries(surface: .twoWeeks, snapshot: snapshot, from: now,
                    calendar: calendar, palette: weeks.palette, showsTodayIndicator: weeks.showsTodayIndicator)
                #expect(monthly.allSatisfy { $0.showsTodayIndicator == enabled })
                #expect(fortnightly.allSatisfy { $0.showsTodayIndicator == !enabled })
                #expect(monthly.map(\.date) == baseline.map(\.date))
                for (actual, original) in zip(monthly, baseline) {
                    #expect(actual.days.filter(\.isToday).map(\.id) == original.days.filter(\.isToday).map(\.id))
                    #expect(actual.days.map(\.value) == original.days.map(\.value))
                    #expect(actual.days.map(\.detail) == original.days.map(\.detail))
                }
                #expect(monthly[0].selectedDay?.id == today)
                #expect(monthly.first { $0.date == expiry }?.selectedDay == nil)
                #expect(monthly[1].days.first { $0.isToday }?.id == today + 1)
                #expect(fortnightly[1].days.first { $0.isToday }?.id == today + 1)
                #expect(fortnightly[0].days.first { $0.id == today }?.detail?.comment == "Keep this record")
            }
            let browsed = WidgetMonthEntry(date: now, snapshot: .init(cycleStartDay: today, cycle: [false],
                overrides: [:], displayedMonthStart: GregorianDay(year: 2026, month: .dec, day: 1).julianDay),
                calendar: calendar, showsTodayIndicator: false)
            #expect(!browsed.showsTodayIndicator)
            #expect(!browsed.days.contains { $0.isToday })
            #expect(!WidgetPeriodEntry(date: now, surface: .threeDays, snapshot: snapshot, calendar: calendar).showsTodayIndicator)
            #expect(try JSONDecoder().decode(WidgetCalendarSnapshot.self, from: encoded) == snapshot)
        }
    }

    @Test func hidingTodayIndicatorShouldRemoveTheStrokeInMonthAndTwoWeeks() throws {
        let calendar = WidgetCalendarTimeline.calendar()
        let date = try #require(calendar.date(from: .init(year: 2026, month: 11, day: 10, hour: 12)))
        let today = GregorianDay(year: 2026, month: .nov, day: 10).julianDay
        let snapshot = WidgetCalendarSnapshot(cycleStartDay: today, cycle: [false], overrides: [:])
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("WidgetPreviews/TodayIndicator")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for surface in [WidgetCalendarSurface.month, .twoWeeks] {
            for enabled in [false, true] {
                let content: AnyView
                if surface == .month {
                    content = AnyView(MonthCalendarWidgetView(entry: .init(date: date, snapshot: snapshot, calendar: calendar,
                        showsTodayIndicator: enabled)))
                } else {
                    content = AnyView(PeriodCalendarWidgetView(entry: .init(date: date, surface: surface, snapshot: snapshot,
                        calendar: calendar, showsTodayIndicator: enabled)))
                }
                let view = content.frame(width: 300, height: surface == .month ? 316 : 141)
                    .background(Color("BackgroundColor"))
                    .environment(\.colorScheme, .light).environment(\.widgetRenderingMode, .fullColor)
                    .environment(\.locale, Locale(identifier: "zh-Hans"))
                let renderer = ImageRenderer(content: view)
                renderer.scale = 2
                let image = try #require(renderer.cgImage)
                let count = try todayColorPixelCount(image)
                #expect(enabled ? count > 60 : count == 0)
                try #require(renderer.uiImage?.pngData()).write(to: folder.appendingPathComponent("\(surface.rawValue)-\(enabled ? "on" : "off").png"))
            }
        }
    }

    private func todayColorPixelCount(_ image: CGImage) throws -> Int {
        var pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)
        let context = try #require(CGContext(data: &pixels, width: image.width, height: image.height, bitsPerComponent: 8,
            bytesPerRow: image.width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue))
        context.draw(image, in: .init(x: 0, y: 0, width: image.width, height: image.height))
        let target = try #require(UIColor(named: "TodayColor"))
            .resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        #expect(target.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
        let expected = [red, green, blue].map { Int(($0 * 255).rounded()) }
        return stride(from: 0, to: pixels.count, by: 4).filter { index in
            (0..<3).allSatisfy { abs(Int(pixels[index + $0]) - expected[$0]) <= 3 } && pixels[index + 3] > 250
        }.count
    }

    @Test func instanceColorsShouldSurviveMidnightAndEditorExpiryWithoutChangingRecords() throws {
        if #available(iOS 17.0, *) {
            let calendar = WidgetCalendarTimeline.calendar(timeZone: TimeZone(secondsFromGMT: 8 * 3600)!)
            let now = try #require(calendar.date(from: .init(year: 2026, month: 11, day: 10, hour: 23, minute: 59)))
            let today = GregorianDay(year: 2026, month: .nov, day: 10).julianDay
            let expiry = now.addingTimeInterval(180)
            let snapshot = WidgetCalendarSnapshot(cycleStartDay: today, cycle: [false, true],
                overrides: [today + 1: .init(isOffDay: false, name: "Holiday")],
                details: [today + 1: .init(publicIsOffDay: true, customIsOffDay: false, comment: "Keep this record")],
                interaction: .init(selectedDay: today + 1, expiresAt: expiry, surface: .month))
            let encoded = try JSONEncoder().encode(snapshot)
            let defaults = [MonthCalendarConfigurationIntent().palette, TwoWeekCalendarConfigurationIntent().palette,
                            ThreeDayCalendarConfigurationIntent().palette]
            #expect(defaults.allSatisfy { $0 == .classic })

            for palette in WidgetCalendarPalette.allCases {
                let month = MonthCalendarConfigurationIntent(palette: palette)
                let weeks = TwoWeekCalendarConfigurationIntent(palette: palette)
                let days = ThreeDayCalendarConfigurationIntent(palette: palette)
                let entries = WidgetMonthTimeline.entries(snapshot: snapshot, from: now, calendar: calendar, palette: month.palette)
                let baseline = WidgetMonthTimeline.entries(snapshot: snapshot, from: now, calendar: calendar)
                #expect(entries.allSatisfy { $0.palette == palette })
                #expect(entries[0].selectedDay?.id == today + 1)
                #expect(entries.first { $0.date == expiry }?.selectedDay == nil)
                #expect(entries.map(\.date) == baseline.map(\.date))
                #expect(entries[1].days.map(\.value) == baseline[1].days.map(\.value))
                for (surface, selectedPalette) in [(WidgetCalendarSurface.twoWeeks, weeks.palette), (.threeDays, days.palette)] {
                    var selected = snapshot
                    selected.interaction?.surface = surface
                    let periods = WidgetPeriodTimeline.entries(surface: surface, snapshot: selected, from: now,
                                                                calendar: calendar, palette: selectedPalette)
                    #expect(periods.allSatisfy { $0.palette == palette })
                    #expect(periods[0].selectedDay?.detail?.comment == "Keep this record")
                    #expect(periods.first { $0.date == expiry }?.selectedDay == nil)
                    #expect(periods[1].days.first { $0.id == today + 1 }?.detail?.customIsOffDay == false)
                }
            }
            // Separate configurations can coexist; no palette is written into the shared snapshot.
            #expect(MonthCalendarConfigurationIntent(palette: .mono).palette == .mono)
            #expect(ThreeDayCalendarConfigurationIntent(palette: .classic).palette == .classic)
            #expect(MonthCalendarConfigurationIntent().palette == .classic)
            #expect(try JSONDecoder().decode(WidgetCalendarSnapshot.self, from: encoded) == snapshot)
        }
    }

    @Test func customPalettesShouldKeepDateAndEditorTextReadableInBothAppearances() {
        #expect(WidgetCalendarPalette.allCases == [.classic, .mono])
        #expect(UIImage(systemName: "zzz") != nil)
        #expect(UIImage(systemName: "briefcase.fill") != nil)
        for palette in WidgetCalendarPalette.allCases where palette != .classic {
            for scheme in [ColorScheme.light, .dark] {
                let colors = palette.colors(for: scheme)
                for (foreground, background) in [(colors.onOff, colors.off), (colors.onOff, colors.weekend), (colors.onWork, colors.work)] {
                    #expect(contrast(foreground, background, scheme: scheme) >= 4.5, "\(palette) \(scheme): date contrast")
                }
                for foreground in [colors.text, colors.offAccent, colors.workAccent] {
                    #expect(contrast(foreground, colors.background, scheme: scheme) >= 4.5, "\(palette) \(scheme): editor contrast")
                }
                #expect(contrast(colors.text, colors.paper, scheme: scheme) >= 4.5)
            }
        }
    }

    @Test func templateRenderingShouldKeepDateGlyphsOpaqueAndCellFillsFaint() throws {
        let calendar = WidgetCalendarTimeline.calendar()
        let date = try #require(calendar.date(from: .init(year: 2026, month: 11, day: 9, hour: 12)))
        let snapshot = WidgetCalendarSnapshot(cycleStartDay: 0, cycle: [false, true], overrides: [:])
        let metrics = WidgetCalendarLayoutMetrics(size: CGSize(width: 338, height: 354), inset: 16)
        for palette in WidgetCalendarPalette.allCases {
            let entry = WidgetMonthEntry(date: date, snapshot: snapshot, calendar: calendar, palette: palette)
            let cell = metrics.gridCellSize(rows: entry.rowCount, headerHeight: 60)
            for mode in [WidgetRenderingMode.accented, .vibrant] {
                let view = MonthCalendarWidgetView(entry: entry)
                    .frame(width: 338, height: 354)
                    .environment(\.widgetRenderingMode, mode)
                    .environment(\.colorScheme, .dark)
                let renderer = ImageRenderer(content: view)
                renderer.scale = 1
                let image = try #require(renderer.cgImage)
                var pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)
                let context = try #require(CGContext(data: &pixels, width: image.width, height: image.height,
                    bitsPerComponent: 8, bytesPerRow: image.width * 4, space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue))
                context.translateBy(x: 0, y: CGFloat(image.height))
                context.scaleBy(x: 1, y: -1)
                context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
                for (index, minimumAlpha) in [(0, 240), (entry.days.count - 1, 170)] {
                    let slot = index + entry.leadingEmptyCount
                    let x = 16 + CGFloat(slot % 7) * (cell.width + CalendarDayAppearance.spacing)
                    let y = 76 + CGFloat(slot / 7) * (cell.height + CalendarDayAppearance.spacing)
                    let backgroundAlpha = pixels[(Int(y + cell.height / 2) * image.width + Int(x + 3)) * 4 + 3]
                    #expect(backgroundAlpha < 64, "A solid template fill hides the date text")
                    var maximumGlyphAlpha: UInt8 = 0
                    for row in Int(y + cell.height / 2 - 7)...Int(y + cell.height / 2 + 7) {
                        for column in Int(x + cell.width / 2 - 9)...Int(x + cell.width / 2 + 9) {
                            maximumGlyphAlpha = max(maximumGlyphAlpha, pixels[(row * image.width + column) * 4 + 3])
                        }
                    }
                    #expect(Int(maximumGlyphAlpha) >= minimumAlpha, "Date text, including next month's dates, must remain readable")
                }
            }
        }
    }

    @Test func renderCalendarPaletteOptions() throws {
        if #available(iOS 17.0, *) {
            let calendar = WidgetCalendarTimeline.calendar(timeZone: TimeZone(secondsFromGMT: 8 * 3600)!)
            let date = try #require(calendar.date(from: .init(year: 2026, month: 11, day: 9, hour: 12)))
            let today = GregorianDay(year: 2026, month: .nov, day: 9).julianDay
            let first = GregorianDay(year: 2026, month: .nov, day: 1).julianDay
            let snapshot = WidgetCalendarSnapshot(cycleStartDay: today, cycle: [false, false, false, false, false, true, true],
                overrides: [today + 1: .init(isOffDay: true, name: "公共假日"), today + 2: .init(isOffDay: false)],
                details: [today: .init(customIsOffDay: true, comment: "和家人一起出游"),
                          today + 1: .init(publicIsOffDay: true), today + 2: .init(publicIsOffDay: false, customIsOffDay: false)],
                display: .init(firstWeekday: 2, blueWeekends: true,
                    alternativeDays: WidgetCalendarDisplay.chineseCalendarNames(for: Set(first..<(first + 42)))))
            let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("WidgetPreviews")
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            for appearance in [(ColorScheme.light, WidgetRenderingMode.fullColor), (.dark, .fullColor), (.light, .accented), (.dark, .accented)] {
                let (scheme, mode) = appearance
                let sheet = HStack(alignment: .top, spacing: 20) {
                    ForEach(WidgetCalendarPalette.allCases, id: \.self) { palette in
                        paletteColumn(palette, scheme: scheme, mode: mode, date: date, calendar: calendar, snapshot: snapshot, selectedDay: today)
                    }
                }
                .padding(20)
                .background(scheme == .dark ? Color(white: 0.08) : Color(white: 0.88))
                .environment(\.colorScheme, scheme)
                .environment(\.widgetRenderingMode, mode)
                .environment(\.locale, Locale(identifier: "zh-Hans"))
                let renderer = ImageRenderer(content: sheet)
                renderer.scale = 1.5
                let image = try #require(renderer.uiImage?.pngData())
                let prefix = mode == .fullColor ? "calendar-palettes" : "calendar-accented"
                try image.write(to: folder.appendingPathComponent("\(prefix)-\(scheme == .dark ? "dark" : "light").png"))
            }

            let monoSheet = HStack(alignment: .top, spacing: 24) {
                ForEach([false, true], id: \.self) { dark in
                    let scheme: ColorScheme = dark ? .dark : .light
                    VStack(spacing: 16) {
                        Text(verbatim: dark ? "Mono · 深色" : "Mono · 浅色")
                            .font(.system(size: 18, weight: .medium)).foregroundStyle(.black)
                        preview(MonthCalendarWidgetView(entry: .init(date: date, snapshot: snapshot, calendar: calendar, palette: .mono)),
                                size: CGSize(width: 338, height: 354), palette: .mono, scheme: scheme, mode: .fullColor)
                        preview(PeriodCalendarWidgetView(entry: .init(date: date, surface: .twoWeeks, snapshot: snapshot, calendar: calendar, palette: .mono)),
                                size: CGSize(width: 338, height: 158), palette: .mono, scheme: scheme, mode: .fullColor)
                        preview(PeriodCalendarWidgetView(entry: .init(date: date, surface: .threeDays, snapshot: snapshot, calendar: calendar, palette: .mono)),
                                size: CGSize(width: 158, height: 158), palette: .mono, scheme: scheme, mode: .fullColor)
                    }
                    .environment(\.colorScheme, scheme)
                }
            }
            .padding(24)
            .background(Color(white: 0.86))
            .environment(\.locale, Locale(identifier: "zh-Hans"))
            .environment(\.widgetRenderingMode, .fullColor)
            let monoRenderer = ImageRenderer(content: monoSheet)
            monoRenderer.scale = 2
            try #require(monoRenderer.uiImage?.pngData()).write(to: folder.appendingPathComponent("calendar-mono-no-popover.png"))
        }
    }

    @Test func renderEditorsInEverySupportedLanguage() throws {
        if #available(iOS 17.0, *) {
            let calendar = WidgetCalendarTimeline.calendar(timeZone: TimeZone(secondsFromGMT: 8 * 3600)!)
            let date = try #require(calendar.date(from: .init(year: 2026, month: 11, day: 9, hour: 12)))
            let today = GregorianDay(year: 2026, month: .nov, day: 9).julianDay
            let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("WidgetPreviews")
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            for width: CGFloat in [300, 338] {
                for scheme in [ColorScheme.light, .dark] {
                    let sheet = HStack(alignment: .top, spacing: 20) {
                        ForEach(["en", "ja", "ko", "zh-Hans", "zh-Hant", "zh-HK"], id: \.self) { language in
                            localizedEditorColumn(language: language, width: width, scheme: scheme,
                                                  date: date, calendar: calendar, dayIndex: today)
                        }
                    }
                    .padding(20)
                    .background(scheme == .dark ? Color(white: 0.08) : Color(white: 0.88))
                    .environment(\.colorScheme, scheme)
                    let renderer = ImageRenderer(content: sheet)
                    renderer.scale = 1.5
                    let data = try #require(renderer.uiImage?.pngData())
                    try data.write(to: folder.appendingPathComponent("calendar-editors-\(Int(width))-\(scheme == .dark ? "dark" : "light").png"))
                }
            }
        }
    }

    @available(iOS 17.0, *)
    private func localizedEditorColumn(language: String, width: CGFloat, scheme: ColorScheme,
                                       date: Date, calendar: Calendar, dayIndex: Int) -> some View {
        let captions = ["en": ("Public holiday", "A family day out"), "ja": ("祝日", "家族とお出かけ"),
                        "ko": ("공휴일", "가족과 나들이"), "zh-Hans": ("公共假日", "和家人一起出游"),
                        "zh-Hant": ("公眾假期", "與家人一起出遊"), "zh-HK": ("公眾假期", "與家人一起出遊")]
        let caption = captions[language]!
        let snapshots = Dictionary(uniqueKeysWithValues: WidgetCalendarSurface.allCases.map { surface in
            (surface, WidgetCalendarSnapshot(cycleStartDay: dayIndex, cycle: [false, false, false, false, false, true, true],
                overrides: [dayIndex: .init(isOffDay: false, name: caption.0)],
                details: [dayIndex: .init(publicIsOffDay: true, customIsOffDay: false, comment: caption.1)],
                display: .init(firstWeekday: 2),
                interaction: .init(selectedDay: dayIndex, expiresAt: date.addingTimeInterval(300), surface: surface)))
        })
        let smallWidth: CGFloat = width == 300 ? 140 : 158
        return VStack(spacing: 14) {
            Text(verbatim: language).font(.system(size: 16, weight: .medium))
                .foregroundStyle(scheme == .dark ? .white : .black)
            preview(MonthCalendarWidgetView(entry: .init(date: date, snapshot: snapshots[.month], calendar: calendar, palette: .mono)),
                    size: CGSize(width: width, height: width + 16), palette: .mono, scheme: scheme, mode: .fullColor)
            preview(PeriodCalendarWidgetView(entry: .init(date: date, surface: .twoWeeks, snapshot: snapshots[.twoWeeks], calendar: calendar, palette: .mono)),
                    size: CGSize(width: width, height: 158), palette: .mono, scheme: scheme, mode: .fullColor)
            preview(PeriodCalendarWidgetView(entry: .init(date: date, surface: .threeDays, snapshot: snapshots[.threeDays], calendar: calendar, palette: .mono)),
                    size: CGSize(width: smallWidth, height: smallWidth), palette: .mono, scheme: scheme, mode: .fullColor)
        }
        .environment(\.locale, Locale(identifier: language))
    }

    @available(iOS 17.0, *)
    private func paletteColumn(_ palette: WidgetCalendarPalette, scheme: ColorScheme, mode: WidgetRenderingMode, date: Date, calendar: Calendar,
                               snapshot: WidgetCalendarSnapshot, selectedDay: Int) -> some View {
        var monthSelection = snapshot
        monthSelection.interaction = .init(selectedDay: selectedDay, expiresAt: date.addingTimeInterval(300), surface: .month)
        var smallSelection = snapshot
        smallSelection.interaction = .init(selectedDay: selectedDay, expiresAt: date.addingTimeInterval(300), surface: .threeDays)
        var weekSelection = snapshot
        weekSelection.interaction = .init(selectedDay: selectedDay, expiresAt: date.addingTimeInterval(300), surface: .twoWeeks)
        return VStack(spacing: 14) {
            Text(LocalizedStringKey("widget.calendar.palette." + palette.rawValue))
                .font(.system(size: 16, weight: .medium)).foregroundStyle(scheme == .dark ? .white : .black)
            preview(MonthCalendarWidgetView(entry: .init(date: date, snapshot: snapshot, calendar: calendar, palette: palette)),
                    size: CGSize(width: 338, height: 354), palette: palette, scheme: scheme, mode: mode)
            preview(PeriodCalendarWidgetView(entry: .init(date: date, surface: .twoWeeks, snapshot: snapshot, calendar: calendar, palette: palette)),
                    size: CGSize(width: 338, height: 158), palette: palette, scheme: scheme, mode: mode)
            preview(PeriodCalendarWidgetView(entry: .init(date: date, surface: .twoWeeks, snapshot: weekSelection, calendar: calendar, palette: palette)),
                    size: CGSize(width: 338, height: 158), palette: palette, scheme: scheme, mode: mode)
            HStack(spacing: 22) {
                preview(PeriodCalendarWidgetView(entry: .init(date: date, surface: .threeDays, snapshot: snapshot, calendar: calendar, palette: palette)),
                        size: CGSize(width: 158, height: 158), palette: palette, scheme: scheme, mode: mode)
                preview(PeriodCalendarWidgetView(entry: .init(date: date, surface: .threeDays, snapshot: smallSelection, calendar: calendar, palette: palette)),
                        size: CGSize(width: 158, height: 158), palette: palette, scheme: scheme, mode: mode)
            }
            preview(MonthCalendarWidgetView(entry: .init(date: date, snapshot: monthSelection, calendar: calendar, palette: palette)),
                    size: CGSize(width: 338, height: 354), palette: palette, scheme: scheme, mode: mode)
        }
    }

    private func preview<V: View>(_ view: V, size: CGSize, palette: WidgetCalendarPalette, scheme: ColorScheme, mode: WidgetRenderingMode) -> some View {
        view.frame(width: size.width, height: size.height)
            .background(mode == .fullColor ? palette.colors(for: scheme).background : Color(white: scheme == .dark ? 0.16 : 0.94))
            .containerShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func contrast(_ foreground: Color, _ background: Color, scheme: ColorScheme) -> Double {
        func luminance(_ color: Color) -> Double {
            let resolved = UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: scheme == .dark ? .dark : .light))
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
            func linear(_ channel: CGFloat) -> Double {
                let value = Double(channel)
                return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
            }
            return linear(r) * 0.2126 + linear(g) * 0.7152 + linear(b) * 0.0722
        }
        let first = luminance(foreground), second = luminance(background)
        return (max(first, second) + 0.05) / (min(first, second) + 0.05)
    }
}
