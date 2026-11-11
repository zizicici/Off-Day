import SwiftUI
import WidgetKit

struct LockScreenWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetKind.lockScreen.rawValue, provider: LockScreenTimelineProvider()) { entry in
            LockScreenWidgetView(entry: entry)
        }
        .calendarPresentation(for: .lockScreen)
    }
}

@available(iOS 17.0, *)
#Preview(as: .accessoryRectangular) {
    LockScreenWidget()
} timeline: {
    WidgetCalendarEntry(date: Date(), today: .init(isOffDay: false), tomorrow: .init(isOffDay: true))
    WidgetCalendarEntry(date: Date(), today: .init(isOffDay: true), tomorrow: .init(isOffDay: false))
    WidgetCalendarEntry(date: Date(), today: .init(isOffDay: true, name: "春节"), tomorrow: .init(isOffDay: true, name: "春节"))
    WidgetCalendarEntry(date: Date(), today: .init(isOffDay: false, name: "国庆节调休上班"), tomorrow: .init(isOffDay: true, name: "国庆节"))
    WidgetCalendarEntry(date: Date(), today: nil, tomorrow: nil)
}
