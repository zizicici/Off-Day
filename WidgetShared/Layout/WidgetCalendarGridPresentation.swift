import Foundation

enum WidgetCalendarGridPresentation {
    case home, accessory

    var verticalSpacing: CGFloat { self == .accessory ? 2 : CalendarDayAppearance.spacing }
    var dateFontSize: CGFloat { self == .accessory ? 20 : CalendarDayAppearance.dateFontSize }
}
