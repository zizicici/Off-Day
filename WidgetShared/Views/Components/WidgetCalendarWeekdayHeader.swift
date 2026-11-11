import SwiftUI

struct WidgetCalendarWeekdayHeader: View {
    @Environment(\.locale) private var locale
    @Environment(\.widgetCalendarColors) private var colors
    var firstWeekday: Int
    var columnWidth: CGFloat
    var columnCount = 7
    var abbreviated = false
    var cellHeight: CGFloat?
    var presentation: WidgetCalendarGridPresentation = .home

    var body: some View {
        let labels = WidgetGregorianDateFormat.weekdayLabels(firstWeekday: firstWeekday, locale: locale, abbreviated: abbreviated)
        HStack(spacing: CalendarDayAppearance.spacing) {
            ForEach(0..<columnCount, id: \.self) { index in
                if presentation == .accessory {
                    label(labels[index])
                        .foregroundStyle(.secondary)
                        .lineLimit(1).minimumScaleFactor(0.7)
                        .frame(width: columnWidth, height: cellHeight)
                } else {
                    label(labels[index])
                        .foregroundStyle(colors.text.opacity(colors.usesSystemRendering ? 0.85 : 0.6))
                        .frame(width: columnWidth, height: cellHeight)
                }
            }
        }
    }

    private func label(_ text: String) -> some View {
        Text(verbatim: text).font(.system(size: 9, weight: .medium))
    }
}
