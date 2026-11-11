import AppIntents
import Foundation
import GRDB
import ZCCalendar

// iOS 17–25 routes these intents to the app via this conformance. iOS 26 uses
// supportedModes; iOS 27 additionally specifies allowedExecutionTargets = .main.
// Keeping the conformances in the app target avoids linking app-only APIs into Widgets.
@available(iOS 17.0, *)
extension SelectWidgetCalendarDayIntent: ForegroundContinuableIntent {}
@available(iOS 17.0, *)
extension SetWidgetCalendarDayMarkIntent: ForegroundContinuableIntent {}
@available(iOS 17.0, *)
extension ShowWidgetCalendarMonthIntent: ForegroundContinuableIntent {}

enum WidgetCalendarMonthStore {
    private static let key = "widget.month.displayedMonth"

    static var current: Int? {
        get {
            let value = UserDefaults.standard.integer(forKey: key)
            return WidgetCalendarMonthNavigation.isValid(value) ? value : nil
        }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }
}

enum WidgetCalendarInteractionStore {
    private static let key = "widget.month.interaction"

    static var current: WidgetCalendarInteraction? {
        get {
            guard let data = UserDefaults.standard.data(forKey: key),
                  let value = try? JSONDecoder().decode(WidgetCalendarInteraction.self, from: data),
                  value.expiresAt > Date() else { return nil }
            return value
        }
        set {
            UserDefaults.standard.set(newValue.flatMap { try? JSONEncoder().encode($0) }, forKey: key)
        }
    }
}

@available(iOS 17.0, *)
@MainActor
enum WidgetCalendarIntentHandler {
    static func showMonth(monthStartDay: Int) throws {
        guard WidgetCalendarMonthNavigation.isValid(monthStartDay) else { throw WidgetCalendarIntentError.invalidDay }
        let current = WidgetMonthEntry(date: Date(), snapshot: nil, calendar: WidgetCalendarTimeline.calendar()).monthStartDay
        // Returning to this month resumes automatic rollover on future local midnights.
        WidgetCalendarMonthStore.current = monthStartDay == current ? nil : monthStartDay
        WidgetCalendarInteractionStore.current = nil
        guard WidgetCalendarPublisher.shared.publishNow() else { throw WidgetCalendarIntentError.publicationFailed }
    }

    static func select(dayIndex: Int, surface: WidgetCalendarSurface = .month) throws {
        guard dayIndex == 0 || valid(dayIndex) else { throw WidgetCalendarIntentError.invalidDay }
        WidgetCalendarInteractionStore.current = dayIndex == 0 ? nil : .init(selectedDay: dayIndex, expiresAt: Date().addingTimeInterval(300), surface: surface)
        guard WidgetCalendarPublisher.shared.publishNow() else { throw WidgetCalendarIntentError.publicationFailed }
    }

    static func setMark(_ mark: WidgetDayMark, dayIndex: Int, surface: WidgetCalendarSurface = .month) async throws {
        try await setMark(mark, dayIndex: dayIndex, surface: surface,
            publishSnapshot: { WidgetCalendarPublisher.shared.publishNow() },
            updateNotifications: { await NotificationManager.shared.updateNotifications() })
    }

    static func setMark(_ mark: WidgetDayMark, dayIndex: Int, surface: WidgetCalendarSurface = .month,
                        publishSnapshot: () -> Bool, updateNotifications: () async -> Void) async throws {
        guard valid(dayIndex) else { throw WidgetCalendarIntentError.invalidDay }
        do {
            let type: DayType? = mark == .automatic ? nil : (mark == .off ? .offDay : .workDay)
            try AppDatabase.shared.setCustomDay(type, at: dayIndex)
            WidgetCalendarInteractionStore.current = nil
            // Notification scheduling belongs to the committed record, independently of the widget cache.
            await updateNotifications()
            guard publishSnapshot() else { throw WidgetCalendarIntentError.publicationFailed }
        } catch {
            WidgetCalendarInteractionStore.current = .init(selectedDay: dayIndex, expiresAt: Date().addingTimeInterval(300), error: true, surface: surface)
            // Publish a visible failure if possible; a committed database write is safe to retry.
            _ = publishSnapshot()
            throw error
        }
    }

    private static func valid(_ index: Int) -> Bool {
        (GregorianDay(year: 1, month: .jan, day: 1).julianDay...GregorianDay(year: 9999, month: .dec, day: 31).julianDay).contains(index)
    }
}

extension AppDatabase {
    /// An explicit assignment is idempotent, including retries after snapshot publication fails.
    /// One transaction prevents the read/insert race and clears duplicate marks from old backups.
    func setCustomDay(_ type: DayType?, at index: Int) throws {
        guard let dbWriter else { throw CocoaError(.fileWriteUnknown) }
        try dbWriter.write { db in
            let request = CustomDay.filter(CustomDay.Columns.dayIndex == index)
            guard let type else {
                try request.deleteAll(db)
                return
            }
            if var day = try request.order(CustomDay.Columns.id).fetchOne(db) {
                if day.dayType != type {
                    day.dayType = type
                    try day.updateWithTimestamp(db)
                }
                try request.filter(CustomDay.Columns.id != day.id!).deleteAll(db)
            } else {
                var day = CustomDay(dayIndex: Int64(index), dayType: type)
                try day.save(db)
            }
        }
        NotificationCenter.default.post(name: .DatabaseUpdated, object: nil)
    }
}
