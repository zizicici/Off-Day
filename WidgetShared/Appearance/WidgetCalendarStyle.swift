import SwiftUI
import WidgetKit
import UIKit

struct CalendarVisualStyle: Codable, Hashable {
    var palette: WidgetCalendarPalette = .classic
    var coloredPatterns = false

    var usesColoredPatterns: Bool { palette == .classic && coloredPatterns }
}

/// Presentation stays in the widget's configuration, independent of shared calendar records.
enum WidgetCalendarPalette: String, Codable, CaseIterable, Sendable {
    case classic, mono

    func colors(for scheme: ColorScheme, renderingMode: WidgetRenderingMode = .fullColor,
                coloredPatterns: Bool = false) -> WidgetCalendarColors {
        guard renderingMode == .fullColor else { return .systemRendered }
        switch self {
        case .classic:
            return coloredPatterns ? .coloredPatterns(for: scheme) : .classic
        case .mono:
            return scheme == .dark
                ? .init(background: 0x111111, paper: 0x292929, text: 0xF2F2F2,
                        off: 0xE8E8E8, weekend: 0xCBCBCB, work: 0x333333, today: 0xF2F2F2,
                        offAccent: 0xEEEEEE, workAccent: 0xC2C2C2, onOff: 0x1A1A1A, onWork: 0xF2F2F2,
                        todayOnAccent: 0x1A1A1A, usesPatterns: true)
                : .init(background: 0xF5F5F5, paper: 0xFFFFFF, text: 0x202020,
                        off: 0x272727, weekend: 0x484848, work: 0xF1F1F1, today: 0x202020,
                        offAccent: 0x202020, workAccent: 0x505050, onWork: 0x202020,
                        todayOnAccent: 0xFFFFFF, usesPatterns: true)
        }
    }
}

struct WidgetCalendarColors {
    var background: Color
    var paper: Color
    var text: Color
    var off: Color
    var weekend: Color
    var work: Color
    var today: Color
    var offAccent: Color
    var workAccent: Color
    var onOff: Color
    var onWork: Color
    var todayOnAccent: Color
    var usesSystemRendering = false
    var usesOriginalMarks = false
    var usesPatterns = false
    var usesColoredPatterns = false
    var patternOpacity: Double = 0.22
    var weekendAccent: Color

    static let classic = Self(background: Color("BackgroundColor"), paper: Color("PaperColor"),
        text: Color("TextColor"), off: Color("OffDayColor"), weekend: Color("WeekEndColor"),
        work: Color("WorkDayColor"), today: Color("TodayColor"),
        offAccent: Color("OffDayColor"), workAccent: Color("WorkDayColor"), usesOriginalMarks: true)

    // Accented/clear widgets are alpha templates: opaque text needs a faint, separate fill.
    static let systemRendered = Self(background: .primary.opacity(0.06), paper: .primary.opacity(0.04),
        text: .primary, off: .primary.opacity(0.16), weekend: .primary.opacity(0.12),
        work: .primary.opacity(0.06), today: .primary, offAccent: .primary, workAccent: .primary,
        onOff: .primary, onWork: .primary, usesSystemRendering: true, usesPatterns: true, patternOpacity: 0.10)

    static func coloredPatterns(for scheme: ColorScheme) -> Self {
        scheme == .dark ? coloredPatternDark : coloredPatternLight
    }

    private static let coloredPatternLight = makeColoredPatterns(for: .light)
    private static let coloredPatternDark = makeColoredPatterns(for: .dark)

    private static func makeColoredPatterns(for scheme: ColorScheme) -> Self {
        let traits = UITraitCollection(userInterfaceStyle: scheme == .dark ? .dark : .light)
        func components(_ name: String) -> [Double] {
            let color = UIColor(named: name)!.resolvedColor(with: traits)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            color.getRed(&r, green: &g, blue: &b, alpha: &a)
            return [Double(r), Double(g), Double(b)]
        }
        let paper = components("PaperColor")
        func tintedComponents(_ name: String) -> [Double] {
            zip(paper, components(name)).map { $0 + ($1 - $0) * 0.08 }
        }
        func color(_ values: [Double]) -> Color {
            Color(.sRGB, red: values[0], green: values[1], blue: values[2], opacity: 1)
        }
        func tint(_ name: String) -> Color {
            color(tintedComponents(name))
        }
        var colors = Self.classic
        colors.off = tint("OffDayColor")
        colors.weekend = tint("WeekEndColor")
        colors.work = tint("WorkDayColor")
        colors.onOff = colors.text
        colors.onWork = colors.text
        colors.usesOriginalMarks = false
        colors.usesPatterns = true
        colors.usesColoredPatterns = true
        colors.patternOpacity = scheme == .dark ? 0.35 : 0.65
        return colors
    }

