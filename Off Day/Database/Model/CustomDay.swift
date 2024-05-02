//
//  CustomDay.swift
//  Off Day
//
//  Created by zici on 2023/12/12.
//

import Foundation
import GRDB
import ZCCalendar

struct CustomDay: Identifiable, Hashable {
    var id: Int64?
    
    var creationTime: Int64?
    var modificationTime: Int64?
    
    var dayIndex: Int64
    var dayType: DayType
}

extension CustomDay: Codable {
    enum CodingKeys: String, CodingKey {
        case id, creationTime = "creation_time", modificationTime = "modification_time", dayIndex = "day_index", dayType = "day_type"
    }
}

extension CustomDay {
    static func emptyDay(day: GregorianDay) -> Self {
        return Self.init(dayIndex: Int64(day.julianDay), dayType: .offday)
    }
}

extension CustomDay: TableRecord {
    static var databaseTableName: String = "custom_day"
}

extension CustomDay {
    enum Columns: String, ColumnExpression {
        case id

        static let creationTime = Column(CodingKeys.creationTime)
        static let modificationTime = Column(CodingKeys.modificationTime)
        static let dayType = Column(CodingKeys.dayType)
    }
}

extension CustomDay: FetchableRecord {
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

extension CustomDay: TimestampedRecord {
    
}

extension Array<CustomDay> {
    func sortedByStart() -> Self {
        return self.sorted(by: { lhs, rhs in
            return lhs.dayIndex < rhs.dayIndex
        })
    }
}
