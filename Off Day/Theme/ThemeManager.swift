//
//  ThemeManager.swift
//  Off Day
//
//  Created by Ci Zi on 2025/11/5.
//

import Foundation
import UIKit

class ThemeManager: NSObject {
    static let shared: ThemeManager = ThemeManager()
    
    private(set) var logo: Logo = Logo.getValue() {
        didSet {
            if oldValue != logo {
                UIApplication.shared.setAlternateIconName(logo.appIcon) { error in
                    if let error = error {
                        print(error)
                    } else {
                        print("Success for \(self.logo.getName())")
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
