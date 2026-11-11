import WidgetKit

@available(iOS 17.0, *)
struct CalendarCountdownIntentTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> WidgetCountdownEntry {
        .init(date: Date(), snapshot: .monthPreview, calendar: WidgetCalendarTimeline.calendar())
    }

    func snapshot(for configuration: WidgetCountdownConfigurationIntent, in context: Context) async -> WidgetCountdownEntry {
        .init(date: Date(), snapshot: context.isPreview ? .monthPreview : WidgetCalendarStore.load(),
              calendar: WidgetCalendarTimeline.calendar(), style: configuration.style, target: configuration.target)
    }

    func timeline(for configuration: WidgetCountdownConfigurationIntent, in context: Context) async -> Timeline<WidgetCountdownEntry> {
        let entries = WidgetCountdownTimeline.entries(snapshot: WidgetCalendarStore.load(), from: Date(),
                                                      calendar: WidgetCalendarTimeline.calendar(), style: configuration.style, target: configuration.target)
        return Timeline(entries: entries, policy: .after(entries[1].date))
    }
}
