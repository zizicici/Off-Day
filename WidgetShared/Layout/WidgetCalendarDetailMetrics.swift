import UIKit

struct WidgetCalendarDetailMetrics {
    var surface: WidgetCalendarSurface

    var contentInset: CGFloat { surface == .month ? 12 : 8 }
    var buttonHeight: CGFloat {
        switch surface {
        case .month: 44
        case .twoWeeks: 34
        case .threeDays: 28
        }
    }

    var buttonFontSize: CGFloat {
        switch surface {
        case .month: 17
        case .twoWeeks: 15
        case .threeDays: 14
        }
    }

    var buttonSpacing: CGFloat { surface == .month ? 12 : (surface == .twoWeeks ? 8 : 4) }
    var buttonHorizontalInset: CGFloat { surface == .threeDays ? 10 : 12 }
    var buttonVerticalInset: CGFloat { surface == .month ? 10 : (surface == .twoWeeks ? 8 : 5) }
    var selectionAllowance: CGFloat { buttonFontSize + 4 }

    func preferredWidth(locale: Locale) -> CGFloat {
        let font = UIFont.systemFont(ofSize: buttonFontSize, weight: .medium)
        let longestLabel = ["detail.day.off.title", "detail.day.work.title"].map { key in
            let text = String(localized: String.LocalizationValue(key), locale: locale)
            return (text as NSString).size(withAttributes: [.font: font]).width
        }.max() ?? 0
        // Leave a few points for SwiftUI's text shaping in addition to UIKit's measurement.
        let buttonWidth = ceil(longestLabel) + buttonHorizontalInset * 2 + selectionAllowance + 4
        let required = (surface == .threeDays ? buttonWidth : buttonWidth * 2 + buttonSpacing) + contentInset * 2
        let preferred: CGFloat = surface == .month ? 248 : (surface == .twoWeeks ? 228 : 128)
        return min(surface == .threeDays ? 160 : 280, max(preferred, required))
    }

    // Derive the panel's curvature from the capsule radius and its content padding.
    var cornerRadius: CGFloat { buttonHeight / 2 + contentInset }
}
