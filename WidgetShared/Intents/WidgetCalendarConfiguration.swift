import AppIntents

@available(iOS 17.0, *)
extension WidgetCalendarPalette: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "widget.calendar.palette"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .classic: "widget.calendar.palette.classic", .mono: "widget.calendar.palette.mono"
    ]
}

@available(iOS 17.0, *)
protocol WidgetCalendarConfiguration: WidgetConfigurationIntent {
    var palette: WidgetCalendarPalette { get }
    var coloredPatterns: Bool { get }
    var showsTodayIndicator: Bool { get }
}

@available(iOS 17.0, *)
struct MonthCalendarConfigurationIntent: WidgetCalendarConfiguration {
    static var title: LocalizedStringResource = "widget.month.title"

    @Parameter(title: "widget.calendar.palette", default: .classic)
    var palette: WidgetCalendarPalette

    @Parameter(title: "calendar.appearance.coloredPatterns", default: false)
    var coloredPatterns: Bool

    @Parameter(title: "widget.calendar.showTodayIndicator", default: true)
    var showsTodayIndicator: Bool

    static var parameterSummary: some ParameterSummary {
        When(\.$palette, .equalTo, WidgetCalendarPalette.classic) {
            Summary { \.$palette; \.$coloredPatterns; \.$showsTodayIndicator }
        } otherwise: {
            Summary { \.$palette; \.$showsTodayIndicator }
        }
    }

    init() {}
    init(palette: WidgetCalendarPalette, coloredPatterns: Bool = false, showsTodayIndicator: Bool = true) {
        self.palette = palette
        self.coloredPatterns = coloredPatterns
        self.showsTodayIndicator = showsTodayIndicator
    }
}

@available(iOS 17.0, *)
struct TwoWeekCalendarConfigurationIntent: WidgetCalendarConfiguration {
    static var title: LocalizedStringResource = "widget.twoWeeks.title"

    @Parameter(title: "widget.calendar.palette", default: .classic)
    var palette: WidgetCalendarPalette

    @Parameter(title: "calendar.appearance.coloredPatterns", default: false)
    var coloredPatterns: Bool

    @Parameter(title: "widget.calendar.showTodayIndicator", default: true)
    var showsTodayIndicator: Bool

    static var parameterSummary: some ParameterSummary {
        When(\.$palette, .equalTo, WidgetCalendarPalette.classic) {
            Summary { \.$palette; \.$coloredPatterns; \.$showsTodayIndicator }
        } otherwise: {
            Summary { \.$palette; \.$showsTodayIndicator }
        }
    }

    init() {}
    init(palette: WidgetCalendarPalette, coloredPatterns: Bool = false, showsTodayIndicator: Bool = true) {
        self.palette = palette
        self.coloredPatterns = coloredPatterns
        self.showsTodayIndicator = showsTodayIndicator
    }
}

@available(iOS 17.0, *)
struct ThreeDayCalendarConfigurationIntent: WidgetCalendarConfiguration {
    static var title: LocalizedStringResource = "widget.threeDays.title"
    var showsTodayIndicator: Bool { false }

    @Parameter(title: "widget.calendar.palette", default: .classic)
    var palette: WidgetCalendarPalette

    @Parameter(title: "calendar.appearance.coloredPatterns", default: false)
    var coloredPatterns: Bool

    static var parameterSummary: some ParameterSummary {
        When(\.$palette, .equalTo, WidgetCalendarPalette.classic) {
            Summary { \.$palette; \.$coloredPatterns }
        } otherwise: {
            Summary { \.$palette }
        }
    }

    init() {}
    init(palette: WidgetCalendarPalette, coloredPatterns: Bool = false) {
        self.palette = palette
        self.coloredPatterns = coloredPatterns
    }
}
