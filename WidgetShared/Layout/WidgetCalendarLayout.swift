import SwiftUI

/// One measurement per widget; date cells only receive resolved sizes and corner radii.
struct WidgetCalendarLayoutMetrics {
    var size: CGSize
    var inset: CGFloat
    var bottomLeadingRadius: CGFloat
    var bottomTrailingRadius: CGFloat

    var contentSize: CGSize { CGSize(width: max(1, size.width - inset * 2), height: max(1, size.height - inset * 2)) }
    var columnWidth: CGFloat { (contentSize.width - CalendarDayAppearance.spacing * 6) / 7 }

    init(size: CGSize, inset: CGFloat, bottomLeadingRadius: CGFloat = 0, bottomTrailingRadius: CGFloat = 0) {
        self.size = size
        self.inset = inset
        self.bottomLeadingRadius = bottomLeadingRadius
        self.bottomTrailingRadius = bottomTrailingRadius
    }

    init(geometry: GeometryProxy, inset: CGFloat) {
        size = geometry.size
        self.inset = inset
        bottomLeadingRadius = 0
        bottomTrailingRadius = 0
        if #available(iOS 27.0, *), let corners = geometry.concentricCornerRadii {
            bottomLeadingRadius = corners.bottomLeading
            bottomTrailingRadius = corners.bottomTrailing
        } else if #available(iOS 26.0, *) {
            let corners = geometry.containerCornerInsets
            bottomLeadingRadius = max(corners.bottomLeading.width, corners.bottomLeading.height)
            bottomTrailingRadius = max(corners.bottomTrailing.width, corners.bottomTrailing.height)
        }
    }

    func gridCellSize(rows: Int, headerHeight: CGFloat) -> CGSize {
        CGSize(width: columnWidth,
               height: max(1, (contentSize.height - headerHeight - CGFloat(rows - 1) * CalendarDayAppearance.spacing) / CGFloat(rows)))
    }

    func columnSize(count: Int, height: CGFloat) -> CGSize {
        CGSize(width: (contentSize.width - CGFloat(count - 1) * CalendarDayAppearance.spacing) / CGFloat(count), height: height)
    }

    func detailInset(for surface: WidgetCalendarSurface) -> CGFloat {
        switch surface {
        case .month: 18
        case .twoWeeks: 12
        case .threeDays: 8
        }
    }

    func shape(size: CGSize, bottomLeading: Bool = false, bottomTrailing: Bool = false) -> WidgetCalendarCellShape {
        let radius = CalendarDayAppearance.cornerRadius
        let limit = min(size.width, size.height) / 2
        // Some WidgetKit presentations only expose a legacy container shape. Preserve the
        // two outer arcs even when numeric system corner information is unavailable.
        let leading = min(limit, max(12, bottomLeadingRadius - inset))
        let trailing = min(limit, max(12, bottomTrailingRadius - inset))
        return WidgetCalendarCellShape(
            bottomLeading: bottomLeading ? leading : radius,
            bottomTrailing: bottomTrailing ? trailing : radius)
    }
}

struct WidgetCalendarCellShape: InsettableShape {
    var bottomLeading: CGFloat = CalendarDayAppearance.cornerRadius
    var bottomTrailing: CGFloat = CalendarDayAppearance.cornerRadius
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        if #available(iOS 17.0, *) {
            UnevenRoundedRectangle(topLeadingRadius: CalendarDayAppearance.cornerRadius,
                bottomLeadingRadius: bottomLeading, bottomTrailingRadius: bottomTrailing,
                topTrailingRadius: CalendarDayAppearance.cornerRadius, style: .continuous)
                .inset(by: insetAmount).path(in: rect)
        } else {
            RoundedRectangle(cornerRadius: CalendarDayAppearance.cornerRadius, style: .continuous)
                .inset(by: insetAmount).path(in: rect)
        }
    }

    func inset(by amount: CGFloat) -> Self {
        var result = self
        result.insetAmount += amount
        return result
    }
}
