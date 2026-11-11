import SwiftUI
import WidgetKit

@available(iOS 17.0, *)
struct CalendarCountdownWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: WidgetKind.countdown.rawValue, intent: WidgetCountdownConfigurationIntent.self,
                               provider: CalendarCountdownIntentTimelineProvider()) { entry in
            WidgetCountdownView(entry: entry)
        }
        .calendarPresentation(for: .countdown)
    }
}

@available(iOS 17.0, *)
#Preview(as: .systemSmall) {
    CalendarCountdownWidget()
} timeline: {
    WidgetCountdownEntry(date: Date(), snapshot: .monthPreview, calendar: WidgetCalendarTimeline.calendar())
}
