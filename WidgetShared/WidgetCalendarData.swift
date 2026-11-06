import Foundation
import WidgetKit
import ZCCalendar

struct WidgetCalendarDay: Codable, Equatable {
    var isOffDay: Bool
    var name: String?
}

/// A full repeating cycle plus explicit overrides keeps working without reopening the app.
struct WidgetCalendarSnapshot: Codable, Equatable {
    var version = 1
    var cycleStartDay: Int
    var cycle: [Bool]
    var overrides: [Int: WidgetCalendarDay]

    var isValid: Bool { version == 1 && !cycle.isEmpty }

    func day(at julianDay: Int) -> WidgetCalendarDay? {
        guard isValid else { return nil }
        if let override = overrides[julianDay] {
            return override
        }
        let offset = ((julianDay - cycleStartDay) % cycle.count + cycle.count) % cycle.count
        return WidgetCalendarDay(isOffDay: cycle[offset])
    }
}

enum WidgetCalendarStore {
    static let appGroup = "group.com.zizicici.zzz"
    // Keep this identifier stable so installed widgets survive type renames.
    static let kind = "LockScreenWidget"

    static func fileURL() throws -> URL {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            throw CocoaError(.fileNoSuchFile)
        }
        return container.appendingPathComponent("widget-calendar.json")
    }

    static func load(from url: URL? = nil) -> WidgetCalendarSnapshot? {
        guard let url = try? url ?? fileURL(),
              let data = try? Data(contentsOf: url),
              let snapshot = try? JSONDecoder().decode(WidgetCalendarSnapshot.self, from: data),
              snapshot.isValid else { return nil }
        return snapshot
    }

    @discardableResult
    static func save(_ snapshot: WidgetCalendarSnapshot, to url: URL? = nil) throws -> Bool {
        let url = try url ?? fileURL()
        guard snapshot != load(from: url) else { return false }
        let data = try JSONEncoder().encode(snapshot)
        // The Lock Screen can read the snapshot after the device's first unlock.
        try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        return true
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

enum WidgetCalendarTimeline {
    static func calendar(timeZone: TimeZone = .current) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    static func entries(snapshot: WidgetCalendarSnapshot?, from now: Date, calendar: Calendar) -> [WidgetCalendarEntry] {
        let start = calendar.startOfDay(for: now)
        // Supply future midnights as a fallback if the system delays a reload.
        let dates = [now] + (1...7).compactMap { offset -> Date? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            // A DST jump can make today's start 01:00; later days still need their own midnight.
            return calendar.startOfDay(for: date)
        }
        return dates.map { WidgetCalendarEntry(date: $0, snapshot: snapshot, calendar: calendar) }
    }
}
