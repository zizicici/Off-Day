import SwiftUI
import WidgetKit

struct LockScreenTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetCalendarEntry {
        WidgetCalendarEntry(date: Date(), today: .init(isOffDay: false), tomorrow: .init(isOffDay: true))
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetCalendarEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
        } else {
            completion(WidgetCalendarEntry(date: Date(), snapshot: WidgetCalendarStore.load(), calendar: WidgetCalendarTimeline.calendar()))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetCalendarEntry>) -> Void) {
        let now = Date()
        let calendar = WidgetCalendarTimeline.calendar()
        let entries = WidgetCalendarTimeline.entries(snapshot: WidgetCalendarStore.load(), from: now, calendar: calendar)
        completion(Timeline(entries: entries, policy: .after(entries[1].date)))
    }
}

struct LockScreenWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetCalendarStore.kind, provider: LockScreenTimelineProvider()) { entry in
            LockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("widget.title")
        .description("widget.description")
        .supportedFamilies([.accessoryRectangular])
        .contentMarginsDisabled()
    }
}

@available(iOS 17.0, *)
#Preview(as: .accessoryRectangular) {
    LockScreenWidget()
} timeline: {
    WidgetCalendarEntry(date: Date(), today: .init(isOffDay: false), tomorrow: .init(isOffDay: true))
    WidgetCalendarEntry(date: Date(), today: .init(isOffDay: true), tomorrow: .init(isOffDay: false))
    WidgetCalendarEntry(date: Date(), today: .init(isOffDay: true, name: "春节"), tomorrow: .init(isOffDay: true, name: "春节"))
    WidgetCalendarEntry(date: Date(), today: .init(isOffDay: false, name: "国庆节调休上班"), tomorrow: .init(isOffDay: true, name: "国庆节"))
    WidgetCalendarEntry(date: Date(), today: nil, tomorrow: nil)
}
