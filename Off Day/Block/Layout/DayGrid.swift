//
//  DayGrid.swift
//  Off Day
//
//  Created by zici on 2023/12/30.
//

import Foundation

struct DayGrid {
    static func itemWidth(in containerWidth: CGFloat) -> CGFloat {
        return 36.0
    }
    static let interSpacing: CGFloat = 3.0
    static let minEdgeInset: CGFloat = 12.0
    static func monthTagWidth(in containerWidth: CGFloat) -> CGFloat {
        return 50.0
    }
    
    static func maxCount(in containerWidth: CGFloat) -> Int {
        return Int(containerWidth - 2 * minEdgeInset) / Int(itemWidth(in: containerWidth) + interSpacing)
    }
    
    static func getCount(in containerWidth: CGFloat) -> Int {
        let settingsValue = 7
        let maxCount = maxCount(in: containerWidth)
        if settingsValue == 0 || settingsValue > maxCount {
            return maxCount
        } else {
            return settingsValue
        }
    }
}
