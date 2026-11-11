import SwiftUI

extension WidgetCalendarDayItem {
    func palette(display: WidgetCalendarDisplay) -> CalendarDayAppearance.Palette {
        CalendarDayAppearance.palette(baseIsOffDay: baseIsOffDay == true, publicIsOffDay: detail?.publicIsOffDay,
            blueWeekends: display.blueWeekends, paperHolidayWorkdays: display.paperHolidayWorkdays)
    }

    func foreground(display: WidgetCalendarDisplay, colors: WidgetCalendarColors) -> Color {
        colors.foreground(for: palette(display: display))
    }
}
