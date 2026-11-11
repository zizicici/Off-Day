import SwiftUI

struct WidgetCalendarMarkSelectedKey: LayoutValueKey {
    static let defaultValue = false
}

/// Measure full labels before choosing a row; both capsules receive the same size.
/// Selection allowance only affects fitting, leaving unselected text visually centered.
struct WidgetCalendarMarkLayout: Layout {
    var prefersVertical: Bool
    var spacing: CGFloat
    var selectionAllowance: CGFloat

    private struct Arrangement {
        var width: CGFloat
        var button: CGSize
        var vertical: Bool
        var count: Int
        var spacing: CGFloat

        var size: CGSize {
            CGSize(width: width, height: vertical ? button.height * CGFloat(count) + spacing * CGFloat(max(0, count - 1)) : button.height)
        }
    }

    private func arrangement(width proposed: CGFloat?, subviews: Subviews) -> Arrangement {
        let count = subviews.count
        let idealWidth = subviews.map {
            $0.sizeThatFits(.unspecified).width + ($0[WidgetCalendarMarkSelectedKey.self] ? 0 : selectionAllowance)
        }.max() ?? 0
        let rowWidth = idealWidth * CGFloat(count) + spacing * CGFloat(max(0, count - 1))
        let width = proposed ?? (prefersVertical ? idealWidth : rowWidth)
        let vertical = prefersVertical || rowWidth > width
        let buttonWidth = vertical ? width : max(0, (width - spacing * CGFloat(max(0, count - 1))) / CGFloat(max(1, count)))
        let height = subviews.map { $0.sizeThatFits(ProposedViewSize(width: buttonWidth, height: nil)).height }.max() ?? 0
        return Arrangement(width: width, button: CGSize(width: buttonWidth, height: height),
                           vertical: vertical, count: count, spacing: spacing)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrangement(width: proposal.width, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let layout = arrangement(width: bounds.width, subviews: subviews)
        for (index, view) in subviews.enumerated() {
            let offset = CGFloat(index)
            let point = CGPoint(x: bounds.minX + (layout.vertical ? 0 : offset * (layout.button.width + spacing)),
                                y: bounds.minY + (layout.vertical ? offset * (layout.button.height + spacing) : 0))
            view.place(at: point, anchor: .topLeading, proposal: ProposedViewSize(layout.button))
        }
    }
}
