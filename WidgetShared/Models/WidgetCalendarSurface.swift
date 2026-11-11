import AppIntents
import Foundation

enum WidgetCalendarSurface: String, Codable, CaseIterable {
    case month, twoWeeks, threeDays
}

@available(iOS 17.0, *)
extension WidgetCalendarSurface: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "widget.calendar.type"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .month: "widget.month.title", .twoWeeks: "widget.twoWeeks.title", .threeDays: "widget.threeDays.title"
    ]
}
