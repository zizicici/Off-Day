import Foundation

/// Persisted WidgetKit identifiers. Keep raw values stable across view/type refactors.
enum WidgetKind: String, CaseIterable {
    case lockScreen = "LockScreenWidget"
    case lockScreenThreeDays = "LockScreenThreeDayWidget"
    case today = "TodayWidget"
    case tomorrow = "TomorrowWidget"
    case month = "MonthCalendarWidget"
    case twoWeeks = "TwoWeekCalendarWidget"
    case threeDays = "ThreeDayCalendarWidget"
    case countdown = "CalendarCountdownWidget"

    static let summaryKinds: [Self] = [.lockScreen, .today, .tomorrow]
    static let detailedKinds: [Self] = [.month, .twoWeeks, .threeDays, .countdown, .lockScreenThreeDays]
}
