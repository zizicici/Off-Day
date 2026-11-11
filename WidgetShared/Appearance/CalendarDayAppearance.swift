import Foundation

/// The UIKit calendar and WidgetKit calendar share their visual rules and dimensions.
enum CalendarDayAppearance {
    static let spacing: CGFloat = 4
    static let inset: CGFloat = 3
    static let cornerRadius: CGFloat = 6
    static let dateFontSize: CGFloat = 16
    static let alternativeFontSize: CGFloat = 9
    static let alternativeHeight: CGFloat = 14
    static let holidayFontSize: CGFloat = 10
    static let holidayHeight: CGFloat = 16
    static let markSize: CGFloat = 15
    static let commentSize: CGFloat = 5
    static let commentInset: CGFloat = 5
    static let todayStrokeWidth: CGFloat = 3
    static let shadowOpacity: CGFloat = 0.1
    static let shadowRadius: CGFloat = 6
    static let shadowOffset = CGSize(width: 0, height: 2)

    struct Palette: Hashable {
        var backgroundAsset: String
        var whiteText: Bool
    }

    // Manual overrides use the existing corner mark; they do not replace the cell's background.
    static func palette(baseIsOffDay: Bool, publicIsOffDay: Bool?, blueWeekends: Bool, paperHolidayWorkdays: Bool) -> Palette {
        if let publicIsOffDay {
            if publicIsOffDay { return Palette(backgroundAsset: "OffDayColor", whiteText: true) }
            return Palette(backgroundAsset: paperHolidayWorkdays ? "PaperColor" : "WorkDayColor", whiteText: !paperHolidayWorkdays)
        }
        return Palette(backgroundAsset: baseIsOffDay ? (blueWeekends ? "WeekEndColor" : "OffDayColor") : "PaperColor", whiteText: baseIsOffDay)
    }
}

enum CalendarDayMarkInteraction {
    /// Tapping the selected mark clears it; tapping the other mark assigns that value.
    static func nextValue(current: Bool?, tapped: Bool) -> Bool? {
        current == tapped ? nil : tapped
    }
}
