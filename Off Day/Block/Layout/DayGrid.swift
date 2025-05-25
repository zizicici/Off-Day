//
//  DayGrid.swift
//  Off Day
//
//  Created by zici on 2023/12/30.
//

import Foundation

struct DayGrid {
    static let countInRow: Int = 7
    
    static func itemWidth(in containerWidth: CGFloat) -> CGFloat {
        if containerWidth <= 320 {
            return 40.0
        } else {
            return 44.0
        }
    }
    
    static func itemHeight(in containerWidth: CGFloat) -> CGFloat {
        switch AlternativeCalendarType.getValue() {
        case .off:
            return itemWidth(in: containerWidth)
        case .chineseCalendar:
            return itemWidth(in: containerWidth) + 8.0
        }
    }
    
    static let interSpacing: CGFloat = 4.0
}
