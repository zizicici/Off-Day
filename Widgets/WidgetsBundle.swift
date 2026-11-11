import SwiftUI
import WidgetKit

@main
enum WidgetsEntryPoint {
    static func main() {
        if #available(iOS 17.0, *) {
            ConfigurableWidgetsBundle.main()
        } else {
            WidgetsBundle.main()
        }
    }
}

@available(iOS 17.0, *)
struct ConfigurableWidgetsBundle: WidgetBundle {
    var body: some Widget {
        CalendarCountdownWidget()
        ThreeDayCalendarWidget()
        TwoWeekCalendarWidget()
        MonthCalendarWidget()
        LockScreenWidget()
        LockScreenThreeDayWidget()
        TodayWidget()
        TomorrowWidget()
    }
}

// WidgetBundleBuilder cannot branch between two configurations of the same kind.
// Choose the bundle at launch to retain all iOS 16 widgets without duplicate kinds.
struct WidgetsBundle: WidgetBundle {
    var body: some Widget {
        LegacyThreeDayCalendarWidget()
        LegacyTwoWeekCalendarWidget()
        LegacyMonthCalendarWidget()
        LockScreenWidget()
        LockScreenThreeDayWidget()
        TodayWidget()
        TomorrowWidget()
    }
}