    init(background: Color, paper: Color, text: Color, off: Color, weekend: Color, work: Color,
         today: Color, offAccent: Color, workAccent: Color, onOff: Color = .white, onWork: Color = .white,
         todayOnAccent: Color? = nil, usesOriginalMarks: Bool = false, usesSystemRendering: Bool = false,
         usesPatterns: Bool = false, patternOpacity: Double = 0.22) {
        self.background = background
        self.paper = paper
        self.text = text
        self.off = off
        self.weekend = weekend
        self.work = work
        self.today = today
        self.offAccent = offAccent
        self.workAccent = workAccent
        self.onOff = onOff
        self.onWork = onWork
        self.todayOnAccent = todayOnAccent ?? today
        self.usesSystemRendering = usesSystemRendering
        self.usesOriginalMarks = usesOriginalMarks
        self.usesPatterns = usesPatterns
        self.patternOpacity = patternOpacity
        self.weekendAccent = weekend
    }

    init(background: UInt32, paper: UInt32, text: UInt32, off: UInt32, weekend: UInt32,
         work: UInt32, today: UInt32, offAccent: UInt32? = nil, workAccent: UInt32? = nil,
         onOff: UInt32 = 0xFFFFFF, onWork: UInt32 = 0xFFFFFF, todayOnAccent: UInt32? = nil,
         usesPatterns: Bool = false) {
        func color(_ hex: UInt32) -> Color {
            Color(.sRGB, red: Double((hex >> 16) & 255) / 255,
                  green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1)
        }
        self.init(background: color(background), paper: color(paper), text: color(text), off: color(off),
                  weekend: color(weekend), work: color(work), today: color(today),
                  offAccent: color(offAccent ?? off), workAccent: color(workAccent ?? work),
                  onOff: color(onOff), onWork: color(onWork), todayOnAccent: todayOnAccent.map(color),
                  usesPatterns: usesPatterns)
    }

    func background(for appearance: CalendarDayAppearance.Palette) -> Color {
        switch appearance.backgroundAsset {
        case "OffDayColor": off
        case "WeekEndColor": weekend
        case "WorkDayColor": work
        default: paper
        }
    }

    func usesInkBacking(for appearance: CalendarDayAppearance.Palette) -> Bool {
        usesPatterns && !usesSystemRendering && CalendarDayTexture(appearance: appearance) != .plain
    }

    func markControl(isOffDay: Bool, selected: Bool) -> CalendarMarkControlAppearance {
        let palette = CalendarDayAppearance.Palette(backgroundAsset: isOffDay ? "OffDayColor" : "WorkDayColor", whiteText: true)
        let patterned = usesInkBacking(for: palette)
        let accent = isOffDay ? offAccent : workAccent
        let foreground = patterned ? foreground(for: palette) : accent
        return .init(palette: palette, foreground: foreground,
                     background: patterned ? background(for: palette) : accent.opacity(selected ? 0.2 : 0.12),
                     stroke: patterned && selected ? foreground.opacity(0.55) : .clear,
                     usesPatterns: patterned)
    }

    func todayStroke(for appearance: CalendarDayAppearance.Palette) -> Color {
        guard appearance.whiteText else { return today }
        if usesPatterns && !usesColoredPatterns && appearance.backgroundAsset == "WorkDayColor" { return onWork }
        return todayOnAccent
    }

    func foreground(for appearance: CalendarDayAppearance.Palette) -> Color {
        guard appearance.whiteText else { return text }
        return appearance.backgroundAsset == "WorkDayColor" ? onWork : onOff
    }

    func patternColor(for appearance: CalendarDayAppearance.Palette) -> Color {
        guard usesColoredPatterns else { return foreground(for: appearance) }
        return switch appearance.backgroundAsset {
        case "OffDayColor": offAccent
        case "WeekEndColor": weekendAccent
        case "WorkDayColor": workAccent
        default: text
        }
    }

    func markFill(isOffDay: Bool, appearance: CalendarDayAppearance.Palette) -> Color {
        usesColoredPatterns ? (isOffDay ? offAccent : workAccent) : foreground(for: appearance)
    }

    func markSymbol(appearance: CalendarDayAppearance.Palette) -> Color {
        usesColoredPatterns ? .white : background(for: appearance)
    }
}

struct CalendarMarkControlAppearance {
    var palette: CalendarDayAppearance.Palette
    var foreground: Color
    var background: Color
    var stroke: Color
    var usesPatterns: Bool
}

private struct WidgetCalendarColorsKey: EnvironmentKey {
    static let defaultValue = WidgetCalendarColors.classic
}

extension EnvironmentValues {
    var widgetCalendarColors: WidgetCalendarColors {
        get { self[WidgetCalendarColorsKey.self] }
        set { self[WidgetCalendarColorsKey.self] = newValue }
    }
}
