import UIKit

/// Date selectors keep their own selection model and text. This adapter applies
/// the same day-role palette and texture used by calendar cells and mark controls.
final class CalendarSelectionAppearance {
    private let base: UIButton.Configuration
    private let titleFont: UIFont
    private let subtitleFont: UIFont?
    private let texture = CalendarDayTextureView()

    init(configuration: UIButton.Configuration, titleFont: UIFont = .systemFont(ofSize: 17), subtitleFont: UIFont? = nil) {
        base = configuration
        self.titleFont = titleFont
        self.subtitleFont = subtitleFont
        texture.isUserInteractionEnabled = false
        texture.clipsToBounds = true
    }

    func update(_ button: UIButton) {
        var config = base
        if button.isHighlighted || button.isSelected {
            let palette = CalendarDayAppearance.palette(baseIsOffDay: true, publicIsOffDay: nil,
                blueWeekends: WeekEndColorType.getValue() == .blue, paperHolidayWorkdays: false)
            let colors = AppTheme.current.colors(for: button.traitCollection)
            let background = UIColor(colors.background(for: palette)).resolvedColor(with: button.traitCollection)
            let foreground = UIColor(colors.foreground(for: palette)).resolvedColor(with: button.traitCollection)
            config.baseBackgroundColor = background
            config.baseForegroundColor = foreground
            if colors.usesInkBacking(for: palette) {
                config.titlePadding = 0
                config.background.backgroundColor = background
                config.background.backgroundColorTransformer = nil
                config.background.strokeWidth = CalendarDayTexture.lineWidth
                config.background.strokeColor = foreground.withAlphaComponent(0.55)
                texture.update(appearance: palette, colors: colors)
                texture.layer.cornerRadius = config.background.cornerRadius
                config.background.customView = texture
                if let title = base.title {
                    config.attributedTitle = AttributedString(CalendarInkTextAttachment.text(title, font: titleFont,
                        foreground: foreground, backing: background, traits: button.traitCollection))
                }
                if let subtitle = base.subtitle, let subtitleFont {
                    config.attributedSubtitle = AttributedString(CalendarInkTextAttachment.text(subtitle, font: subtitleFont,
                        foreground: foreground, backing: background, traits: button.traitCollection))
                }
            }
        } else {
            config.baseBackgroundColor = .clear
            config.baseForegroundColor = AppColor.text
        }
        button.configuration = config
        // Image-backed titles retain the original spoken label.
        button.accessibilityLabel = [base.title, base.subtitle].compactMap { $0 }.joined(separator: ", ")
    }
}
