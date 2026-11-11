import UIKit
import SwiftUI

/// The app's semantic UI palette. Widgets resolve their own configuration through
/// the same palette definitions; they never read the app's selected appearance.
struct AppTheme {
    enum ColorRole {
        case background, paper, text, secondaryText, placeholderText
        case accent, onAccent, workDay, weekend, today
        case navigationBackground, navigationText, solidNavigationText, selection, separator
        case attention, success, warning, destructive
    }

    var style: CalendarVisualStyle
    static var current: AppTheme { AppTheme(style: AppThemeStore.current) }
    var usesPatterns: Bool { style.palette == .mono || style.usesColoredPatterns }

    func dateStyleName(backgroundAsset: String, classicName: String) -> String {
        guard usesPatterns else { return classicName }
        let colored = style.usesColoredPatterns
        let key: String
        switch CalendarDayTexture(appearance: .init(backgroundAsset: backgroundAsset, whiteText: true)) {
        case .diagonal: key = colored ? "calendar.texture.greenDiagonal" : "calendar.texture.diagonal"
        case .horizontal: key = colored ? "calendar.texture.blueHorizontal" : "calendar.texture.horizontal"
        case .dots: key = colored ? "calendar.texture.redDots" : "calendar.texture.dots"
        case .plain: key = "settings.holidayWorkColorType.paper"
        }
        return String(localized: String.LocalizationValue(key))
    }

    func colors(for traits: UITraitCollection) -> WidgetCalendarColors {
        style.palette.colors(for: traits.userInterfaceStyle == .dark ? .dark : .light,
                             coloredPatterns: style.coloredPatterns)
    }

    func color(_ role: ColorRole, for traits: UITraitCollection) -> UIColor {
        let colors = colors(for: traits)
        func ui(_ color: Color) -> UIColor { UIColor(color).resolvedColor(with: traits) }
        switch role {
        case .background: return ui(colors.background)
        case .paper: return ui(colors.paper)
        case .text: return ui(colors.text)
        case .secondaryText: return ui(colors.text).withAlphaComponent(0.75)
        case .placeholderText: return usesPatterns ? ui(colors.text).withAlphaComponent(0.45) : .placeholderText
        case .accent:
            if style.palette == .mono { return ui(colors.text) }
            return UIColor.offDay.resolvedColor(with: traits)
        case .workDay: return usesPatterns ? ui(colors.text) : UIColor.workDay.resolvedColor(with: traits)
        case .weekend: return usesPatterns ? ui(colors.text) : UIColor.weekEnd.resolvedColor(with: traits)
        case .onAccent:
            if style.palette == .mono { return ui(colors.background) }
            return style.usesColoredPatterns
                ? UIColor.text.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)) : .white
        case .today: return ui(colors.today)
        case .navigationBackground:
            if style.palette == .mono { return ui(colors.background) }
            return UIColor.navigationBar.resolvedColor(with: traits)
        case .navigationText:
            return usesPatterns ? ui(colors.text) : .white
        case .solidNavigationText:
            return style.palette == .mono ? ui(colors.text) : .white
        case .selection: return usesPatterns ? ui(colors.text).withAlphaComponent(0.12) : UIColor.systemGray4.resolvedColor(with: traits)
        case .separator: return usesPatterns ? ui(colors.text).withAlphaComponent(0.18) : UIColor.separator.resolvedColor(with: traits)
        case .attention: return style.palette == .mono ? ui(colors.text) : UIColor.systemPink.resolvedColor(with: traits)
        case .success: return style.palette == .mono ? ui(colors.text) : UIColor.systemGreen.resolvedColor(with: traits)
        case .warning: return style.palette == .mono ? ui(colors.text) : UIColor.systemOrange.resolvedColor(with: traits)
        case .destructive: return style.palette == .mono ? ui(colors.text) : UIColor.systemRed.resolvedColor(with: traits)
        }
    }

    static func dynamicColor(_ role: ColorRole) -> UIColor {
        UIColor { traits in
            if #available(iOS 17.0, *) { _ = traits[AppThemeRevisionTrait.self] }
            return current.color(role, for: traits)
        }
    }

    func statusBarStyle(for traits: UITraitCollection) -> UIStatusBarStyle {
        usesPatterns && traits.userInterfaceStyle != .dark ? .darkContent : .lightContent
    }

}

/// Read once per settings change, rather than reading UserDefaults while drawing.
enum AppThemeStore {
    private static let lock = NSLock()
    private static var value = CalendarAppearanceSettings.load()
    static var current: CalendarVisualStyle {
        lock.lock(); defer { lock.unlock() }
        return value
    }

    @discardableResult
    static func update(_ style: CalendarVisualStyle) -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard style != value else { return false }
        value = style
        return true
    }
}

@available(iOS 17.0, *)
struct AppThemeRevisionTrait: UITraitDefinition {
    static let defaultValue = 0
    static let affectsColorAppearance = true
}

@MainActor
extension AppTheme {
    static func apply(to window: UIWindow, revision: Int) {
        window.tintColor = AppColor.accent
        if #available(iOS 17.0, *) {
            window.traitOverrides[AppThemeRevisionTrait.self] = revision
        } else {
            // iOS 16 has no custom color traits. Reapply existing color bindings,
            // preserving controllers, the responder and any in-progress edits.
            refreshLegacyColors(in: window)
        }
        refreshControllers(window.rootViewController)
    }

    private static func refreshControllers(_ controller: UIViewController?) {
        guard let controller else { return }
        controller.setNeedsStatusBarAppearanceUpdate()
        if let view = controller.viewIfLoaded { refreshControls(in: view) }
        if let navigation = controller as? NavigationController {
            navigation.refreshTheme()
        }
        for child in controller.children { refreshControllers(child) }
        refreshControllers(controller.presentedViewController)
    }

    private static func refreshControls(in view: UIView) {
        if let button = view as? UIButton { button.setNeedsUpdateConfiguration() }
        for child in view.subviews { refreshControls(in: child) }
    }

    private static func refreshLegacyColors(in view: UIView) {
        let background = view.backgroundColor
        let tint = view.tintColor
        view.backgroundColor = nil; view.backgroundColor = background
        view.tintColor = nil; view.tintColor = tint
        if let label = view as? UILabel {
            let text = label.textColor
            label.textColor = .clear; label.textColor = text
        }
        if let text = view as? UITextView {
            let color = text.textColor
            text.textColor = .clear; text.textColor = color
        }
        if let field = view as? UITextField {
            let color = field.textColor
            field.textColor = .clear; field.textColor = color
        }
        if let button = view as? UIButton { button.setNeedsUpdateConfiguration() }
        view.setNeedsDisplay()
        for child in view.subviews { refreshLegacyColors(in: child) }
    }
}
