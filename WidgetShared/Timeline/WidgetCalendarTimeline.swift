import Foundation

enum WidgetCalendarTimeline {
    static func calendar(timeZone: TimeZone = .current) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.locale = .current
        calendar.firstWeekday = Calendar.current.firstWeekday
        return calendar
    }

    static func dates(from now: Date, calendar: Calendar, interactionExpiry: Date? = nil) -> [Date] {
        let start = calendar.startOfDay(for: now)
        // Supply future midnights as a fallback if the system delays a reload.
        var dates = [now] + (1...7).compactMap { offset -> Date? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            // A DST jump can make today's start 01:00; later days still need their own midnight.
            return calendar.startOfDay(for: date)
        }
        if let expiry = interactionExpiry, expiry > now, let last = dates.last, expiry < last {
            dates.append(expiry)
            dates.sort()
        }
        return dates
    }

    static func entries(snapshot: WidgetCalendarSnapshot?, from now: Date, calendar: Calendar) -> [WidgetCalendarEntry] {
        dates(from: now, calendar: calendar).map { WidgetCalendarEntry(date: $0, snapshot: snapshot, calendar: calendar) }
    }
}

enum WidgetMonthTimeline {
    static func entries(snapshot: WidgetCalendarSnapshot?, from now: Date, calendar: Calendar,
                        palette: WidgetCalendarPalette = .classic, coloredPatterns: Bool = false,
                        showsTodayIndicator: Bool = true) -> [WidgetMonthEntry] {
        WidgetCalendarTimeline.dates(from: now, calendar: calendar, interactionExpiry: snapshot?.interaction?.expiresAt)
            .map { WidgetMonthEntry(date: $0, snapshot: snapshot, calendar: calendar,
                palette: palette, coloredPatterns: coloredPatterns, showsTodayIndicator: showsTodayIndicator) }
    }
}

enum WidgetPeriodTimeline {
    static func entries(surface: WidgetCalendarSurface, snapshot: WidgetCalendarSnapshot?, from now: Date, calendar: Calendar,
                        palette: WidgetCalendarPalette = .classic, coloredPatterns: Bool = false,
                        showsTodayIndicator: Bool = true) -> [WidgetPeriodEntry] {
        WidgetCalendarTimeline.dates(from: now, calendar: calendar, interactionExpiry: snapshot?.interaction?.expiresAt)
            .map { WidgetPeriodEntry(date: $0, surface: surface, snapshot: snapshot, calendar: calendar,
                palette: palette, coloredPatterns: coloredPatterns, showsTodayIndicator: showsTodayIndicator) }
    }
}

enum WidgetCountdownTimeline {
    static func entries(snapshot: WidgetCalendarSnapshot?, from now: Date, calendar: Calendar,
                        style: WidgetCountdownStyle = .init(), target: WidgetCountdownTarget = .publicHoliday) -> [WidgetCountdownEntry] {
        WidgetCalendarTimeline.dates(from: now, calendar: calendar).map {
            WidgetCountdownEntry(date: $0, snapshot: snapshot, calendar: calendar, style: style, target: target)
        }
    }
}
