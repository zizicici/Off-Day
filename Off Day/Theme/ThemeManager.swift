//
//  ThemeManager.swift
//  Off Day
//
//  Created by Ci Zi on 2025/11/5.
//

import Foundation
import os
import UIKit
import MoreKit

@MainActor
class ThemeManager: NSObject {
    static let shared: ThemeManager = ThemeManager()
    private(set) var appearanceRevision = 0
    
    private(set) var logo: Logo = Logo.getValue() {
        didSet {
            if oldValue != logo {
                let logoName = logo.getName()
                UIApplication.shared.setAlternateIconName(logo.appIcon) { error in
                    if let error = error {
                        Logger.theme.error("Failed to set app icon: \(error.localizedDescription)")
                    } else {
                        Logger.theme.info("App icon changed to \(logoName)")
                    }
                }
            }
        }
    }
    
    override init() {
        super.init()
        
        updateLogo()
        updateAppearance()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateLogo), name: .SettingsUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateAppearance), name: .SettingsUpdate, object: nil)
    }
    
    @objc
    func updateLogo() {
        self.logo = Logo.getValue()
    }

    @objc
    func updateAppearance() {
        guard AppThemeStore.update(CalendarAppearanceSettings.load()) else { return }
        appearanceRevision += 1
        for scene in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }) {
            for window in scene.windows { AppTheme.apply(to: window, revision: appearanceRevision) }
        }
    }
}
