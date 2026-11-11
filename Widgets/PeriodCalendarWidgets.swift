import SwiftUI
import WidgetKit

@available(iOS 17.0, *)
struct TwoWeekCalendarWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: WidgetKind.twoWeeks.rawValue, intent: TwoWeekCalendarConfigurationIntent.self,
                               provider: PeriodCalendarIntentTimelineProvider<TwoWeekCalendarConfigurationIntent>(surface: .twoWeeks)) { entry in
            PeriodCalendarWidgetView(entry: entry)
        }
        .calendarPresentation(for: .twoWeeks)
    }
}

@available(iOS 17.0, *)
struct ThreeDayCalendarWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: WidgetKind.threeDays.rawValue, intent: ThreeDayCalendarConfigurationIntent.self,
                               provider: PeriodCalendarIntentTimelineProvider<ThreeDayCalendarConfigurationIntent>(surface: .threeDays)) { entry in
            PeriodCalendarWidgetView(entry: entry)
        }
        .calendarPresentation(for: .threeDays)
    }
}

struct LegacyTwoWeekCalendarWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetKind.twoWeeks.rawValue, provider: PeriodCalendarTimelineProvider(surface: .twoWeeks)) { entry in
            PeriodCalendarWidgetView(entry: entry)
        }
        .calendarPresentation(for: .twoWeeks)
    }
}

struct LegacyThreeDayCalendarWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetKind.threeDays.rawValue, provider: PeriodCalendarTimelineProvider(surface: .threeDays)) { entry in
            PeriodCalendarWidgetView(entry: entry)
        }
        .calendarPresentation(for: .threeDays)
    }
}

@available(iOS 17.0, *)
#Preview(as: .systemMedium) {
    TwoWeekCalendarWidget()
} timeline: {
    WidgetPeriodEntry(date: Date(), surface: .twoWeeks, snapshot: .monthPreview, calendar: WidgetCalendarTimeline.calendar())
}

@available(iOS 17.0, *)
#Preview(as: .systemSmall) {
    ThreeDayCalendarWidget()
} timeline: {
    WidgetPeriodEntry(date: Date(), surface: .threeDays, snapshot: .monthPreview, calendar: WidgetCalendarTimeline.calendar())
}
