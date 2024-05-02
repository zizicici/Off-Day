//
//  CustomDay+UIColor.swift
//  Off Day
//
//  Created by zici on 2/5/24.
//

import Foundation
import UIKit

extension CustomDay {
    var color: UIColor {
        get {
            switch dayType {
            case .offday:
                return UIColor.offDay
            case .workday:
                return UIColor.workDay
            }
        }
    }
}
