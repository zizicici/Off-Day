//
//  StandardConfig.swift
//  Off Day
//
//  Created by zici on 9/5/24.
//

import Foundation
import GRDB
import ZCCalendar

struct BasicCalendarConfig: Identifiable, Hashable, MutablePersistableRecord {
    var id: Int64?
    
    var type: BasicCalendarType
    var standardOffday: String
    
    var weekOffset: Int64
    var weekCount: WeekCount
    var weekIndexs: String
    
    var dayStart: Int64
    var dayWorkCount: Int64
    var dayOffCount: Int64
}

extension BasicCalendarConfig: Codable {
    enum CodingKeys: String, CodingKey {
        case id, type, standardOffday = "standard_offday", weekOffset = "week_offset", weekCount = "week_count", weekIndexs = "week_indexs", dayStart = "day_start", dayWorkCount = "day_work_count", dayOffCount = "day_off_count"
    }
}

extension BasicCalendarConfig: TableRecord {
    static var databaseTableName: String = "basic_calendar_config"
}

extension BasicCalendarConfig: FetchableRecord {
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

extension BasicCalendarConfig {
    func standardWeekdayOrders() -> [WeekdayOrder] {
        return standardOffday.split(separator: "/").compactMap{ Int($0) }.compactMap{ WeekdayOrder(rawValue: $0) }
    }
    
    func weeksCircleIndexs() -> [Int] {
        return weekIndexs.split(separator: "/").compactMap{ Int($0) }
    }
}
