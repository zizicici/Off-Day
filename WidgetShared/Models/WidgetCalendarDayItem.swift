import Foundation
import ZCCalendar

struct WidgetCalendarDayItem: Identifiable {
    var id: Int { day.julianDay }
    var day: GregorianDay
    var isCurrentMonth: Bool
    var isToday: Bool
    var value: WidgetCalendarDay?
    var baseIsOffDay: Bool?
    var detail: WidgetCalendarDayDetail?
    var alternativeName: String?

    static func make(day: GregorianDay, today: GregorianDay, displayedMonth: GregorianDay? = nil,
                     snapshot: WidgetCalendarSnapshot?) -> Self {
        Self(day: day,
             isCurrentMonth: displayedMonth.map { day.month == $0.month && day.year == $0.year } ?? true,
             isToday: day == today, value: snapshot?.day(at: day.julianDay),
             baseIsOffDay: snapshot?.baseIsOffDay(at: day.julianDay), detail: snapshot?.details?[day.julianDay],
             alternativeName: snapshot?.display?.alternativeDays[day.julianDay])
    }
}
