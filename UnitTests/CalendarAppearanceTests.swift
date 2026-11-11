import Foundation
import SwiftUI
import Testing
import UIKit
import WidgetKit
import ZCCalendar
@testable import Off_Day

@MainActor
struct CalendarAppearanceTests {
    @Test func existingUsersShouldKeepClassicAndAppearanceShouldPersistSeparately() throws {
        let domain = "CalendarAppearanceTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: domain))
        defer { defaults.removePersistentDomain(forName: domain) }
        #expect(CalendarAppearanceSettings.load(from: defaults) == CalendarVisualStyle())
        for style in [CalendarVisualStyle(coloredPatterns: true), .init(palette: .mono, coloredPatterns: true), .init()] {
            CalendarAppearanceSettings.save(style, to: defaults, notificationCenter: NotificationCenter())
            #expect(CalendarAppearanceSettings.load(from: defaults) == style)
            #expect(try JSONDecoder().decode(CalendarVisualStyle.self, from: #require(defaults.data(forKey: CalendarAppearanceSettings.key))) == style)
        }
        defaults.set(Data("invalid appearance".utf8), forKey: CalendarAppearanceSettings.key)
        #expect(CalendarAppearanceSettings.load(from: defaults) == CalendarVisualStyle())
    }

    @Test func configurationsShouldRetainPatternsWithoutChangingCalendarInformation() throws {
        if #available(iOS 17.0, *) {
            #expect(!MonthCalendarConfigurationIntent().coloredPatterns)
            #expect(!TwoWeekCalendarConfigurationIntent().coloredPatterns)
            #expect(!ThreeDayCalendarConfigurationIntent().coloredPatterns)
            let calendar = WidgetCalendarTimeline.calendar()
            let date = try #require(calendar.date(from: .init(year: 2026, month: 11, day: 10, hour: 23, minute: 59)))
            let day = GregorianDay(year: 2026, month: .nov, day: 10).julianDay
            let snapshot = WidgetCalendarSnapshot(cycleStartDay: day, cycle: [true, false],
                overrides: [day: .init(isOffDay: false, name: "Holiday")],
                details: [day: .init(publicIsOffDay: true, customIsOffDay: false, comment: "Keep this comment")])
            let month = MonthCalendarConfigurationIntent(palette: .classic, coloredPatterns: true)
            let monthly = WidgetMonthTimeline.entries(snapshot: snapshot, from: date, calendar: calendar,
                                                       palette: month.palette, coloredPatterns: month.coloredPatterns)
            let plain = WidgetMonthTimeline.entries(snapshot: snapshot, from: date, calendar: calendar)
            #expect(monthly.allSatisfy { $0.coloredPatterns })
            #expect(zip(monthly, plain).allSatisfy { $0.date == $1.date && $0.days.map(\.value) == $1.days.map(\.value) })
            for (surface, configuration) in [(WidgetCalendarSurface.twoWeeks, TwoWeekCalendarConfigurationIntent().coloredPatterns),
                                              (.threeDays, ThreeDayCalendarConfigurationIntent().coloredPatterns)] {
                #expect(!configuration)
                let entries = WidgetPeriodTimeline.entries(surface: surface, snapshot: snapshot, from: date,
                    calendar: calendar, coloredPatterns: true)
                #expect(entries.allSatisfy { $0.coloredPatterns })
                #expect(entries[0].days.first { $0.id == day }?.detail?.comment == "Keep this comment")
            }
        }
    }

    @Test func UIKitAndWidgetPaintShouldStayConsistentAcrossAppearanceChanges() {
        let roles = [CalendarDayAppearance.Palette(backgroundAsset: "PaperColor", whiteText: false),
                     .init(backgroundAsset: "OffDayColor", whiteText: true),
                     .init(backgroundAsset: "WeekEndColor", whiteText: true),
                     .init(backgroundAsset: "WorkDayColor", whiteText: true)]
        for style in [CalendarVisualStyle(), .init(coloredPatterns: true), .init(palette: .mono)] {
            for role in roles {
                let paint = CalendarCellPresentation(style: style, appearance: role)
                for scheme in [ColorScheme.light, .dark] {
                    let traits = UITraitCollection(userInterfaceStyle: scheme == .dark ? .dark : .light)
                    let colors = style.palette.colors(for: scheme, coloredPatterns: style.coloredPatterns)
                    expectSameColor(paint.background, UIColor(colors.background(for: role)), traits: traits)
                    expectSameColor(paint.foreground, UIColor(colors.foreground(for: role)), traits: traits)
                    expectSameColor(paint.today, UIColor(colors.todayStroke(for: role)), traits: traits)
                    if style.usesColoredPatterns {
                        #expect(colors.usesPatterns && !colors.usesOriginalMarks)
                        #expect(colors.usesColoredPatterns)
                        expectSameColor(UIColor(colors.markSymbol(appearance: role)), .white, traits: traits)
                    }
                }
            }
        }
    }

    private func expectSameColor(_ actual: UIColor, _ expected: UIColor, traits: UITraitCollection,
                                 sourceLocation: SourceLocation = #_sourceLocation) {
        func components(_ color: UIColor) -> [CGFloat] {
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            #expect(color.resolvedColor(with: traits).getRed(&red, green: &green, blue: &blue, alpha: &alpha),
                    sourceLocation: sourceLocation)
            return [red, green, blue, alpha]
        }
        // UIKit assets and SwiftUI Color can resolve into different color spaces.
        #expect(zip(components(actual), components(expected)).allSatisfy { abs($0 - $1) < 0.0001 },
                sourceLocation: sourceLocation)
    }

    @Test func renderAppAndWidgetStylesTogether() throws {
        let calendar = WidgetCalendarTimeline.calendar()
        let date = try #require(calendar.date(from: .init(year: 2026, month: 11, day: 9, hour: 12)))
        let first = GregorianDay(year: 2026, month: .nov, day: 9)
        let roles = [CalendarDayAppearance.Palette(backgroundAsset: "PaperColor", whiteText: false),
                     .init(backgroundAsset: "OffDayColor", whiteText: true),
                     .init(backgroundAsset: "WeekEndColor", whiteText: true),
                     .init(backgroundAsset: "WorkDayColor", whiteText: true)]
        let styles = [CalendarVisualStyle(), .init(coloredPatterns: true), .init(palette: .mono)]
        let titles = ["经典 · 纯色", "经典 · 彩色纹理", "黑白"]
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("WidgetPreviews")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for scheme in [ColorScheme.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: scheme == .dark ? .dark : .light)
            let images = try styles.map { style in
                try roles.enumerated().map { index, role in
                    try renderCell(day: first + index, role: role, style: style, traits: traits, custom: index == 0 ? .offDay : .workDay)
                }
            }
            let sheet = HStack(alignment: .top, spacing: 24) {
                ForEach(0..<styles.count, id: \.self) { index in
                    let style = styles[index]
                    VStack(spacing: 14) {
                        Text(verbatim: titles[index]).font(.headline)
                        Text(verbatim: "主 App").font(.caption)
                        HStack(spacing: 4) {
                            ForEach(0..<roles.count, id: \.self) { role in
                                Image(uiImage: images[index][role]).frame(width: 44, height: 52)
                            }
                        }
                        Text(verbatim: "Widget").font(.caption)
                        HStack(spacing: 4) {
                            ForEach(0..<roles.count, id: \.self) { roleIndex in
                                let role = roles[roleIndex]
                                let item = widgetDay(day: first + roleIndex, role: role, custom: roleIndex == 0)
                                WidgetCalendarDayCell(day: item, display: .init(blueWeekends: true), surface: .month,
                                    size: CGSize(width: 44, height: 52))
                            }
                        }
                        .environment(\.widgetCalendarColors, style.palette.colors(for: scheme, coloredPatterns: style.coloredPatterns))
                        MonthCalendarWidgetView(entry: .init(date: date, snapshot: previewSnapshot(day: first.julianDay),
                            calendar: calendar, palette: style.palette, coloredPatterns: style.coloredPatterns))
                            .frame(width: 300, height: 316)
                            .background(style.palette.colors(for: scheme, coloredPatterns: style.coloredPatterns).background)
                            .containerShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    }
                    .padding(16)
                    .background(style.palette.colors(for: scheme, coloredPatterns: style.coloredPatterns).background,
                                in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                }
            }
            .padding(24)
            .background(Color(white: scheme == .dark ? 0.06 : 0.85))
            .foregroundStyle(scheme == .dark ? .white : .black)
            .environment(\.colorScheme, scheme)
            .environment(\.locale, Locale(identifier: "zh-Hans"))
            let renderer = ImageRenderer(content: sheet)
            renderer.scale = 2
            try #require(renderer.uiImage?.pngData()).write(to: folder.appendingPathComponent("calendar-app-widget-appearance-\(scheme == .dark ? "dark" : "light").png"))
        }
    }

    private func renderCell(day: GregorianDay, role: CalendarDayAppearance.Palette, style: CalendarVisualStyle,
                            traits: UITraitCollection, custom: DayType) throws -> UIImage {
        let scene = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 44, height: 52)
        let controller = UIViewController()
        controller.overrideUserInterfaceStyle = traits.userInterfaceStyle
        window.rootViewController = controller
        window.isHidden = false
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        var image: UIImage!
        traits.performAsCurrent {
            let paint = CalendarCellPresentation(style: style, appearance: role)
            let cell = BlockCell(frame: CGRect(x: 0, y: 0, width: 44, height: 52))
            controller.view.addSubview(cell)
            var item = BlockItem(index: day.julianDay, publicDayName: nil, baseCalendarDayType: role.whiteText ? .offDay : .workDay,
                publicDayType: nil, customDayInfo: .init(dayIndex: day.julianDay,
                    customDay: .init(dayIndex: Int64(day.julianDay), dayType: custom)),
                backgroundColor: paint.background, foregroundColor: paint.foreground, isToday: false,
                alternativeCalendarDayName: "初一", alternativeCalendarA11yName: nil)
            item.appearance = role
            item.visualStyle = style
            cell.update(with: item)
            cell.updateConfiguration(using: cell.configurationState)
            window.layoutIfNeeded()
            cell.layoutIfNeeded()
            #expect(cell.traitCollection.userInterfaceStyle == traits.userInterfaceStyle)
            image = UIGraphicsImageRenderer(size: cell.bounds.size).image { cell.layer.render(in: $0.cgContext) }
        }
        return try #require(image)
    }

    private func widgetDay(day: GregorianDay, role: CalendarDayAppearance.Palette, custom off: Bool) -> WidgetCalendarDayItem {
        .init(day: day, isCurrentMonth: true, isToday: false, value: .init(isOffDay: off),
            baseIsOffDay: role.backgroundAsset == "WeekEndColor",
            detail: .init(publicIsOffDay: role.backgroundAsset == "OffDayColor" ? true : (role.backgroundAsset == "WorkDayColor" ? false : nil),
                          customIsOffDay: off), alternativeName: "初一")
    }

    private func previewSnapshot(day: Int) -> WidgetCalendarSnapshot {
        .init(cycleStartDay: day, cycle: [false, false, false, false, false, true, true],
            overrides: [day + 1: .init(isOffDay: true, name: "公共假期"), day + 2: .init(isOffDay: false)],
            details: [day: .init(customIsOffDay: true), day + 1: .init(publicIsOffDay: true),
                      day + 2: .init(publicIsOffDay: false, customIsOffDay: false)], display: .init(firstWeekday: 2, blueWeekends: true))
    }
}
