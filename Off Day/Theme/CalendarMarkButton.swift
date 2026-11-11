import UIKit

/// Semantic date-state control shared by app editors. Its appearance comes from
/// the current theme; its selected value remains owned by the editor's data model.
final class CalendarMarkButton: UIButton {
    let isOffDay: Bool
    private let texture = CalendarDayTextureView()

    init(isOffDay: Bool) {
        self.isOffDay = isOffDay
        super.init(frame: .zero)
        texture.isUserInteractionEnabled = false
        texture.clipsToBounds = true
        accessibilityIdentifier = isOffDay ? "calendar.mark.off" : "calendar.mark.work"
        accessibilityLabel = String(localized: isOffDay ? "detail.day.off.title" : "detail.day.work.title")
        accessibilityHint = String(localized: isOffDay ? "detail.day.off.hint" : "detail.day.work.hint")
        updateConfiguration()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func updateConfiguration() {
        let colors = AppTheme.current.colors(for: traitCollection)
        let paint = colors.markControl(isOffDay: isOffDay, selected: isSelected)
        let foreground = UIColor(paint.foreground).resolvedColor(with: traitCollection)
        let background = UIColor(paint.background).resolvedColor(with: traitCollection)
        let font = UIFont.preferredSystemFont(for: .body, weight: .medium)
        var config: UIButton.Configuration = paint.usesPatterns ? .plain() : .tinted()
        config.cornerStyle = .capsule
        config.title = accessibilityLabel
        config.imagePadding = 4
        config.contentInsets = .init(top: 12, leading: paint.usesPatterns ? 8 : 0,
                                    bottom: 12, trailing: paint.usesPatterns ? 8 : 0)
        config.titleAlignment = .center
        config.titleLineBreakMode = .byWordWrapping
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var result = incoming
            result.font = font
            return result
        }
        if isSelected {
            config.image = UIImage(systemName: "checkmark", withConfiguration:
                UIImage.SymbolConfiguration(pointSize: min(20, font.pointSize * 0.85), weight: .semibold))
        }
        if paint.usesPatterns {
            config.baseForegroundColor = foreground
            config.background.backgroundColor = background
            config.background.strokeColor = UIColor(paint.stroke).resolvedColor(with: traitCollection)
            config.background.strokeWidth = isSelected ? CalendarDayTexture.lineWidth : 0
            texture.update(appearance: paint.palette, colors: colors)
            config.background.customView = texture
            config.attributedTitle = AttributedString(CalendarInkTextAttachment.text(accessibilityLabel ?? "", font: font,
                foreground: foreground, backing: background, traits: traitCollection))
        }
        tintColor = paint.usesPatterns ? foreground : (isOffDay ? AppColor.accent : AppColor.workDay)
        configuration = config
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if AppTheme.current.usesPatterns { texture.layer.cornerRadius = texture.bounds.height / 2 }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection)
            || traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            setNeedsUpdateConfiguration()
        }
    }
}
