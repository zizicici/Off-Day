import Foundation

extension WidgetCalendarSnapshot {
    static var monthPreview: Self {
        let calendar = WidgetCalendarTimeline.calendar()
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let entry = WidgetMonthEntry(date: now, snapshot: nil, calendar: calendar)
        let today = entry.days.first { $0.isToday }!.id
        var snapshot = Self(cycleStartDay: today, cycle: (0..<7).map { (weekday - 1 + $0) % 7 == 0 || (weekday - 1 + $0) % 7 == 6 },
                            overrides: [:], details: [:])
        snapshot.details?[today + 1] = .init(customIsOffDay: true, comment: String(localized: "widget.preview.comment"))
        snapshot.overrides[today + 1] = .init(isOffDay: true)
        snapshot.overrides[today + 2] = .init(isOffDay: true, name: String(localized: "widget.preview.holiday"))
        snapshot.details?[today + 2] = .init(publicIsOffDay: true)
        return snapshot
    }
}
