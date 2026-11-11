import UIKit

final class CalendarInkTextLabel: UILabel {
    var inkBackingColor: UIColor? {
        didSet { setNeedsDisplay() }
    }

    override func drawText(in rect: CGRect) {
        guard let inkBackingColor else { return super.drawText(in: rect) }
        guard let context = UIGraphicsGetCurrentContext(), let text, !text.isEmpty else { return }
        let layout = CalendarInkTextLayout.resolve(text, font: font, size: bounds.size,
            minimumScaleFactor: adjustsFontSizeToFitWidth ? minimumScaleFactor : 1)
        layout.draw(in: context, size: bounds.size,
            foreground: textColor.resolvedColor(with: traitCollection).cgColor,
            backing: inkBackingColor.resolvedColor(with: traitCollection).cgColor)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if inkBackingColor != nil { setNeedsDisplay() }
    }
}

/// MarqueeLabel keeps its existing scrolling and fading. A cached attachment moves
/// the text and its backing together, without measuring its private scrolling label.
enum CalendarInkTextAttachment {
    private static let cache: NSCache<Key, NSAttributedString> = {
        let cache = NSCache<Key, NSAttributedString>()
        cache.countLimit = 128
        cache.totalCostLimit = 4 * 1024 * 1024
        return cache
    }()

    static func text(_ text: String, font: UIFont, foreground: UIColor, backing: UIColor,
                     traits: UITraitCollection) -> NSAttributedString {
        let foreground = foreground.resolvedColor(with: traits)
        let backing = backing.resolvedColor(with: traits)
        let scale = max(1, traits.displayScale)
        let key = Key(text: text, font: font, foreground: foreground, backing: backing, scale: scale)
        if let cached = cache.object(forKey: key) { return cached }
        let layout = CalendarInkTextLayout.resolve(text, font: font,
            size: CGSize(width: .greatestFiniteMagnitude, height: font.lineHeight), minimumScaleFactor: 1)
        let padding = CalendarInkTextLayout.backingInset
        let size = CGSize(width: ceil(layout.advance + padding * 2), height: ceil(layout.ascent + layout.descent + padding * 2))
        guard !layout.glyphBounds.isNull, size.width * scale <= 8192, size.height * scale <= 512 else {
            return NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: foreground])
        }
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.preferredRange = .standard
        let image = UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            layout.draw(in: renderer.cgContext, size: size, foreground: foreground.cgColor, backing: backing.cgColor)
        }
        let attachment = NSTextAttachment()
        attachment.image = image
        attachment.bounds = CGRect(x: 0, y: -layout.descent - padding, width: size.width, height: size.height)
        let result = NSMutableAttributedString(attachment: attachment)
        result.addAttribute(.font, value: font, range: NSRange(location: 0, length: result.length))
        cache.setObject(result, forKey: key, cost: Int(size.width * scale) * Int(size.height * scale) * 4)
        return result
    }

    private final class Key: NSObject {
        let text: String
        let font: UIFont
        let foreground: UIColor
        let backing: UIColor
        let scale: CGFloat
        let locale = Locale.current.identifier

        init(text: String, font: UIFont, foreground: UIColor, backing: UIColor, scale: CGFloat) {
            self.text = text; self.font = font; self.foreground = foreground; self.backing = backing; self.scale = scale
        }

        override var hash: Int {
            var hasher = Hasher()
            hasher.combine(text); hasher.combine(font); hasher.combine(foreground); hasher.combine(backing)
            hasher.combine(scale); hasher.combine(locale)
            return hasher.finalize()
        }

        override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? Key else { return false }
            return text == other.text && font == other.font && foreground == other.foreground && backing == other.backing
                && scale == other.scale && locale == other.locale
        }
    }
}
