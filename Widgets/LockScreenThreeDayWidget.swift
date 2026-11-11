import SwiftUI
import WidgetKit

struct LockScreenThreeDayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetKind.lockScreenThreeDays.rawValue, provider: PeriodCalendarTimelineProvider(surface: .threeDays)) { entry in
            LockScreenThreeDayWidgetView(entry: entry)
        }
        .calendarPresentation(for: .lockScreenThreeDays)
    }
}

@available(iOS 17.0, *)
#Preview(as: .accessoryRectangular) {
    LockScreenThreeDayWidget()
} timeline: {
    WidgetPeriodEntry(date: Date(), surface: .threeDays, snapshot: .monthPreview, calendar: WidgetCalendarTimeline.calendar())
    WidgetPeriodEntry(date: Date(), surface: .threeDays, snapshot: nil, calendar: WidgetCalendarTimeline.calendar())
}
