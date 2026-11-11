import WidgetKit

struct PeriodCalendarTimelineProvider: TimelineProvider {
    var surface: WidgetCalendarSurface

    func placeholder(in context: Context) -> WidgetPeriodEntry {
        .init(date: Date(), surface: surface, snapshot: .monthPreview, calendar: WidgetCalendarTimeline.calendar())
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetPeriodEntry) -> Void) {
        completion(.init(date: Date(), surface: surface, snapshot: context.isPreview ? .monthPreview : WidgetCalendarStore.load(),
                         calendar: WidgetCalendarTimeline.calendar()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetPeriodEntry>) -> Void) {
        let entries = WidgetPeriodTimeline.entries(surface: surface, snapshot: WidgetCalendarStore.load(), from: Date(),
                                                  calendar: WidgetCalendarTimeline.calendar())
        completion(Timeline(entries: entries, policy: .after(entries[1].date)))
    }
}

@available(iOS 17.0, *)
struct PeriodCalendarIntentTimelineProvider<Configuration: WidgetCalendarConfiguration>: AppIntentTimelineProvider {
    var surface: WidgetCalendarSurface

    func placeholder(in context: Context) -> WidgetPeriodEntry {
        .init(date: Date(), surface: surface, snapshot: .monthPreview, calendar: WidgetCalendarTimeline.calendar())
    }

    func snapshot(for configuration: Configuration, in context: Context) async -> WidgetPeriodEntry {
        .init(date: Date(), surface: surface, snapshot: context.isPreview ? .monthPreview : WidgetCalendarStore.load(),
              calendar: WidgetCalendarTimeline.calendar(), palette: configuration.palette, coloredPatterns: configuration.coloredPatterns,
              showsTodayIndicator: configuration.showsTodayIndicator)
    }

    func timeline(for configuration: Configuration, in context: Context) async -> Timeline<WidgetPeriodEntry> {
        let entries = WidgetPeriodTimeline.entries(surface: surface, snapshot: WidgetCalendarStore.load(), from: Date(),
            calendar: WidgetCalendarTimeline.calendar(), palette: configuration.palette, coloredPatterns: configuration.coloredPatterns,
            showsTodayIndicator: configuration.showsTodayIndicator)
        return Timeline(entries: entries, policy: .after(entries[1].date))
    }
}
