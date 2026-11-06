import SwiftUI
import WidgetKit

struct TodayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TodayWidget", provider: LockScreenTimelineProvider()) { entry in
            SingleDayWidgetView(title: "widget.today", day: entry.today)
        }
        .configurationDisplayName("widget.today")
        .description("widget.today.description")
        .supportedFamilies([.accessoryCircular])
        .contentMarginsDisabled()
    }
}

struct TomorrowWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TomorrowWidget", provider: LockScreenTimelineProvider()) { entry in
            SingleDayWidgetView(title: "widget.tomorrow", day: entry.tomorrow)
        }
        .configurationDisplayName("widget.tomorrow")
        .description("widget.tomorrow.description")
        .supportedFamilies([.accessoryCircular])
        .contentMarginsDisabled()
    }
}

@available(iOS 17.0, *)
#Preview(as: .accessoryCircular) {
    TodayWidget()
} timeline: {
    WidgetCalendarEntry(date: Date(), today: .init(isOffDay: true), tomorrow: .init(isOffDay: false))
    WidgetCalendarEntry(date: Date(), today: .init(isOffDay: false), tomorrow: .init(isOffDay: true))
    WidgetCalendarEntry(date: Date(), today: nil, tomorrow: nil)
}

@available(iOS 17.0, *)
#Preview(as: .accessoryCircular) {
    TomorrowWidget()
} timeline: {
    WidgetCalendarEntry(date: Date(), today: .init(isOffDay: false), tomorrow: .init(isOffDay: true))
    WidgetCalendarEntry(date: Date(), today: .init(isOffDay: true), tomorrow: .init(isOffDay: false))
    WidgetCalendarEntry(date: Date(), today: nil, tomorrow: nil)
}
