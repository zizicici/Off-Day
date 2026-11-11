import WidgetKit

struct LockScreenTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetCalendarEntry {
        WidgetCalendarEntry(date: Date(), today: .init(isOffDay: false), tomorrow: .init(isOffDay: true))
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetCalendarEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
        } else {
            completion(WidgetCalendarEntry(date: Date(), snapshot: WidgetCalendarStore.loadSummary(), calendar: WidgetCalendarTimeline.calendar()))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetCalendarEntry>) -> Void) {
        let now = Date()
        let calendar = WidgetCalendarTimeline.calendar()
        let entries = WidgetCalendarTimeline.entries(snapshot: WidgetCalendarStore.loadSummary(), from: now, calendar: calendar)
        completion(Timeline(entries: entries, policy: .after(entries[1].date)))
    }
}
