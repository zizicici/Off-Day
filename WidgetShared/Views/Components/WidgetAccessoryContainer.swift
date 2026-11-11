import SwiftUI
import WidgetKit

/// Accessory widgets let the system supply their background in every rendering mode.
struct WidgetAccessoryContainer<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        if #available(iOS 17.0, *) {
            content().containerBackground(for: .widget) { Color.clear }
        } else {
            content()
        }
    }
}
