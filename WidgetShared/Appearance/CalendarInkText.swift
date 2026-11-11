import CoreText
import UIKit

/// A single resolved line owns both its visible bounds and its drawing. Never pair
/// these bounds with a separately laid-out UILabel or SwiftUI Text.
final class CalendarInkTextLayout {
    static let backingInset: CGFloat = 1.5
    private static let cache: NSCache<Key, CalendarInkTextLayout> = {
        let cache = NSCache<Key, CalendarInkTextLayout>()
        cache.countLimit = 256
        return cache
    }()

    let line: CTLine
    let glyphBounds: CGRect
    let advance: CGFloat
    let ascent: CGFloat
    let descent: CGFloat
    let font: UIFont
    let isTruncated: Bool

    static func resolve(_ text: String, font: UIFont, size: CGSize,
                        minimumScaleFactor: CGFloat = 0.5, locale: Locale = .current) -> CalendarInkTextLayout {
        let key = Key(text: text, font: font, size: size,
                      minimumScaleFactor: minimumScaleFactor, locale: locale.identifier(.bcp47))
        if let cached = cache.object(forKey: key) { return cached }
        let value = CalendarInkTextLayout(key: key)
        cache.setObject(value, forKey: key)
        return value
    }

    private init(key: Key) {
        func create(_ text: String, font: UIFont) -> CTLine {
            CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: [
                .font: font,
                NSAttributedString.Key(kCTLanguageAttributeName as String): key.locale,
                NSAttributedString.Key(kCTForegroundColorFromContextAttributeName as String): true
            ]))
        }
        var font = key.font
        var line = create(key.text, font: font)
        let minimumSize = key.font.pointSize * min(1, max(0.01, key.minimumScaleFactor))
        // Optical font sizing can change advances after shrinking. Resolve again
        // before truncating so the measurements describe the final displayed line.
        for _ in 0..<3 {
            var ascent: CGFloat = 0, descent: CGFloat = 0
            let width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, nil))
            let ink = CTLineGetImageBounds(line, nil)
            var factor = min(1, max(0, key.size.width) / max(width, 0.001))
            if !ink.isNull, !ink.isEmpty {
                let horizontalExtent = max(abs(ink.minX - width / 2), abs(ink.maxX - width / 2))
                let verticalCenter = (ascent - descent) / 2
                let verticalExtent = max(abs(ink.minY - verticalCenter), abs(ink.maxY - verticalCenter))
                factor = min(factor,
                    max(0, key.size.width / 2 - Self.backingInset) / max(horizontalExtent, 0.001),
                    max(0, key.size.height / 2 - Self.backingInset) / max(verticalExtent, 0.001))
            }
            let nextSize = max(minimumSize, font.pointSize * factor)
            guard nextSize < font.pointSize - 0.001 else { break }
            font = key.font.withSize(nextSize)
            line = create(key.text, font: font)
        }
        let width = max(0, key.size.width)
        if CTLineGetTypographicBounds(line, nil, nil, nil) > width + 0.001,
           let truncated = CTLineCreateTruncatedLine(line, max(0, width - Self.backingInset * 2), .end, create("…", font: font)) {
            line = truncated
            isTruncated = true
        } else {
            isTruncated = false
        }
        var ascent: CGFloat = 0, descent: CGFloat = 0
        self.advance = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, nil))
        self.ascent = ascent
        self.descent = descent
        self.glyphBounds = CTLineGetImageBounds(line, nil)
        self.font = font
        self.line = line
    }

    func origin(in size: CGSize) -> CGPoint {
        CGPoint(x: (size.width - advance) / 2, y: (size.height - ascent - descent) / 2 + descent)
    }

    /// Bounds in UIKit/SwiftUI coordinates, excluding side bearings and font leading.
    func visibleBounds(in size: CGSize) -> CGRect {
        guard !glyphBounds.isNull, !glyphBounds.isEmpty else { return .null }
        let origin = origin(in: size)
        return CGRect(x: origin.x + glyphBounds.minX, y: size.height - origin.y - glyphBounds.maxY,
                      width: glyphBounds.width, height: glyphBounds.height)
    }

    func draw(in context: CGContext, size: CGSize, foreground: CGColor, backing: CGColor) {
        guard size.width > 0, size.height > 0, !glyphBounds.isNull, !glyphBounds.isEmpty else { return }
        context.saveGState()
        defer { context.restoreGState() }
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1, y: -1)
        context.textMatrix = .identity
        let origin = origin(in: size)
        let backingRect = glyphBounds.offsetBy(dx: origin.x, dy: origin.y)
            .insetBy(dx: -Self.backingInset, dy: -Self.backingInset)
        context.setFillColor(backing)
        context.fill(backingRect)
        context.setFillColor(foreground)
        context.textPosition = origin
        CTLineDraw(line, context)
    }

    private final class Key: NSObject {
        let text: String
        let font: UIFont
        let size: CGSize
        let minimumScaleFactor: CGFloat
        let locale: String

        init(text: String, font: UIFont, size: CGSize, minimumScaleFactor: CGFloat, locale: String) {
            self.text = text; self.font = font; self.size = size
            self.minimumScaleFactor = minimumScaleFactor; self.locale = locale
        }

        override var hash: Int {
            var hasher = Hasher()
            hasher.combine(text); hasher.combine(font); hasher.combine(size.width); hasher.combine(size.height)
            hasher.combine(minimumScaleFactor); hasher.combine(locale)
            return hasher.finalize()
        }

        override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? Key else { return false }
            return text == other.text && font == other.font && size == other.size
                && minimumScaleFactor == other.minimumScaleFactor && locale == other.locale
        }
    }
}
