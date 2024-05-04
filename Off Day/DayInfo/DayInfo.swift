//
//  DayInfo.swift
//  Off Day
//
//  Created by zici on 1/5/24.
//

import Foundation
import ZCCalendar

enum DayType: Int, Codable {
    case offday = 0
    case workday
}

struct DayInfo: Codable, Equatable, Hashable {
    let name: String
    let date: GregorianDay
    let type: DayType
}

extension GregorianDay {
    var dayType: DayType {
        return weekdayOrder().isWeekEnd ? .offday : .workday
    }
}
