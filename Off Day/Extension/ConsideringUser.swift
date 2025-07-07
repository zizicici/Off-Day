//
//  ConsideringUser.swift
//  Off Day
//
//  Created by Ci Zi on 2025/7/7.
//

import UIKit

struct ConsideringUser {
    static var animated: Bool {
        return UIAccessibility.isReduceMotionEnabled ? false : true
    }
    
    static var pushAnimated: Bool {
        return UIAccessibility.prefersCrossFadeTransitions ? false : true
    }
    
    static var buttonShapesEnabled: Bool {
        return UIAccessibility.buttonShapesEnabled
    }
}
