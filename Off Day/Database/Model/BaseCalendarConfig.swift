//
//  StandardConfig.swift
//  Off Day
//
//  Created by zici on 9/5/24.
//

import Foundation
import GRDB
import ZCCalendar

struct BaseCalendarConfig: Identifiable, Hashable, MutablePersistableRecord {
    var id: Int64?
    
    var type: BaseCalendarType
    var standardOffday: String
    
    var weekOffset: Int64
    var weekCount: WeekCount
    var weekIndexes: String
    
    var dayStart: Int64
    var dayWorkCount: Int64
    var dayOffCount: Int64
}

extension BaseCalendarConfig: Codable {
    enum CodingKeys: String, CodingKey {
        case id, type, standardOffday = "standard_offday", weekOffset = "week_offset", weekCount = "week_count", weekIndexes = "week_indexs", dayStart = "day_start", dayWorkCount = "day_work_count", dayOffCount = "day_off_count"
    }
}

extension BaseCalendarConfig: TableRecord {
    static var databaseTableName: String = "basic_calendar_config"
}

extension BaseCalendarConfig: FetchableRecord {
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

extension BaseCalendarConfig {
    static func makeDefault() -> BaseCalendarConfig {
        let standardOffday: String
        switch WeekEndOffDayType.getValue() {
        case .two:
            standardOffday = "6/7"
        case .one:
            standardOffday = "7"
        case .zero:
            standardOffday = ""
        }
        return BaseCalendarConfig(
            type: .standard,
            standardOffday: standardOffday,
            weekOffset: 0,
            weekCount: .two,
            weekIndexes: "",
            dayStart: 0,
            dayWorkCount: 1,
            dayOffCount: 1
        )
    }

    func standardWeekdayOrders() -> [WeekdayOrder] {
        return standardOffday.split(separator: "/").compactMap{ Int($0) }.compactMap{ WeekdayOrder(rawValue: $0) }
    }
    
    func weeksCircleIndexes() -> [Int] {
        return weekIndexes.split(separator: "/").compactMap{ Int($0) }
    }
}
