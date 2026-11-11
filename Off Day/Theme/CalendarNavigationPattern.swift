import UIKit

/// A six-point repeating tile for the home's shared header background.
enum CalendarNavigationPattern {
    static let period: CGFloat = 6
    static let palette = CalendarDayAppearance.Palette(backgroundAsset: "OffDayColor", whiteText: true)
    private static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 8
        return cache
    }()

    static func image(for traits: UITraitCollection) -> UIImage {
        let scale = max(1, traits.displayScale)
        let key = "\(traits.userInterfaceStyle.rawValue).\(scale)" as NSString
        if let image = cache.object(forKey: key) { return image }
        let colors = WidgetCalendarColors.coloredPatterns(for: traits.userInterfaceStyle == .dark ? .dark : .light)
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true
        format.preferredRange = .standard
        let image = UIGraphicsImageRenderer(size: CGSize(width: period, height: period), format: format).image { render in
            UIColor(colors.background(for: palette)).resolvedColor(with: traits).setFill()
            render.fill(CGRect(x: 0, y: 0, width: period, height: period))
            let cg = render.cgContext
            cg.setFillColor(UIColor(colors.patternColor(for: palette)).resolvedColor(with: traits)
                .withAlphaComponent(CGFloat(colors.patternOpacity)).cgColor)
            cg.addPath(CalendarDayTexture.diagonal.path(in: CGRect(x: 0, y: 0, width: period, height: period)))
            cg.fillPath()
        }
        cache.setObject(image, forKey: key)
        return image
    }
}

/// One drawing surface extends behind both bars. Separate pattern colors start
/// at separate drawing origins on older UIKit versions, even with the same tile.
final class CalendarNavigationPatternView: UIView {
    private var appearanceKey: String?

    func refreshTheme() {
        let style = AppTheme.current.style
        let key = "\(style.usesColoredPatterns).\(traitCollection.userInterfaceStyle.rawValue).\(traitCollection.displayScale)"
        guard appearanceKey != key else { return }
        appearanceKey = key
        isHidden = !style.usesColoredPatterns
        backgroundColor = style.usesColoredPatterns
            ? UIColor(patternImage: CalendarNavigationPattern.image(for: traitCollection)) : .clear
    }
}
