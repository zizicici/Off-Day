import Foundation
import WidgetKit
import ZCCalendar

extension WidgetCalendarSnapshot {
    /// Public holidays keep their identity even when the user marks that date as work.
    func nextPublicHoliday(after dayIndex: Int) -> Int? {
        guard isValid else { return nil }
        return details?.lazy.filter { $0.key > dayIndex && $0.value.publicIsOffDay == true }.map(\.key).min()
    }

    func nextOffDay(after dayIndex: Int) -> Int? {
        guard isValid else { return nil }
        let explicit = overrides.lazy.filter { $0.key > dayIndex && $0.value.isOffDay }.map(\.key).min()
        guard cycle.contains(true) else { return explicit }

        var cursor = dayIndex
        // Each blocked candidate consumes an explicit work override. This terminates
        // without an arbitrary date horizon, even with an all-work base calendar.
        while let distance = (1...cycle.count).first(where: { baseIsOffDay(at: cursor + $0) == true }) {
            let candidate = cursor + distance
            if let explicit, explicit <= candidate { return explicit }
            if overrides[candidate]?.isOffDay != false { return candidate }
            cursor = candidate
        }
        return explicit
    }
}

struct WidgetCalendarCountdown: Equatable {
    var daysRemaining: Int
    var date: Date
    var name: String?

    init(dayIndex: Int, today: Int, name: String? = nil, calendar: Calendar) {
        daysRemaining = dayIndex - today
        let day = GregorianDay(JDN: dayIndex)
        date = calendar.date(from: .init(year: day.year, month: day.month.rawValue, day: day.day, hour: 12))!
        self.name = name
    }
}

struct WidgetCountdownEntry: TimelineEntry {
    var date: Date
    var style: WidgetCountdownStyle
    var target: WidgetCountdownTarget
    var isReady: Bool
    var countdown: WidgetCalendarCountdown?

    init(date: Date, snapshot: WidgetCalendarSnapshot?, calendar: Calendar, style: WidgetCountdownStyle = .init(),
         target: WidgetCountdownTarget = .publicHoliday) {
        self.date = date
        self.style = style
        self.target = target
        isReady = snapshot?.isValid == true
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let today = GregorianDay(year: components.year!, month: Month(rawValue: components.month!)!, day: components.day!).julianDay
        switch target {
        case .publicHoliday:
            countdown = snapshot?.nextPublicHoliday(after: today).map {
                .init(dayIndex: $0, today: today, name: snapshot?.overrides[$0]?.name, calendar: calendar)
            }
        case .offDay:
            countdown = snapshot?.nextOffDay(after: today).map {
                let name = snapshot?.details?[$0]?.publicIsOffDay == true ? snapshot?.overrides[$0]?.name : nil
                return .init(dayIndex: $0, today: today, name: name, calendar: calendar)
            }
        }
    }
}
