import SwiftUI
import WidgetKit

struct WidgetCalendarContainer<Content: View>: View {
    @Environment(\.self) private var environment
    var palette: WidgetCalendarPalette
    var coloredPatterns: Bool
    var surface: WidgetCalendarSurface?
    var display: WidgetCalendarDisplay
    var interaction: WidgetCalendarInteraction?
    var selectedDay: WidgetCalendarDayItem?
    var isReady: Bool
    var background: Color
    var content: (WidgetCalendarLayoutMetrics) -> Content

    init(surface: WidgetCalendarSurface? = nil, display: WidgetCalendarDisplay = .init(), interaction: WidgetCalendarInteraction? = nil,
         selectedDay: WidgetCalendarDayItem? = nil, isReady: Bool, background: Color = Color("BackgroundColor"),
         palette: WidgetCalendarPalette = .classic, coloredPatterns: Bool = false,
         @ViewBuilder content: @escaping (WidgetCalendarLayoutMetrics) -> Content) {
        self.palette = palette
        self.coloredPatterns = coloredPatterns
        self.surface = surface
        self.display = display
        self.interaction = interaction
        self.selectedDay = selectedDay
        self.isReady = isReady
        self.background = background
        self.content = content
    }

    private var inset: CGFloat {
        if #available(iOS 17.0, *) {
            let margins = environment.widgetContentMargins
            return [16, margins.top, margins.leading, margins.bottom, margins.trailing].max() ?? 16
        }
        return 16
    }

    var body: some View {
        let colors = palette.colors(for: environment.colorScheme, renderingMode: environment.widgetRenderingMode, coloredPatterns: coloredPatterns)
        let resolvedBackground = colors.usesSystemRendering ? Color.clear : (palette == .classic ? background : colors.background)
        if #available(iOS 17.0, *) {
            container.environment(\.widgetCalendarColors, colors)
                .containerBackground(for: .widget) { resolvedBackground }
        } else {
            container.environment(\.widgetCalendarColors, colors).background(resolvedBackground)
        }
    }

    private var container: some View {
        GeometryReader { geometry in
            let metrics = WidgetCalendarLayoutMetrics(geometry: geometry, inset: inset)
            ZStack {
                if isReady {
                    content(metrics)
                        .frame(width: metrics.contentSize.width, height: metrics.contentSize.height)
                        .padding(inset)
                        // An opaque popover cannot cover template-rendered dates. Hide the
                        // underlying grid while editing so its glyphs cannot bleed through.
                        .opacity(environment.widgetRenderingMode != .fullColor && selectedDay != nil ? 0 : 1)
                } else {
                    WidgetOpenAppPlaceholder(style: .home)
                        .padding(inset)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                if #available(iOS 17.0, *), let selectedDay, let surface {
                    Button(intent: SelectWidgetCalendarDayIntent(dayIndex: 0, surface: surface)) {
                        Color.black.opacity(environment.widgetRenderingMode == .fullColor ? 0.18 : 0)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("widget.month.close"))
                    WidgetCalendarDetailView(day: selectedDay, display: display, surface: surface,
                                             hasError: interaction?.error == true)
                        .frame(maxWidth: WidgetCalendarDetailMetrics(surface: surface).preferredWidth(locale: environment.locale))
                        .padding(metrics.detailInset(for: surface))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        // SwiftUI's formatted Text also reads the calendar environment, even
        // when the supplied FormatStyle has an explicit calendar.
        .environment(\.calendar, WidgetCalendarTimeline.calendar())
    }
}
