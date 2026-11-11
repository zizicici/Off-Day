import AppIntents
import Foundation

@available(iOS 17.0, *)
enum WidgetDayMark: String, AppEnum {
    case off, work, automatic

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "widget.month.mark"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .off: "widget.offDay", .work: "widget.workDay", .automatic: "dayType.none"
    ]
}

/// Both intents are described in both targets, but only the main app implements their actions.
/// Never fall back to writing from the extension if the system routes an intent incorrectly.
@available(iOS 17.0, *)
struct SelectWidgetCalendarDayIntent: AppIntent {
    static var title: LocalizedStringResource = "widget.month.select"
    static var isDiscoverable: Bool = false
    static var openAppWhenRun: Bool = false

    @available(iOS 26.0, *)
    static var supportedModes: IntentModes { [.background, .foreground(.dynamic)] }

    @available(iOS 27.0, *)
    static var allowedExecutionTargets: IntentExecutionTargets { .main }

    @Parameter(title: "widget.month.date") var dayIndex: Int
    @Parameter(title: "widget.calendar.type", default: .month) var surface: WidgetCalendarSurface

    init() {}
    init(dayIndex: Int, surface: WidgetCalendarSurface = .month) {
        self.dayIndex = dayIndex
        self.surface = surface
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        #if OFF_DAY_APP
        try WidgetCalendarIntentHandler.select(dayIndex: dayIndex, surface: surface)
        #else
        try WidgetCalendarIntentError.requireMainApp()
        #endif
        return .result()
    }
}

@available(iOS 17.0, *)
struct SetWidgetCalendarDayMarkIntent: AppIntent {
    static var title: LocalizedStringResource = "widget.month.mark"
    static var isDiscoverable: Bool = false
    static var openAppWhenRun: Bool = false

    @available(iOS 26.0, *)
    static var supportedModes: IntentModes { [.background, .foreground(.dynamic)] }

    @available(iOS 27.0, *)
    static var allowedExecutionTargets: IntentExecutionTargets { .main }

    @Parameter(title: "widget.month.date") var dayIndex: Int
    @Parameter(title: "widget.month.mark") var mark: WidgetDayMark
    @Parameter(title: "widget.calendar.type", default: .month) var surface: WidgetCalendarSurface

    init() {}
    init(dayIndex: Int, mark: WidgetDayMark, surface: WidgetCalendarSurface = .month) {
        self.dayIndex = dayIndex
        self.mark = mark
        self.surface = surface
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        #if OFF_DAY_APP
        try await WidgetCalendarIntentHandler.setMark(mark, dayIndex: dayIndex, surface: surface)
        #else
        try WidgetCalendarIntentError.requireMainApp()
        #endif
        return .result()
    }
}

enum WidgetCalendarIntentError: Error, LocalizedError, Equatable {
    case mainAppRequired, publicationFailed, invalidDay

    var errorDescription: String? { String(localized: "widget.month.updateFailed") }

    static func requireMainApp() throws { throw Self.mainAppRequired }
}

@available(iOS 17.0, *)
struct ShowWidgetCalendarMonthIntent: AppIntent {
    static var title: LocalizedStringResource = "widget.month.show"
    static var isDiscoverable: Bool = false
    static var openAppWhenRun: Bool = false

    @available(iOS 26.0, *)
    static var supportedModes: IntentModes { [.background, .foreground(.dynamic)] }

    @available(iOS 27.0, *)
    static var allowedExecutionTargets: IntentExecutionTargets { .main }

    @Parameter(title: "widget.month.date") var monthStartDay: Int

    init() {}
    init(monthStartDay: Int) { self.monthStartDay = monthStartDay }

    @MainActor
    func perform() async throws -> some IntentResult {
        #if OFF_DAY_APP
        try WidgetCalendarIntentHandler.showMonth(monthStartDay: monthStartDay)
        #else
        try WidgetCalendarIntentError.requireMainApp()
        #endif
        return .result()
    }
}
