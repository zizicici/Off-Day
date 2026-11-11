import SwiftUI

struct WidgetCountdownStyle: Codable, Equatable {
    var palette: WidgetCountdownPalette = .classic
    var font: WidgetCountdownFont = .rounded
}

enum WidgetCountdownTarget: String, Codable, CaseIterable, Sendable {
    case publicHoliday, offDay
}

enum WidgetCountdownPalette: String, Codable, CaseIterable, Sendable {
    case classic, mono

    // Previously configured colors migrate to Classic without remaining selectable.
    init?(rawValue: String) {
        switch rawValue {
        case "classic", "mint", "blue", "peach", "lilac", "automatic": self = .classic
        case "mono": self = .mono
        default: return nil
        }
    }

    var calendarPalette: WidgetCalendarPalette { self == .classic ? .classic : .mono }

    func colors(for scheme: ColorScheme) -> WidgetCountdownColors {
        let colors = calendarPalette.colors(for: scheme)
        return .init(background: colors.background, number: self == .classic ? colors.offAccent : colors.text,
                     text: colors.text, secondary: colors.text.opacity(0.6))
    }
}

enum WidgetCountdownFont: String, Codable, CaseIterable, Sendable {
    case rounded, standard, serif, monospaced

    func numberFont(size: CGFloat) -> Font {
        switch self {
        case .rounded: .system(size: size, weight: .heavy, design: .rounded)
        case .standard: .system(size: size, weight: .bold)
        case .serif: .system(size: size, weight: .bold, design: .serif)
        case .monospaced: .system(size: size, weight: .bold, design: .monospaced)
        }
    }
}

struct WidgetCountdownColors {
    var background: Color
    var number: Color
    var text: Color
    var secondary: Color
}
