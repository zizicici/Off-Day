import SwiftUI
import UIKit

/// Full-color patterned calendars, including Mono, use custom text drawing. The enclosing
/// date button supplies accessibility, hit testing and the native pressed state.
struct WidgetCalendarInkText: View {
    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var scheme
    var text: String
    var font: UIFont
    var foreground: Color
    var backing: Color

    var body: some View {
        let traits = UITraitCollection(userInterfaceStyle: scheme == .dark ? .dark : .light)
        let foreground = UIColor(foreground).resolvedColor(with: traits).cgColor
        let backing = UIColor(backing).resolvedColor(with: traits).cgColor
        Canvas { context, size in
            let layout = CalendarInkTextLayout.resolve(text, font: font, size: size, locale: locale)
            context.withCGContext { cg in
                layout.draw(in: cg, size: size, foreground: foreground, backing: backing)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
