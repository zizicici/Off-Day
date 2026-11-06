import SwiftUI
import WidgetKit

@main
struct WidgetsBundle: WidgetBundle {
    var body: some Widget {
        LockScreenWidget()
        TodayWidget()
        TomorrowWidget()
    }
}
