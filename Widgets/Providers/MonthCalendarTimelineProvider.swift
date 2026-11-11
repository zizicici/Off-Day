import WidgetKit

struct MonthCalendarTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetMonthEntry {
        .init(date: Date(), snapshot: .monthPreview, calendar: WidgetCalendarTimeline.calendar())
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetMonthEntry) -> Void) {
        completion(.init(date: Date(), snapshot: context.isPreview ? .monthPreview : WidgetCalendarStore.load(),
                         calendar: WidgetCalendarTimeline.calendar()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetMonthEntry>) -> Void) {
        let entries = WidgetMonthTimeline.entries(snapshot: WidgetCalendarStore.load(), from: Date(),
                                                 calendar: WidgetCalendarTimeline.calendar())
        completion(Timeline(entries: entries, policy: .after(entries[1].date)))
    }
}

@available(iOS 17.0, *)
struct MonthCalendarIntentTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> WidgetMonthEntry {
        .init(date: Date(), snapshot: .monthPreview, calendar: WidgetCalendarTimeline.calendar())
    }

    func snapshot(for configuration: MonthCalendarConfigurationIntent, in context: Context) async -> WidgetMonthEntry {
        .init(date: Date(), snapshot: context.isPreview ? .monthPreview : WidgetCalendarStore.load(),
              calendar: WidgetCalendarTimeline.calendar(), palette: configuration.palette, coloredPatterns: configuration.coloredPatterns,
              showsTodayIndicator: configuration.showsTodayIndicator)
    }

    func timeline(for configuration: MonthCalendarConfigurationIntent, in context: Context) async -> Timeline<WidgetMonthEntry> {
        let entries = WidgetMonthTimeline.entries(snapshot: WidgetCalendarStore.load(), from: Date(),
            calendar: WidgetCalendarTimeline.calendar(), palette: configuration.palette, coloredPatterns: configuration.coloredPatterns,
            showsTodayIndicator: configuration.showsTodayIndicator)
        return Timeline(entries: entries, policy: .after(entries[1].date))
    }
}
