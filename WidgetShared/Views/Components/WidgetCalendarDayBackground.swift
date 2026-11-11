import SwiftUI

/// Retain the meaning of the app's green, blue, and red cells without relying on hue.
struct WidgetCalendarDayBackground: View {
    @Environment(\.widgetCalendarColors) private var colors
    var appearance: CalendarDayAppearance.Palette

    var body: some View {
        colors.background(for: appearance)
            .overlay {
                if colors.usesPatterns {
                    WidgetCalendarDayPattern(appearance: appearance)
                        .fill(colors.patternColor(for: appearance).opacity(colors.patternOpacity))
                }
            }
    }
}

/// A single vector path per cell, rather than a hierarchy of repeated icon views.
private struct WidgetCalendarDayPattern: Shape {
    var appearance: CalendarDayAppearance.Palette

    func path(in rect: CGRect) -> Path {
        Path(CalendarDayTexture(appearance: appearance).path(in: rect))
    }
}
