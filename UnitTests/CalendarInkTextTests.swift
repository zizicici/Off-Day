import CoreText
import Foundation
import MarqueeLabel
import SwiftUI
import Testing
import UIKit
import WidgetKit
import ZCCalendar
@testable import Off_Day

@MainActor
struct CalendarInkTextTests {
    @Test func texturedPalettesShouldShareBackingWhileSystemTemplatesKeepNativeText() {
        let textured = CalendarDayAppearance.Palette(backgroundAsset: "WeekEndColor", whiteText: true)
        let plain = CalendarDayAppearance.Palette(backgroundAsset: "PaperColor", whiteText: false)
        for scheme in [ColorScheme.light, .dark] {
            for palette in WidgetCalendarPalette.allCases {
                let colors = palette.colors(for: scheme, coloredPatterns: true)
                #expect(colors.usesInkBacking(for: textured))
                #expect(!colors.usesInkBacking(for: plain))
                #expect(!palette.colors(for: scheme, renderingMode: .accented, coloredPatterns: true).usesInkBacking(for: textured))
            }
            #expect(!WidgetCalendarColors.classic.usesInkBacking(for: textured))
        }
    }

    @Test func backingShouldFollowVisibleGlyphsAfterShrinkingAndTruncating() throws {
        let samples: [(String, UIFont, CGSize)] = [
            ("二", .systemFont(ofSize: 9), .init(width: 36, height: 14)),
            ("廿二", .systemFont(ofSize: 9), .init(width: 36, height: 14)),
            ("30", .monospacedDigitSystemFont(ofSize: 16, weight: .regular), .init(width: 36, height: 19)),
            ("公共假期安排", .systemFont(ofSize: 10, weight: .bold), .init(width: 30, height: 16)),
            ("Public holiday for the whole family", .systemFont(ofSize: 10, weight: .bold), .init(width: 30, height: 16)),
            ("休み / Work", .systemFont(ofSize: 9), .init(width: 30, height: 14)),
            ("gyp", .systemFont(ofSize: 10), .init(width: 30, height: 16)),
            ("   二   ", .systemFont(ofSize: 9), .init(width: 44, height: 14))
        ]
        for (text, font, size) in samples {
            let layout = CalendarInkTextLayout.resolve(text, font: font, size: size)
            let visible = layout.visibleBounds(in: size)
            let textPixels = try alphaBounds(render(layout, size: size, foreground: .black, backing: .clear))
            expectNear(textPixels, visible)
            let backing = visible.insetBy(dx: -1.5, dy: -1.5)
            let backingPixels = try alphaBounds(render(layout, size: size, foreground: .clear, backing: .black))
            expectNear(backingPixels, backing.intersection(CGRect(origin: .zero, size: size)))
            #expect(layout.font.pointSize >= font.pointSize * 0.5 - 0.001)
            #expect(layout.advance <= size.width + 0.01)
        }
        let two = CalendarInkTextLayout.resolve("二", font: .systemFont(ofSize: 9), size: .init(width: 36, height: 14))
        #expect(two.glyphBounds.height < two.ascent + two.descent - 3)
        let long = CalendarInkTextLayout.resolve("Public holiday for the whole family", font: .systemFont(ofSize: 10), size: .init(width: 30, height: 16))
        #expect(long.isTruncated)
    }

    @Test func cacheShouldDistinguishTextFontLocaleAndAvailableSpace() {
        let font = UIFont.systemFont(ofSize: 10)
        let size = CGSize(width: 32, height: 16)
        let line = CalendarInkTextLayout.resolve("公共假期", font: font, size: size, locale: Locale(identifier: "zh-Hans"))
        #expect(line === CalendarInkTextLayout.resolve("公共假期", font: font, size: size, locale: Locale(identifier: "zh-Hans")))
        #expect(line !== CalendarInkTextLayout.resolve("公共假日", font: font, size: size, locale: Locale(identifier: "zh-Hans")))
        #expect(line !== CalendarInkTextLayout.resolve("公共假期", font: .systemFont(ofSize: 10, weight: .bold), size: size, locale: Locale(identifier: "zh-Hans")))
        #expect(line !== CalendarInkTextLayout.resolve("公共假期", font: font, size: .init(width: 42, height: 16), locale: Locale(identifier: "zh-Hans")))
        #expect(line !== CalendarInkTextLayout.resolve("公共假期", font: font, size: size, locale: Locale(identifier: "ja")))
        for text in ["", "   "] {
            #expect(CalendarInkTextLayout.resolve(text, font: font, size: size).visibleBounds(in: size).isNull)
        }
    }

