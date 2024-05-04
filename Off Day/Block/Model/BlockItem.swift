//
//  BlockItem.swift
//  Off Day
//
//  Created by zici on 2023/12/26.
//

import Foundation
import ZCCalendar
import UIKit

struct BlockItem: Hashable {
    var index: Int
    var publicDay: DayInfo?
    var customDay: CustomDay?
    var isToday: Bool
}

extension BlockItem {
    var day: GregorianDay {
        return GregorianDay(JDN: index)
    }
}

extension BlockItem {
    var calendarColor: UIColor {
        guard let dayType = publicDay?.type else {
            switch day.dayType {
            case .offday:
                return day.dayType.color
            case .workday:
                return .paper
            }
        }
        return dayType.color
    }
    
    var calendarString: String {
        var suffix = ""
        if let name = publicDay?.name {
            suffix = "\n\(name)"
        }
        return (day.completeFormatString() ?? "") + suffix
    }
    
    var calendarTextColor: UIColor {
        var result: UIColor
        switch (calendarColor.isLight, UIColor.text.isLight) {
        case (true, true):
            result = .text.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        case (false, true):
            result = .text
        case (false, false):
            result = .text.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        case (true, false):
            result = .text
        }
        return result
    }
}
