import Foundation
import WidgetKit
import ZCCalendar

struct WidgetPeriodEntry: TimelineEntry {
    var date: Date
    var surface: WidgetCalendarSurface
    var firstWeekday: Int
    var days: [WidgetCalendarDayItem]
    var display: WidgetCalendarDisplay
    var interaction: WidgetCalendarInteraction?
    var palette: WidgetCalendarPalette
    var coloredPatterns: Bool
    var showsTodayIndicator: Bool

    var selectedDay: WidgetCalendarDayItem? { interaction?.day(in: days, surface: surface, at: date) }
    var firstDisplayedWeekday: Int { days[0].day.weekdayOrder().rawValue % 7 + 1 }

    init(date: Date, surface: WidgetCalendarSurface, snapshot: WidgetCalendarSnapshot?, calendar input: Calendar,
         palette: WidgetCalendarPalette = .classic, coloredPatterns: Bool = false, showsTodayIndicator: Bool = true) {
        precondition(surface != .month)
        self.date = date
        self.surface = surface
        self.palette = palette
        self.coloredPatterns = coloredPatterns
        self.showsTodayIndicator = surface == .twoWeeks && showsTodayIndicator
        display = snapshot?.display ?? WidgetCalendarDisplay()
        var calendar = input
        if let value = display.firstWeekday, (1...7).contains(value) { calendar.firstWeekday = value }
        firstWeekday = calendar.firstWeekday
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let today = GregorianDay(year: components.year!, month: Month(rawValue: components.month!)!, day: components.day!)
        let offset = surface == .twoWeeks ? (calendar.component(.weekday, from: date) - firstWeekday + 7) % 7 : 0
        let count = surface == .twoWeeks ? 14 : 3
        days = (0..<count).map { index in
            .make(day: GregorianDay(JDN: today.julianDay - offset + index), today: today, snapshot: snapshot)
        }
        interaction = snapshot?.interaction
    }
}
