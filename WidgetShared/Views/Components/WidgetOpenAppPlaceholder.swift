import SwiftUI

struct WidgetOpenAppPlaceholder: View {
    enum Style { case home, accessory }
    var style: Style

    var body: some View {
        switch style {
        case .home:
            VStack(spacing: 6) {
                Text("widget.openApp.title").font(.headline)
                Text("widget.openApp.subtitle").font(.footnote)
            }
            .multilineTextAlignment(.center).foregroundStyle(.secondary)
        case .accessory:
            VStack(alignment: .leading, spacing: 4) {
                Text("widget.openApp.title").font(.subheadline.weight(.semibold))
                Text("widget.openApp.subtitle").font(.caption2).foregroundStyle(.secondary).lineLimit(2)
            }
        }
    }
}
