import SwiftUI

/// Home calendars adapt their two outside bottom corners to the widget container.
/// Accessory calendars use uniform corners; empty slots stay inert.
struct WidgetCalendarDayGrid: View {
    var days: [WidgetCalendarDayItem]
    var display: WidgetCalendarDisplay
    var surface: WidgetCalendarSurface
    var metrics: WidgetCalendarLayoutMetrics
    var cellSize: CGSize
    var columns = 7
    var leadingEmptyCount = 0
    var showsTodayIndicator = true
    var presentation: WidgetCalendarGridPresentation = .home

    private var rowCount: Int { (leadingEmptyCount + days.count + columns - 1) / columns }

    var body: some View {
        VStack(spacing: presentation.verticalSpacing) {
            ForEach(0..<rowCount, id: \.self) { row in
                HStack(spacing: CalendarDayAppearance.spacing) {
                    ForEach(0..<columns, id: \.self) { column in
                        let index = row * columns + column - leadingEmptyCount
                        if days.indices.contains(index) {
                            WidgetCalendarDayCell(day: days[index], display: display, surface: surface,
                                size: cellSize, shape: metrics.shape(size: cellSize,
                                    bottomLeading: presentation == .home && row == rowCount - 1 && column == 0,
                                    bottomTrailing: presentation == .home && row == rowCount - 1 && column == columns - 1),
                                showsTodayIndicator: showsTodayIndicator, isInteractive: presentation == .home,
                                showsShadow: presentation == .home, dateFontSize: presentation.dateFontSize)
                        } else {
                            Color.clear.frame(width: cellSize.width, height: cellSize.height)
                                .accessibilityHidden(true)
                        }
                    }
                }
            }
        }
    }
}
