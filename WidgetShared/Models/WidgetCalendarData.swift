import Foundation
import WidgetKit
import ZCCalendar

struct WidgetCalendarDay: Codable, Equatable {
    var isOffDay: Bool
    var name: String?
}

struct WidgetCalendarDayDetail: Codable, Equatable {
    var publicIsOffDay: Bool?
    var customIsOffDay: Bool?
    var comment: String?
    var commentAvailable: Bool?

    var hasComment: Bool { comment != nil || commentAvailable == true }
}

struct WidgetCalendarDisplay: Codable, Equatable {
    /// Calendar weekday numbering: Sunday = 1. Nil follows the device's locale.
    var firstWeekday: Int?
    var blueWeekends = false
    var paperHolidayWorkdays = false
    var alternativeDays: [Int: String] = [:]
}

struct WidgetCalendarInteraction: Codable, Equatable {
    var selectedDay: Int
    var expiresAt: Date
    var error: Bool = false
    var surface: WidgetCalendarSurface?
}

extension WidgetCalendarInteraction {
    func day(in days: [WidgetCalendarDayItem], surface requested: WidgetCalendarSurface, at date: Date) -> WidgetCalendarDayItem? {
        guard (surface ?? .month) == requested, expiresAt > date else { return nil }
        return days.first { $0.id == selectedDay }
    }
}

/// A full repeating cycle plus explicit overrides keeps working without reopening the app.
struct WidgetCalendarSnapshot: Codable, Equatable {
    var version = 1
    var cycleStartDay: Int
    var cycle: [Bool]
    var overrides: [Int: WidgetCalendarDay]
    // Optional additions preserve the existing Lock Screen snapshot format.
    var details: [Int: WidgetCalendarDayDetail]?
    var display: WidgetCalendarDisplay?
    var interaction: WidgetCalendarInteraction?
    /// Nil follows the current month; a first-of-month Julian day preserves a browsed month.
    var displayedMonthStart: Int?

    var isValid: Bool { version == 1 && !cycle.isEmpty }

    var summary: Self {
        Self(version: version, cycleStartDay: cycleStartDay, cycle: cycle, overrides: overrides)
    }

    func baseIsOffDay(at julianDay: Int) -> Bool? {
        guard isValid else { return nil }
        let offset = ((julianDay - cycleStartDay) % cycle.count + cycle.count) % cycle.count
        return cycle[offset]
    }

    func day(at julianDay: Int) -> WidgetCalendarDay? {
        guard isValid else { return nil }
        if let override = overrides[julianDay] {
            return override
        }
        return baseIsOffDay(at: julianDay).map { WidgetCalendarDay(isOffDay: $0) }
    }
}

struct WidgetCalendarEntry: TimelineEntry {
    var date: Date
    var today: WidgetCalendarDay?
    var tomorrow: WidgetCalendarDay?

    init(date: Date, snapshot: WidgetCalendarSnapshot?, calendar: Calendar) {
        self.date = date
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let day = GregorianDay(year: components.year!, month: Month(rawValue: components.month!)!, day: components.day!)
        today = snapshot?.day(at: day.julianDay)
        tomorrow = snapshot?.day(at: day.julianDay + 1)
    }

    init(date: Date, today: WidgetCalendarDay?, tomorrow: WidgetCalendarDay?) {
        self.date = date
        self.today = today
        self.tomorrow = tomorrow
    }
}
