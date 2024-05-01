//
//  Event.swift
//  Off Day
//
//  Created by zici on 2023/12/12.
//

import Foundation
import GRDB
import ZCCalendar

struct Event: Identifiable, Hashable {
    var id: Int64?
    
    var creationTime: Int64?
    var modificationTime: Int64?
    
    var dayType: DayType
    var color: String

    var comment: String?

    var start: Int64
    var end: Int64
}

extension Event {
    var isValidDate: Bool {
        return start <= end
    }
}

extension Event: Codable {
    enum CodingKeys: String, CodingKey {
        case id, creationTime = "creation_time", modificationTime = "modification_time", dayType = "day_type", color, comment, start, end
    }
}

extension Event {
    static func emptyDayEvent(day: GregorianDay) -> Self {
        return Self.init(dayType: .offday, color: "", start: Int64(day.julianDay), end: Int64(day.julianDay))
    }
}

extension Event: TableRecord {
    static var databaseTableName: String = "event"
}

extension Event {
    enum Columns: String, ColumnExpression {
        case id

        static let creationTime = Column(CodingKeys.creationTime)
        static let modificationTime = Column(CodingKeys.modificationTime)
        static let dayType = Column(CodingKeys.dayType)
    }
}

extension Event: FetchableRecord {
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

extension Event: TimestampedRecord {
    
}

extension Array<Event> {
    func sortedByStart() -> Self {
        return self.sorted(by: { lhs, rhs in
            return lhs.start < rhs.end
        })
    }
}
