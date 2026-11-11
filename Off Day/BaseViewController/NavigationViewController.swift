//
//  NavigationViewController.swift
//  Off Day
//
//  Created by zici on 2023/8/15.
//

import UIKit

class NavigationController: UINavigationController {
    private var headerThemeKey: String?
    private var usesPatternedHomeBackground = false

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if headerThemeKey != currentHeaderThemeKey { refreshTheme() }
    }

    private var currentHeaderThemeKey: String {
        let style = AppTheme.current.style
        return "\(style.palette.rawValue).\(style.coloredPatterns).\(traitCollection.userInterfaceStyle.rawValue).\(traitCollection.displayScale).\(topViewController.map(ObjectIdentifier.init).map(String.init(describing:)) ?? "none")"
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshTheme()
    }

    func refreshTheme() {
        headerThemeKey = currentHeaderThemeKey
        let patternedHome = topViewController is BlockViewController && AppTheme.current.style.usesColoredPatterns
        // UIKit may normalize a clear appearance background to nil. Remember when
        // that transparency belongs to our header so leaving it restores the bar.
        let updatesHomeBackground = patternedHome || usesPatternedHomeBackground
        usesPatternedHomeBackground = patternedHome
        // Preserve each screen's navigation layout and shadow choices.
        let appearance = navigationBar.standardAppearance.copy()
        if appearance.backgroundColor != nil || updatesHomeBackground {
            appearance.backgroundColor = patternedHome
                ? .clear : AppColor.navigationBar
            // The home view draws one continuous texture behind both header bars.
            // Keep UIKit from starting a separate pattern at the bar's own origin.
            appearance.backgroundImage = nil
            if patternedHome { appearance.backgroundEffect = nil }
            appearance.titleTextAttributes[.foregroundColor] = AppColor.navigationText
            appearance.largeTitleTextAttributes[.foregroundColor] = AppColor.navigationText
            navigationBar.standardAppearance = appearance
        }
        if let edge = navigationBar.scrollEdgeAppearance?.copy(),
           edge.backgroundColor != nil || updatesHomeBackground {
            edge.backgroundColor = appearance.backgroundColor
            edge.backgroundImage = appearance.backgroundImage
            if patternedHome { edge.backgroundEffect = nil }
            edge.titleTextAttributes[.foregroundColor] = AppColor.navigationText
            edge.largeTitleTextAttributes[.foregroundColor] = AppColor.navigationText
            navigationBar.scrollEdgeAppearance = edge
        }
        navigationBar.tintColor = patternedHome || navigationBar.standardAppearance.backgroundColor != nil
            ? AppColor.navigationText : AppColor.accent
        setNeedsStatusBarAppearanceUpdate()
    }
    @available(iOS 27.1, *)
    override var preferredVerticalBarBehavior: UIVerticalBarBehavior {
        .disabled
    }

    @available(iOS 27.1, *)
    override var childForPreferredVerticalBarBehavior: UIViewController? {
        nil
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return children.first?.preferredStatusBarStyle ?? super.preferredStatusBarStyle
    }
    
    override var prefersStatusBarHidden: Bool {
        return children.first?.prefersStatusBarHidden ?? super.prefersStatusBarHidden
    }
}
