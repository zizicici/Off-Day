//
//  UIColor+Extension.swift
//  Off Day
//
//  Created by zici on 2023/12/22.
//

import UIKit

extension UIColor {
    convenience init?(hex: String, alpha: CGFloat = 1.0) {
        var hexFormatted = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()
        
        if hexFormatted.hasPrefix("#") {
            hexFormatted.remove(at: hexFormatted.startIndex)
        }
        var hexValue: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&hexValue)
        
        switch hexFormatted.count {
        case 6:
            self.init(red: CGFloat((hexValue & 0xFF0000) >> 16) / 255.0,
                      green: CGFloat((hexValue & 0x00FF00) >> 8) / 255.0,
                      blue: CGFloat(hexValue & 0x0000FF) / 255.0,
                      alpha: alpha)
        case 8:
            self.init(red: CGFloat((hexValue & 0xFF000000) >> 24) / 255.0,
                      green: CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0,
                      blue: CGFloat((hexValue & 0x0000FF00) >> 8) / 255.0,
                      alpha: CGFloat(hexValue & 0x000000FF) / 255.0)
        default:
            return nil
        }
    }
    
    func toHexString() -> String? {
        guard let components = cgColor.components, components.count > 0 else {
            return nil
        }
        var r: Float = 0
        var g: Float = 0
        var b: Float = 0
        var a: Float = 0
        switch components.count {
        case 1:
            r = Float(components[0])
            g = Float(components[0])
            b = Float(components[0])
            a = 1.0
        case 2:
            r = Float(components[0])
            g = Float(components[0])
            b = Float(components[0])
            a = Float(components[1])
        case 3:
            r = Float(components[0])
            g = Float(components[1])
            b = Float(components[2])
            a = 1.0
        default:
            r = Float(components[0])
            g = Float(components[1])
            b = Float(components[2])
            a = Float(components[3])
        }
        
        let hexString = String(format: "%02lX%02lX%02lX%02lX",
                               lroundf(r * 255),
                               lroundf(g * 255),
                               lroundf(b * 255),
                               lroundf(a * 255))
        
        return hexString
    }
}

extension UIColor {
    func generateLightDarkString() -> String {
        let lightColorHexString = resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)).toHexString() ?? ""
        let darkColorHexString = resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)).toHexString() ?? ""
        return "\(lightColorHexString),\(darkColorHexString)"
    }
    
    convenience init?(string: String) {
        let lightDark = string.split(separator: ",")
        switch lightDark.count {
        case 1:
            self.init(hex: string, alpha: 1.0)
        case 2:
            if let first = lightDark.first, let last = lightDark.last, let light = UIColor(hex: "\(first)"), let dark = UIColor(hex: "\(last)") {
                self.init(dynamicProvider: { traitCollection -> UIColor in
                    switch traitCollection.userInterfaceStyle {
                    case .light, .unspecified:
                        return light
                    case .dark:
                        return dark
                    @unknown default:
                        fatalError()
                    }
                })
            } else {
                return nil
            }
        default:
            return nil
        }
    }
}


extension UIColor {
    var isLight: Bool {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: nil)
        let threshold: CGFloat = 75.0 // 自定义阈值(0-1)，数值越小，认为颜色越暗
        let gray = YtoLstar(Y: rgbToY(r: red, g: green, b: blue)) // 计算灰度值（在RGB空间内）
        return gray > threshold
    }
    
    func sRGBtoLin(_ colorChannel: CGFloat) -> CGFloat {
        if colorChannel <= 0.04045 {
            return colorChannel / 12.92
        }
        return pow((colorChannel + 0.055) / 1.055, 2.4)
    }

    func rgbToY(r: CGFloat, g: CGFloat, b: CGFloat) -> CGFloat {
        return 0.2126 * sRGBtoLin(r) + 0.7152 * sRGBtoLin(g) + 0.0722 * sRGBtoLin(b)
    }

    func YtoLstar(Y: CGFloat) -> CGFloat {
        if Y <= (216 / 24389) {
            return Y * (24389 / 27)
        }
        return pow(Y, (1 / 3)) * 116 - 16
    }
    
    func isSimilar(to color: UIColor, threshold: CGFloat = 0.2) -> Bool {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let distance = sqrt(pow(r1 - r2, 2) + pow(g1 - g2, 2) + pow(b1 - b2, 2))
        return distance <= threshold
    }
}

extension UIColor {
    /// 将当前颜色叠加到背景色上，模拟图层叠加效果
    /// - Parameter background: 背景颜色
    /// - Returns: 叠加后的新颜色
    func overlay(on background: UIColor) -> UIColor {
        // 确保两种颜色都在同一颜色空间（这里使用sRGB）
        let foreground = self.resolvedColor(with: .current)
        let background = background.resolvedColor(with: .current)
        
        var fgR: CGFloat = 0, fgG: CGFloat = 0, fgB: CGFloat = 0, fgA: CGFloat = 0
        var bgR: CGFloat = 0, bgG: CGFloat = 0, bgB: CGFloat = 0, bgA: CGFloat = 0
        
        // 获取前景色和背景色的RGBA分量
        foreground.getRed(&fgR, green: &fgG, blue: &fgB, alpha: &fgA)
        background.getRed(&bgR, green: &bgG, blue: &bgB, alpha: &bgA)
        
        // 计算叠加后的Alpha值
        let finalAlpha = 1 - (1 - fgA) * (1 - bgA)
        
        // 防止除以0
        guard finalAlpha > 0 else { return .clear }
        
        // 计算叠加后的RGB分量
        let computeComponent = { (fgC: CGFloat, fgA: CGFloat, bgC: CGFloat, bgA: CGFloat) -> CGFloat in
            return (fgC * fgA + bgC * bgA * (1 - fgA)) / finalAlpha
        }
        
        let finalRed = computeComponent(fgR, fgA, bgR, bgA)
        let finalGreen = computeComponent(fgG, fgA, bgG, bgA)
        let finalBlue = computeComponent(fgB, fgA, bgB, bgA)
        
        return UIColor(red: finalRed, green: finalGreen, blue: finalBlue, alpha: finalAlpha)
    }
}
