import SwiftUI
import WidgetKit

private extension WidgetKind {
    var presentation: (title: LocalizedStringKey, description: LocalizedStringKey, family: WidgetFamily) {
        switch self {
        case .lockScreen: ("widget.title", "widget.description", .accessoryRectangular)
        case .lockScreenThreeDays: ("widget.lockScreen.threeDays.title", "widget.lockScreen.threeDays.description", .accessoryRectangular)
        case .today: ("widget.today", "widget.today.description", .accessoryCircular)
        case .tomorrow: ("widget.tomorrow", "widget.tomorrow.description", .accessoryCircular)
        case .month: ("widget.month.title", "widget.month.description", .systemLarge)
        case .twoWeeks: ("widget.twoWeeks.title", "widget.twoWeeks.description", .systemMedium)
        case .threeDays: ("widget.threeDays.title", "widget.threeDays.description", .systemSmall)
        case .countdown: ("widget.countdown.title", "widget.countdown.description", .systemSmall)
        }
    }
}

extension WidgetConfiguration {
    /// Legacy and configurable versions share gallery metadata and margin policy.
    func calendarPresentation(for kind: WidgetKind) -> some WidgetConfiguration {
        let presentation = kind.presentation
        return configurationDisplayName(presentation.title)
            .description(presentation.description)
            .supportedFamilies([presentation.family])
            .contentMarginsDisabled()
    }
}
