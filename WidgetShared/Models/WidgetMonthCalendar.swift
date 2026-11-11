import Foundation
import WidgetKit
import ZCCalendar

struct WidgetMonthEntry: TimelineEntry {
    var date: Date
    var monthDate: Date
    var firstWeekday: Int
    var leadingEmptyCount: Int
    var rowCount: Int
    var days: [WidgetCalendarDayItem]
    var display: WidgetCalendarDisplay
    var interaction: WidgetCalendarInteraction?
    var palette: WidgetCalendarPalette
    var coloredPatterns: Bool
    var showsTodayIndicator: Bool

    var monthStartDay: Int { days[0].id }
    var previousMonthStart: Int? { WidgetCalendarMonthNavigation.adjacent(to: monthStartDay, offset: -1) }
    var nextMonthStart: Int? { WidgetCalendarMonthNavigation.adjacent(to: monthStartDay, offset: 1) }

    var selectedDay: WidgetCalendarDayItem? {
        interaction?.day(in: days, surface: .month, at: date)
    }

    init(date: Date, snapshot: WidgetCalendarSnapshot?, calendar inputCalendar: Calendar, palette: WidgetCalendarPalette = .classic,
         coloredPatterns: Bool = false, showsTodayIndicator: Bool = true) {
        self.date = date
        self.palette = palette
        self.coloredPatterns = coloredPatterns
        self.showsTodayIndicator = showsTodayIndicator
        display = snapshot?.display ?? WidgetCalendarDisplay()
        var calendar = inputCalendar
        if let firstWeekday = display.firstWeekday, (1...7).contains(firstWeekday) {
            calendar.firstWeekday = firstWeekday
        }
        firstWeekday = calendar.firstWeekday
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let today = GregorianDay(year: components.year!, month: Month(rawValue: components.month!)!, day: components.day!)
        let first: GregorianDay
        if let requested = snapshot?.displayedMonthStart, WidgetCalendarMonthNavigation.isValid(requested) {
            first = GregorianDay(JDN: requested)
        } else {
            first = GregorianDay(year: today.year, month: today.month, day: 1)
        }
        monthDate = calendar.date(from: DateComponents(year: first.year, month: first.month.rawValue, day: 1))!
        let leading = (calendar.component(.weekday, from: monthDate) - calendar.firstWeekday + 7) % 7
        let dayCount = calendar.range(of: .day, in: .month, for: monthDate)!.count
        let rows = leading + dayCount > 35 ? 6 : 5
        leadingEmptyCount = leading
        rowCount = rows
        // Keep weekday alignment with empty leading slots; only this month and next are visible.
        days = (0..<(rows * 7 - leading)).map { index in
            let day = GregorianDay(JDN: first.julianDay + index)
            return WidgetCalendarDayItem.make(day: day, today: today, displayedMonth: first, snapshot: snapshot)
        }
        interaction = snapshot?.interaction
    }
}

enum WidgetCalendarMonthNavigation {
    static func isValid(_ monthStart: Int) -> Bool {
        let lower = GregorianDay(year: 1, month: .jan, day: 1).julianDay
        let upper = GregorianDay(year: 9999, month: .dec, day: 1).julianDay
        guard (lower...upper).contains(monthStart) else { return false }
        return GregorianDay(JDN: monthStart).day == 1
    }

    static func adjacent(to monthStart: Int, offset: Int) -> Int? {
        guard isValid(monthStart), (-1...1).contains(offset) else { return nil }
        let first = GregorianDay(JDN: monthStart)
        let ordinal = (first.year - 1) * 12 + first.month.rawValue - 1 + offset
        guard (0..<(9999 * 12)).contains(ordinal) else { return nil }
        return GregorianDay(year: ordinal / 12 + 1, month: Month(rawValue: ordinal % 12 + 1)!, day: 1).julianDay
    }
}
