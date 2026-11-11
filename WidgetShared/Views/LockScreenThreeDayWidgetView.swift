import SwiftUI
import WidgetKit

struct LockScreenThreeDayWidgetView: View {
    var entry: WidgetPeriodEntry

    var body: some View {
        WidgetAccessoryContainer {
            content
        }
    }

    private var content: some View {
        Group {
            if entry.days.contains(where: { $0.value != nil }) {
                GeometryReader { geometry in
                    let presentation = WidgetCalendarGridPresentation.accessory
                    let metrics = WidgetCalendarLayoutMetrics(size: geometry.size, inset: 0)
                    let size = metrics.columnSize(count: 3,
                        height: max(1, metrics.contentSize.height - 12 - presentation.verticalSpacing))
                    VStack(spacing: presentation.verticalSpacing) {
                        WidgetCalendarWeekdayHeader(firstWeekday: entry.firstDisplayedWeekday, columnWidth: size.width,
                            columnCount: 3, abbreviated: true, cellHeight: 12, presentation: presentation)
                        WidgetCalendarDayGrid(days: entry.days, display: entry.display, surface: .threeDays,
                            metrics: metrics, cellSize: size, columns: 3, showsTodayIndicator: false,
                            presentation: presentation)
                    }
                    .environment(\.widgetCalendarColors, WidgetCalendarColors.systemRendered)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
                .padding(.horizontal, 2)
            } else {
                WidgetOpenAppPlaceholder(style: .accessory)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
