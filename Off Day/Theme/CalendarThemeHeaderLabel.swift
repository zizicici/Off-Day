import CoreText
import UIKit

/// Multi-line theme text uses the very same CTFrame for glyph bounds and drawing.
/// Only the currently displayed header is cached; colors need no new text layout.
final class CalendarThemeHeaderLabel: UILabel {
    var inkBackingColor: UIColor? { didSet { setNeedsDisplay() } }
    private var cached: (text: String, font: UIFont, size: CGSize, alignment: NSTextAlignment, frame: CTFrame, height: CGFloat)?

    override func drawText(in rect: CGRect) {
        guard let text, !text.isEmpty, bounds.width > 0, let context = UIGraphicsGetCurrentContext() else { return }
        let resolved: (frame: CTFrame, height: CGFloat)
        if let cached, cached.text == text, cached.font == font,
           cached.size == bounds.size, cached.alignment == textAlignment {
            resolved = (cached.frame, cached.height)
        } else {
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = textAlignment
            paragraph.lineBreakMode = .byWordWrapping
            let string = NSAttributedString(string: text, attributes: [
                .font: font as Any, .paragraphStyle: paragraph,
                NSAttributedString.Key(kCTForegroundColorFromContextAttributeName as String): true,
                NSAttributedString.Key(kCTLanguageAttributeName as String): Locale.current.identifier(.bcp47)
            ])
            let setter = CTFramesetterCreateWithAttributedString(string)
            let suggested = CTFramesetterSuggestFrameSizeWithConstraints(setter, CFRange(), nil,
                CGSize(width: bounds.width, height: .greatestFiniteMagnitude), nil)
            let height = max(bounds.height, ceil(suggested.height))
            let path = CGPath(rect: CGRect(x: 0, y: 0, width: bounds.width, height: height), transform: nil)
            let frame = CTFramesetterCreateFrame(setter, CFRange(), path, nil)
            cached = (text, font, bounds.size, textAlignment, frame, height)
            resolved = (frame, height)
        }
        let lines = CTFrameGetLines(resolved.frame) as! [CTLine]
        var origins = [CGPoint](repeating: .zero, count: lines.count)
        CTFrameGetLineOrigins(resolved.frame, CFRange(), &origins)
        context.saveGState()
        defer { context.restoreGState() }
        context.translateBy(x: 0, y: (bounds.height + resolved.height) / 2)
        context.scaleBy(x: 1, y: -1)
        context.textMatrix = .identity
        if let backing = inkBackingColor {
            context.setFillColor(backing.resolvedColor(with: traitCollection).cgColor)
            for (index, line) in lines.enumerated() {
                let ink = CTLineGetImageBounds(line, nil)
                guard !ink.isNull, !ink.isEmpty else { continue }
                context.fill(ink.offsetBy(dx: origins[index].x, dy: origins[index].y)
                    .insetBy(dx: -CalendarInkTextLayout.backingInset, dy: -CalendarInkTextLayout.backingInset))
            }
        }
        context.setFillColor(textColor.resolvedColor(with: traitCollection).cgColor)
        for (index, line) in lines.enumerated() {
            context.textPosition = origins[index]
            CTLineDraw(line, context)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }
}
