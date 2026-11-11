import SwiftUI
import WidgetKit

struct PeriodCalendarWidgetView: View {
    var entry: WidgetPeriodEntry

    var body: some View {
        WidgetCalendarContainer(surface: entry.surface, display: entry.display, interaction: entry.interaction,
                                selectedDay: entry.selectedDay, isReady: entry.days.contains { $0.value != nil },
                                palette: entry.palette, coloredPatterns: entry.coloredPatterns) { metrics in
            if entry.surface == .twoWeeks {
                let cellSize = metrics.gridCellSize(rows: 2, headerHeight: 20)
                VStack(spacing: CalendarDayAppearance.spacing) {
                    WidgetCalendarWeekdayHeader(firstWeekday: entry.firstWeekday, columnWidth: cellSize.width)
                        .frame(height: 16)
                    WidgetCalendarDayGrid(days: entry.days, display: entry.display, surface: entry.surface,
                        metrics: metrics, cellSize: cellSize, showsTodayIndicator: entry.showsTodayIndicator)
                }
            } else {
                let cellSize = metrics.columnSize(count: 3, height: 52)
                VStack(alignment: .leading, spacing: 0) {
                    WidgetThreeDayMonthTitle(entry: entry)
                    Spacer(minLength: 8)
                    WidgetCalendarWeekdayHeader(firstWeekday: entry.firstDisplayedWeekday, columnWidth: cellSize.width,
                        columnCount: 3, abbreviated: true, cellHeight: 12)
                        .padding(.bottom, CalendarDayAppearance.spacing)
                    WidgetCalendarDayGrid(days: entry.days, display: entry.display, surface: entry.surface,
                        metrics: metrics, cellSize: cellSize, columns: 3, showsTodayIndicator: false)
                }
                .frame(maxHeight: .infinity)
            }
        }
    }
}

private struct WidgetThreeDayMonthTitle: View {
    @Environment(\.locale) private var locale
    @Environment(\.widgetCalendarColors) private var colors
    var entry: WidgetPeriodEntry

    var body: some View {
        monthTitle
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(entry.palette == .classic ? colors.offAccent : colors.text)
            .lineLimit(1).minimumScaleFactor(0.65)
            .padding(.leading, 4)
            .frame(height: 24, alignment: .leading)
    }

    private var monthTitle: Text {
        let first = entry.days[0].day
        let last = entry.days[2].day
        let calendar = WidgetCalendarTimeline.calendar()
        let start = calendar.date(from: .init(year: first.year, month: first.month.rawValue, day: 1, hour: 12))!
        if first.month == last.month {
            return Text(start, format: .dateTime.month(.wide).widgetGregorian(locale: locale))
        }
        let end = calendar.date(from: .init(year: last.year, month: last.month.rawValue, day: 1, hour: 12))!
        return Text(start, format: .dateTime.month(.abbreviated).widgetGregorian(locale: locale)) + Text(verbatim: " – ")
            + Text(end, format: .dateTime.month(.abbreviated).widgetGregorian(locale: locale))
    }
}
