import CoreGraphics

/// One geometry definition for UIKit and SwiftUI, with equal physical line widths.
enum CalendarDayTexture: Hashable {
    case plain, diagonal, horizontal, dots

    static let lineWidth: CGFloat = 1.5
    static let lineSpacing = CGFloat(6) / CGFloat(2).squareRoot()

    init(appearance: CalendarDayAppearance.Palette) {
        switch appearance.backgroundAsset {
        case "OffDayColor": self = .diagonal
        case "WeekEndColor": self = .horizontal
        case "WorkDayColor": self = .dots
        default: self = .plain
        }
    }

    func path(in rect: CGRect) -> CGPath {
        let path = CGMutablePath()
        switch self {
        case .diagonal:
            let scale = CGFloat(2).squareRoot()
            let width = Self.lineWidth * scale
            for offset in stride(from: -rect.height, through: rect.width, by: Self.lineSpacing * scale) {
                path.move(to: CGPoint(x: offset, y: rect.maxY))
                path.addLine(to: CGPoint(x: offset + rect.height, y: rect.minY))
                path.addLine(to: CGPoint(x: offset + rect.height + width, y: rect.minY))
                path.addLine(to: CGPoint(x: offset + width, y: rect.maxY))
                path.closeSubpath()
            }
        case .horizontal:
            for y in stride(from: CGFloat(2), through: rect.height, by: Self.lineSpacing) {
                path.addRect(CGRect(x: 0, y: y, width: rect.width, height: Self.lineWidth))
            }
        case .dots:
            for y in stride(from: CGFloat(2), through: rect.height, by: 5.5) {
                for x in stride(from: CGFloat(2), through: rect.width, by: 5.5) {
                    path.addEllipse(in: CGRect(x: x, y: y, width: 2, height: 2))
                }
            }
        case .plain: break
        }
        return path
    }
}

enum CalendarDayMarkGeometry {
    static func symbol(isOffDay: Bool) -> String { isOffDay ? "zzz" : "briefcase.fill" }
    static func side(for width: CGFloat) -> CGFloat { min(20, max(16, width * 0.45)) }

    static func symbolRect(in rect: CGRect) -> CGRect {
        CGRect(x: rect.width * 0.52, y: rect.height * 0.06, width: rect.width * 0.42, height: rect.height * 0.42)
    }

    static func triangle(in rect: CGRect) -> CGPath {
        let path = CGMutablePath()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
