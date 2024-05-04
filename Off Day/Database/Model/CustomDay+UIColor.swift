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
            return dayType.color
        }
    }
}

extension DayType {
    var color: UIColor {
        get {
            switch self {
            case .offDay:
                return AppColor.offDay
            case .workDay:
                return AppColor.workDay
            }
        }
    }
}
