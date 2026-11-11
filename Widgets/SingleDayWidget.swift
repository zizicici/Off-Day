import SwiftUI
import WidgetKit

struct TodayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetKind.today.rawValue, provider: LockScreenTimelineProvider()) { entry in
            SingleDayWidgetView(title: "widget.today", day: entry.today)
        }
        .calendarPresentation(for: .today)
    }
}

struct TomorrowWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetKind.tomorrow.rawValue, provider: LockScreenTimelineProvider()) { entry in
            SingleDayWidgetView(title: "widget.tomorrow", day: entry.tomorrow)
        }
        .calendarPresentation(for: .tomorrow)
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