    @Test func labelShouldReturnToNativeDrawingAndMarqueeShouldKeepItsTextWhenStyleChanges() throws {
        let bounds = CGRect(x: 0, y: 0, width: 44, height: 24)
        let label = CalendarInkTextLabel(frame: bounds)
        let original = UILabel(frame: bounds)
        for view in [label, original] {
            view.text = "廿二"; view.font = .systemFont(ofSize: 9)
            view.textColor = .black; view.textAlignment = .center
        }
        label.inkBackingColor = .white
        _ = render(label)
        label.inkBackingColor = nil
        #expect(render(label).pngData() == render(original).pngData())

        let day = GregorianDay(year: 2026, month: .nov, day: 10)
        let name = "Public holiday for the whole family"
        let role = CalendarDayAppearance.Palette(backgroundAsset: "OffDayColor", whiteText: true)
        let cell = BlockCell(frame: .init(x: 0, y: 0, width: 44, height: 52))
        for style in [CalendarVisualStyle(coloredPatterns: true), .init(), .init(palette: .mono), .init()] {
            let patterned = style.usesColoredPatterns || style.palette == .mono
            let paint = CalendarCellPresentation(style: style, appearance: role)
            var item = BlockItem(index: day.julianDay, publicDayName: name, baseCalendarDayType: .workDay,
                publicDayType: .offDay, customDayInfo: .init(dayIndex: day.julianDay),
                backgroundColor: paint.background, foregroundColor: paint.foreground, isToday: false,
                alternativeCalendarDayName: "廿二", alternativeCalendarA11yName: nil)
            item.appearance = role; item.visualStyle = style
            cell.update(with: item)
            cell.updateConfiguration(using: cell.configurationState)
            cell.layoutIfNeeded()
            #expect(!cell.publicDayLabel.labelize)
            #expect(!cell.publicDayLabel.holdScrolling)
            #expect(cell.accessibilityValue?.contains(name) == true)
            if patterned {
                let string = try #require(cell.publicDayLabel.attributedText)
                let attachment = try #require(string.attribute(.attachment, at: 0, effectiveRange: nil) as? NSTextAttachment)
                #expect(attachment.bounds.width > cell.publicDayLabel.bounds.width)
                #expect(attachment.image != nil)
            } else {
                #expect(cell.publicDayLabel.text == name)
                #expect(cell.publicDayLabel.attributedText?.attribute(.attachment, at: 0, effectiveRange: nil) == nil)
            }
        }
    }

