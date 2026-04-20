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

class ThemeManager: NSObject {
    static let shared: ThemeManager = ThemeManager()
    
    private(set) var logo: Logo = Logo.getValue() {
        didSet {
            if oldValue != logo {
                UIApplication.shared.setAlternateIconName(logo.appIcon) { error in
                    if let error = error {
                        Logger.theme.error("Failed to set app icon: \(error.localizedDescription)")
                    } else {
                        Logger.theme.info("App icon changed to \(self.logo.getName())")
                    }
                }
            }
        }
    }
    
    override init() {
        super.init()
        
        updateLogo()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateLogo), name: .SettingsUpdate, object: nil)
    }
    
    @objc
    func updateLogo() {
        self.logo = Logo.getValue()
    }
}
