//
//  Logo.swift
//  Off Day
//
//  Created by Ci Zi on 2025/11/5.
//

import Foundation

enum Logo: Int, Hashable, CaseIterable {
    case glass = 0
    case classic
    
    var name: String {
        switch self {
        case .glass:
            return String(localized: "logo.glass.name")
        case .classic:
            return String(localized: "logo.classic.name")
        }
    }
    
    var appIcon: String? {
        switch self {
        case .glass:
            return nil
        case .classic:
            return "AppIconClassic"
        }
    }
}
