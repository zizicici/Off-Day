import UIKit

/// A six-point repeating tile, shared by the home navigation and weekday bar.
/// Both surfaces use the same native pattern color to keep their tiles aligned.
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
