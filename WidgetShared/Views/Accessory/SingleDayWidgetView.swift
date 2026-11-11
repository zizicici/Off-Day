import SwiftUI
import WidgetKit

struct SingleDayWidgetView: View {
    var title: LocalizedStringKey
    var day: WidgetCalendarDay?

    var body: some View {
        WidgetAccessoryContainer {
            ZStack {
                AccessoryWidgetBackground()
                SingleDayWidgetContent(title: title, day: day)
            }
        }
    }
}

/// A circular widget has room for one clear answer, without holiday details.
struct SingleDayWidgetContent: View {
    var title: LocalizedStringKey
    var day: WidgetCalendarDay?

    var body: some View {
        GeometryReader { geometry in
            // An inscribed square keeps every text corner inside the circular background.
            let contentSide = min(geometry.size.width, geometry.size.height) * 0.7
            ViewThatFits(in: .vertical) {
                labels(titleSize: 10, statusSize: 16, spacing: 3)
                labels(titleSize: 9, statusSize: 14, spacing: 2)
            }
            .frame(width: contentSide, height: contentSide)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .accessibilityElement(children: .combine)
    }

    private func labels(titleSize: CGFloat, statusSize: CGFloat, spacing: CGFloat) -> some View {
        VStack(spacing: spacing) {
            Text(title)
                .font(.system(size: titleSize, weight: .medium))
                .foregroundStyle(.secondary)
                .minimumScaleFactor(0.75)
                .allowsTightening(true)
            if let day {
                Text(LocalizedStringKey(day.isOffDay ? "widget.offDay" : "widget.workDay"))
                    .font(.system(size: statusSize, weight: .semibold))
                    .minimumScaleFactor(0.75)
                    .allowsTightening(true)
            } else {
                Text("widget.openApp.short")
                    .font(.system(size: 11, weight: .semibold))
                    .minimumScaleFactor(0.75)
            }
        }
        .lineLimit(1)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
    }
}
