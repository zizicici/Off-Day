import AppIntents

@available(iOS 17.0, *)
extension WidgetCountdownPalette: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "widget.countdown.palette"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .classic: "widget.calendar.palette.classic", .mono: "widget.calendar.palette.mono"
    ]
}

@available(iOS 17.0, *)
extension WidgetCountdownFont: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "widget.countdown.font"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .rounded: "widget.countdown.font.rounded", .standard: "widget.countdown.font.standard",
        .serif: "widget.countdown.font.serif", .monospaced: "widget.countdown.font.monospaced"
    ]
}

@available(iOS 17.0, *)
extension WidgetCountdownTarget: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "widget.countdown.target"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .publicHoliday: "widget.countdown.target.publicHoliday", .offDay: "widget.countdown.target.offDay"
    ]
}

@available(iOS 17.0, *)
struct WidgetCountdownConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "widget.countdown.customize"
    static var description = IntentDescription("widget.countdown.customize.description")

    @Parameter(title: "widget.countdown.target", default: .publicHoliday)
    var target: WidgetCountdownTarget

    @Parameter(title: "widget.countdown.palette", default: .classic)
    var palette: WidgetCountdownPalette

    @Parameter(title: "widget.countdown.font", default: .rounded)
    var font: WidgetCountdownFont

    static var parameterSummary: some ParameterSummary {
        Summary {
            \.$target
            \.$palette
            \.$font
        }
    }

    var style: WidgetCountdownStyle { .init(palette: palette, font: font) }

    init() {}

    init(target: WidgetCountdownTarget = .publicHoliday, palette: WidgetCountdownPalette, font: WidgetCountdownFont) {
        self.target = target
        self.palette = palette
        self.font = font
    }
}