    @Test func renderActualCellsAndAllWidgetSizes() throws {
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("WidgetPreviews/InkBacking")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var calendar = WidgetCalendarTimeline.calendar()
        calendar.locale = Locale(identifier: "zh-Hans")
        let date = try #require(calendar.date(from: .init(year: 2026, month: 11, day: 10, hour: 12)))
        let today = GregorianDay(year: 2026, month: .nov, day: 10).julianDay
        let names = WidgetCalendarDisplay.chineseCalendarNames(for: Set((today - 15)..<(today + 45)))
        let snapshot = WidgetCalendarSnapshot(cycleStartDay: today,
            cycle: [false, false, false, false, true, true, false],
            overrides: [today: .init(isOffDay: true, name: "公共假期"),
                        today + 1: .init(isOffDay: false, name: "Public holiday"),
                        today + 2: .init(isOffDay: true, name: "建国記念の日")],
            details: [today: .init(publicIsOffDay: true, customIsOffDay: true, comment: "备注"),
                      today + 1: .init(publicIsOffDay: false, customIsOffDay: false),
                      today + 2: .init(publicIsOffDay: true)],
            display: .init(firstWeekday: 2, blueWeekends: true, alternativeDays: names))
        for palette in WidgetCalendarPalette.allCases {
        for scheme in [ColorScheme.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: scheme == .dark ? .dark : .light)
            let style = CalendarVisualStyle(palette: palette, coloredPatterns: true)
            let colors = palette.colors(for: scheme, coloredPatterns: true)
            let appImages = try ["公共假期", "Public holiday", "建国記念の日", "二", "十一月廿二"].enumerated().map { index, text in
                try appCellImage(index: today + index, name: text, traits: traits, role: index % 3, style: style)
            }
            let sheet = VStack(alignment: .leading, spacing: 16) {
                Text(verbatim: "\(palette == .mono ? "黑白" : "彩色纹理") · 字迹范围外扩 1.5 pt").font(.headline)
                Text(verbatim: "主 App · 保留长名称滚动").font(.caption)
                HStack(spacing: 8) {
                    ForEach(appImages.indices, id: \.self) { index in
                        Image(uiImage: appImages[index]).frame(width: 44, height: 52)
                    }
                }
                HStack(alignment: .top, spacing: 16) {
                    MonthCalendarWidgetView(entry: .init(date: date, snapshot: snapshot,
                        calendar: calendar, palette: palette, coloredPatterns: true))
                        .frame(width: 300, height: 316).modifier(InkPreviewContainer(colors: colors))
                    VStack(alignment: .leading, spacing: 16) {
                        PeriodCalendarWidgetView(entry: .init(date: date, surface: .twoWeeks, snapshot: snapshot,
                            calendar: calendar, palette: palette, coloredPatterns: true))
                            .frame(width: 300, height: 141).modifier(InkPreviewContainer(colors: colors))
                        PeriodCalendarWidgetView(entry: .init(date: date, surface: .threeDays, snapshot: snapshot,
                            calendar: calendar, palette: palette, coloredPatterns: true))
                            .frame(width: 141, height: 141).modifier(InkPreviewContainer(colors: colors))
                    }
                }
            }.padding(24).foregroundStyle(scheme == .dark ? .white : .black)
                .background(Color(white: scheme == .dark ? 0.06 : 0.85))
                .environment(\.colorScheme, scheme).environment(\.locale, Locale(identifier: "zh-Hans"))
            let renderer = ImageRenderer(content: sheet)
            renderer.scale = 3
            try #require(renderer.uiImage?.pngData()).write(to: folder.appendingPathComponent("actual-app-widgets-\(palette.rawValue)-\(scheme == .dark ? "dark" : "light").png"))
        }
        }
    }

    private func appCellImage(index: Int, name: String, traits: UITraitCollection, role: Int,
                              style: CalendarVisualStyle) throws -> UIImage {
        let scene = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.frame = .init(x: 0, y: 0, width: 44, height: 52)
        let controller = UIViewController()
        controller.overrideUserInterfaceStyle = traits.userInterfaceStyle
        window.rootViewController = controller
        window.isHidden = false
        defer { window.isHidden = true; window.rootViewController = nil }
        let role = CalendarDayAppearance.Palette(backgroundAsset: ["OffDayColor", "WorkDayColor", "WeekEndColor"][role], whiteText: true)
        let paint = CalendarCellPresentation(style: style, appearance: role)
        let cell = BlockCell(frame: .init(x: 0, y: 0, width: 44, height: 52))
        controller.view.addSubview(cell)
        var item = BlockItem(index: index, publicDayName: name, baseCalendarDayType: .workDay,
            publicDayType: .offDay, customDayInfo: .init(dayIndex: index),
            backgroundColor: paint.background, foregroundColor: paint.foreground, isToday: false,
            alternativeCalendarDayName: "廿二", alternativeCalendarA11yName: nil)
        item.appearance = role; item.visualStyle = style
        cell.update(with: item)
        cell.updateConfiguration(using: cell.configurationState)
        window.layoutIfNeeded()
        cell.layoutIfNeeded()
        return render(cell)
    }

    private func render(_ view: UIView) -> UIImage {
        view.setNeedsDisplay(); view.layer.displayIfNeeded()
        return UIGraphicsImageRenderer(size: view.bounds.size).image { view.layer.render(in: $0.cgContext) }
    }

    private func render(_ layout: CalendarInkTextLayout, size: CGSize, foreground: UIColor, backing: UIColor) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3
        format.preferredRange = .standard
        return UIGraphicsImageRenderer(size: size, format: format).image {
            layout.draw(in: $0.cgContext, size: size, foreground: foreground.cgColor, backing: backing.cgColor)
        }
    }

    private func alphaBounds(_ image: UIImage) throws -> CGRect {
        let cg = try #require(image.cgImage)
        var bytes = [UInt8](repeating: 0, count: cg.width * cg.height * 4)
        let context = try #require(CGContext(data: &bytes, width: cg.width, height: cg.height, bitsPerComponent: 8,
            bytesPerRow: cg.width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(cg, in: .init(x: 0, y: 0, width: cg.width, height: cg.height))
        var minX = cg.width, minY = cg.height, maxX = -1, maxY = -1
        for y in 0..<cg.height {
            for x in 0..<cg.width where bytes[(y * cg.width + x) * 4 + 3] > 32 {
                minX = min(minX, x); minY = min(minY, y)
                maxX = max(maxX, x); maxY = max(maxY, y)
            }
        }
        #expect(maxX >= 0)
        return CGRect(x: CGFloat(minX) / image.scale, y: CGFloat(minY) / image.scale,
                      width: CGFloat(maxX - minX + 1) / image.scale, height: CGFloat(maxY - minY + 1) / image.scale)
    }

    private func expectNear(_ actual: CGRect, _ expected: CGRect, sourceLocation: SourceLocation = #_sourceLocation) {
        // Ideal glyph bounds exclude antialias coverage. Allow less than one point at 3x.
        #expect(abs(actual.minX - expected.minX) < 0.8, sourceLocation: sourceLocation)
        #expect(abs(actual.minY - expected.minY) < 0.8, sourceLocation: sourceLocation)
        #expect(abs(actual.maxX - expected.maxX) < 0.8, sourceLocation: sourceLocation)
        #expect(abs(actual.maxY - expected.maxY) < 0.8, sourceLocation: sourceLocation)
    }
}

private struct InkPreviewContainer: ViewModifier {
    var colors: WidgetCalendarColors
    func body(content: Content) -> some View {
        content.background(colors.background)
            .containerShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}
