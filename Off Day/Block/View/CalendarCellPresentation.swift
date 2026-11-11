import SwiftUI
import UIKit

struct CalendarCellPresentation {
    var style: CalendarVisualStyle
    var appearance: CalendarDayAppearance.Palette

    private static let cache = NSCache<NSString, UIColor>()

    func colors(for traits: UITraitCollection) -> WidgetCalendarColors {
        style.palette.colors(for: traits.userInterfaceStyle == .dark ? .dark : .light,
                             coloredPatterns: style.coloredPatterns)
    }

    var background: UIColor {
        if style == CalendarVisualStyle() { return UIColor(named: appearance.backgroundAsset) ?? UIColor.paper }
        return dynamic("background") { $0.background(for: appearance) }
    }

    var foreground: UIColor {
        if style == CalendarVisualStyle() { return appearance.whiteText ? .white : UIColor.text }
        return dynamic("foreground") { $0.foreground(for: appearance) }
    }

    var today: UIColor {
        if style == CalendarVisualStyle() { return UIColor.today }
        return dynamic("today") { $0.todayStroke(for: appearance) }
    }

    private func dynamic(_ role: String, resolve: @escaping (WidgetCalendarColors) -> Color) -> UIColor {
        let key = "\(style.palette.rawValue).\(style.coloredPatterns).\(appearance.backgroundAsset).\(appearance.whiteText).\(role)" as NSString
        if let cached = Self.cache.object(forKey: key) { return cached }
        let color = UIColor { traits in UIColor(resolve(colors(for: traits))).resolvedColor(with: traits) }
        Self.cache.setObject(color, forKey: key)
        return color
    }
}

final class CalendarDayTextureView: UIView {
    override class var layerClass: AnyClass { CAShapeLayer.self }
    private var texture = CalendarDayTexture.plain
    private var lastBounds = CGRect.null

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.actions = ["path": NSNull(), "fillColor": NSNull()]
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(appearance: CalendarDayAppearance.Palette, colors: WidgetCalendarColors) {
        let next = colors.usesPatterns ? CalendarDayTexture(appearance: appearance) : .plain
        isHidden = next == .plain
        (layer as? CAShapeLayer)?.fillColor = UIColor(colors.patternColor(for: appearance))
            .resolvedColor(with: traitCollection).withAlphaComponent(CGFloat(colors.patternOpacity)).cgColor
        if next != texture {
            texture = next
            lastBounds = .null
        }
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds != lastBounds else { return }
        lastBounds = bounds
        (layer as? CAShapeLayer)?.path = texture.path(in: bounds)
    }
}

final class CalendarDayCornerMarkView: UIView {
    private let original = UIImageView()
    private let symbol = UIImageView()
    private let triangle = CAShapeLayer()
    private let separator = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        layer.addSublayer(triangle)
        layer.addSublayer(separator)
        addSubview(original)
        addSubview(symbol)
        symbol.contentMode = .scaleAspectFit
        for shape in [triangle, separator] {
            shape.actions = ["path": NSNull(), "fillColor": NSNull(), "strokeColor": NSNull(),
                             "bounds": NSNull(), "position": NSNull()]
        }
        separator.fillColor = UIColor.clear.cgColor
        separator.lineWidth = 1
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(isOffDay: Bool, appearance: CalendarDayAppearance.Palette, colors: WidgetCalendarColors) {
        original.isHidden = !colors.usesOriginalMarks
        symbol.isHidden = colors.usesOriginalMarks
        triangle.isHidden = colors.usesOriginalMarks
        separator.isHidden = colors.usesOriginalMarks
        if colors.usesOriginalMarks {
            original.image = UIImage(named: isOffDay ? "OffDayMark" : "WorkDayMark")
        } else {
            triangle.fillColor = UIColor(colors.markFill(isOffDay: isOffDay, appearance: appearance)).resolvedColor(with: traitCollection).cgColor
            separator.strokeColor = UIColor(colors.markSymbol(appearance: appearance)).resolvedColor(with: traitCollection).cgColor
            symbol.tintColor = UIColor(colors.markSymbol(appearance: appearance)).resolvedColor(with: traitCollection)
            symbol.image = UIImage(systemName: CalendarDayMarkGeometry.symbol(isOffDay: isOffDay),
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 9, weight: .bold))
        }
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        original.frame = bounds
        symbol.frame = CalendarDayMarkGeometry.symbolRect(in: bounds)
        triangle.frame = bounds
        triangle.path = CalendarDayMarkGeometry.triangle(in: bounds)
        separator.frame = bounds
        let path = CGMutablePath()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY))
        separator.path = path
    }
}
