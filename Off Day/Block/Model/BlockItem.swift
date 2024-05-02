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
    var publicDay: PublicDay?
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
        guard let dayType = publicDay?.dayType else {
            switch day.dayType {
            case .offday:
                return day.dayType.color
            case .workday:
                return .paper
            }
        }
        return dayType.color
    }
}
