//
//  NavigationViewController.swift
//  Off Day
//
//  Created by zici on 2023/8/15.
//

import UIKit

class NavigationController: UINavigationController {
    private var headerThemeKey: String?

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
        // Preserve each screen's navigation layout and shadow choices.
        let appearance = navigationBar.standardAppearance.copy()
        if appearance.backgroundColor != nil {
            appearance.backgroundColor = patternedHome
                ? UIColor(patternImage: CalendarNavigationPattern.image(for: traitCollection)) : AppColor.navigationBar
            // The native bar extends background images above its backdrop. A tiled color
            // follows the backdrop itself and shares the weekday view's window origin.
            appearance.backgroundImage = nil
            if patternedHome { appearance.backgroundEffect = nil }
            appearance.titleTextAttributes[.foregroundColor] = AppColor.navigationText
            appearance.largeTitleTextAttributes[.foregroundColor] = AppColor.navigationText
            navigationBar.standardAppearance = appearance
        }
        if let edge = navigationBar.scrollEdgeAppearance?.copy(),
           edge.backgroundColor != nil {
            edge.backgroundColor = appearance.backgroundColor
            edge.backgroundImage = appearance.backgroundImage
            if patternedHome { edge.backgroundEffect = nil }
            edge.titleTextAttributes[.foregroundColor] = AppColor.navigationText
            edge.largeTitleTextAttributes[.foregroundColor] = AppColor.navigationText
            navigationBar.scrollEdgeAppearance = edge
        }
        navigationBar.tintColor = navigationBar.standardAppearance.backgroundColor == nil ? AppColor.accent : AppColor.navigationText
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
