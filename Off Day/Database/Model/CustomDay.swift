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
    
    var dayType: DayType
    var comment: String?
    var start: Int64
    var end: Int64
}

extension CustomDay {
    var isValidDate: Bool {
        return start <= end
    }
}

extension CustomDay: Codable {
    enum CodingKeys: String, CodingKey {
        case id, creationTime = "creation_time", modificationTime = "modification_time", dayType = "day_type", comment, start, end
    }
}

extension CustomDay {
    static func emptyDay(day: GregorianDay) -> Self {
        return Self.init(dayType: .offday, start: Int64(day.julianDay), end: Int64(day.julianDay))
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
            return lhs.start < rhs.end
        })
    }
}
