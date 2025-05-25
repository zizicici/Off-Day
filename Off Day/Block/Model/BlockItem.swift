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
    var publicDayName: String?
    var baseCalendarDayType: DayType
    var publicDayType: DayType?
    var customDayInfo: CustomDayInfo
    var backgroundColor: UIColor
    var foregroundColor: UIColor
    var isToday: Bool
    var alternativeCalendarDayName: String?
    var alternativeCalendarA11yName: String?
}

extension BlockItem {
    var day: GregorianDay {
        return GregorianDay(JDN: index)
    }
}

extension BlockItem {
    var calendarString: String {
        var suffix = ""
        if let name = PublicPlanManager.shared.dataSource?.days[day.julianDay]?.name {
            suffix = "\n\(name)"
        }
        return (day.completeFormatString() ?? "") + suffix
    }
}

extension BlockItem {
    var customDayType: DayType? {
        get {
            return customDayInfo.customDay?.dayType
        }
    }
}
