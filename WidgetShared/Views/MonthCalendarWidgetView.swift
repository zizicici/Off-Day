import SwiftUI
import WidgetKit

struct MonthCalendarWidgetView: View {
    var entry: WidgetMonthEntry

    var body: some View {
        WidgetCalendarContainer(surface: .month, display: entry.display, interaction: entry.interaction,
                                selectedDay: entry.selectedDay, isReady: entry.days.contains { $0.value != nil },
                                palette: entry.palette, coloredPatterns: entry.coloredPatterns) { metrics in
            let cellSize = metrics.gridCellSize(rows: entry.rowCount, headerHeight: 60)
            VStack(spacing: CalendarDayAppearance.spacing) {
                WidgetMonthCalendarHeader(entry: entry, cellWidth: cellSize.width)
                WidgetCalendarWeekdayHeader(firstWeekday: entry.firstWeekday, columnWidth: cellSize.width)
                    .frame(height: 20)
                WidgetCalendarDayGrid(days: entry.days, display: entry.display, surface: .month,
                    metrics: metrics, cellSize: cellSize, leadingEmptyCount: entry.leadingEmptyCount,
                    showsTodayIndicator: entry.showsTodayIndicator)
            }
        }
    }
}

private struct WidgetMonthCalendarHeader: View {
    @Environment(\.locale) private var locale
    @Environment(\.widgetCalendarColors) private var colors
    var entry: WidgetMonthEntry
    var cellWidth: CGFloat

    var body: some View {
        // Title spans columns 1–5. The two native buttons share columns 6 and 7 with the dates.
        HStack(spacing: CalendarDayAppearance.spacing) {
            Text(entry.monthDate, format: .dateTime.year().month(.wide).widgetGregorian(locale: locale))
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(colors.text)
                .lineLimit(1).minimumScaleFactor(0.65)
                .padding(.leading, 8)
                .frame(width: cellWidth * 5 + CalendarDayAppearance.spacing * 4, alignment: .leading)
            monthButton(target: entry.previousMonthStart, previous: true, width: cellWidth)
            monthButton(target: entry.nextMonthStart, previous: false, width: cellWidth)
        }
        .frame(height: 32)
    }

    @ViewBuilder
    private func monthButton(target: Int?, previous: Bool, width: CGFloat) -> some View {
        if #available(iOS 17.0, *) {
            Button(intent: ShowWidgetCalendarMonthIntent(monthStartDay: target ?? entry.monthStartDay)) {
                Image(systemName: previous ? "chevron.left" : "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(colors.text)
                    .frame(width: width, height: 32)
            }
            .buttonStyle(.plain).disabled(target == nil)
            .accessibilityLabel(Text(LocalizedStringKey(previous ? "widget.month.previous" : "widget.month.next")))
        } else {
            Color.clear.frame(width: width, height: 32)
        }
    }
}
