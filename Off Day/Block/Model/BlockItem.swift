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
    var backgroundColor: UIColor
    var foregroundColor: UIColor
    var isToday: Bool
}

extension BlockItem {
    var day: GregorianDay {
        return GregorianDay(JDN: index)
    }
}

extension BlockItem {
    var calendarString: String {
        var suffix = ""
        if let name = publicDay?.name {
            suffix = "\n\(name)"
        }
        return (day.completeFormatString() ?? "") + suffix
    }
}
