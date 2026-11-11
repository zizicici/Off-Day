import Foundation

enum WidgetGregorianDateFormat {
    static func weekdayLabels(firstWeekday: Int, locale: Locale, abbreviated: Bool = false) -> [String] {
        let formatter = DateFormatter()
        formatter.locale = locale
        let symbols = abbreviated ? formatter.shortStandaloneWeekdaySymbols! : formatter.veryShortStandaloneWeekdaySymbols!
        return (0..<7).map { symbols[(firstWeekday - 1 + $0) % 7] }
    }
}

extension Date.FormatStyle {
    /// Widget dates use Gregorian models while keeping the user's language and field order.
    func widgetGregorian(locale: Locale, timeZone: TimeZone = .current) -> Self {
        var style = self.locale(locale)
        var calendar = WidgetCalendarTimeline.calendar(timeZone: timeZone)
        calendar.locale = locale
        style.calendar = calendar
        style.timeZone = timeZone
        return style
    }
}

extension WidgetCalendarDayItem {
    func formattedDate(locale: Locale, compact: Bool = false) -> String {
        let calendar = WidgetCalendarTimeline.calendar()
        let date = calendar.date(from: DateComponents(year: day.year, month: day.month.rawValue, day: day.day, hour: 12))!
        let format: Date.FormatStyle = compact
            ? .dateTime.month(.abbreviated).day().weekday(.abbreviated)
            : .dateTime.year().month(.wide).day().weekday(.wide)
        return format.widgetGregorian(locale: locale, timeZone: calendar.timeZone).format(date)
    }
}
