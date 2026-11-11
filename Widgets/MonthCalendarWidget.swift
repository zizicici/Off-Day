import SwiftUI
import WidgetKit

@available(iOS 17.0, *)
struct MonthCalendarWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: WidgetKind.month.rawValue, intent: MonthCalendarConfigurationIntent.self,
                               provider: MonthCalendarIntentTimelineProvider()) { entry in
            MonthCalendarWidgetView(entry: entry)
        }
        .calendarPresentation(for: .month)
    }
}

// Preserve the existing iOS 16 presentation and kind; configuration begins on iOS 17.
struct LegacyMonthCalendarWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetKind.month.rawValue, provider: MonthCalendarTimelineProvider()) { entry in
            MonthCalendarWidgetView(entry: entry)
        }
        .calendarPresentation(for: .month)
    }
}

@available(iOS 17.0, *)
#Preview(as: .systemLarge) {
    MonthCalendarWidget()
} timeline: {
    WidgetMonthEntry(date: Date(), snapshot: .monthPreview, calendar: WidgetCalendarTimeline.calendar())
}
