//
//  DayComment.swift
//  Off Day
//
//  Created by Ci Zi on 2025/5/23.
//

import Foundation
import GRDB
import ZCCalendar

struct CustomComment: Identifiable, Hashable {
    var id: Int64?
    
    var creationTime: Int64?
    var modificationTime: Int64?
    
    var dayIndex: Int64
    var content: String
}

extension CustomComment: Codable {
    enum CodingKeys: String, CodingKey {
        case id, creationTime = "creation_time", modificationTime = "modification_time", dayIndex = "day_index", content
    }
}

extension CustomComment: TableRecord {
    static var databaseTableName: String = "custom_comment"
}

extension CustomComment {
    enum Columns: String, ColumnExpression {
        case id
        case content

        static let creationTime = Column(CodingKeys.creationTime)
        static let modificationTime = Column(CodingKeys.modificationTime)
        static let dayIndex = Column(CodingKeys.dayIndex)
    }
}

extension CustomComment: FetchableRecord {
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

extension CustomComment: TimestampedRecord {
    
}

extension Array<CustomComment> {
    func sortedByStart() -> Self {
        return self.sorted(by: { lhs, rhs in
            return lhs.dayIndex < rhs.dayIndex
        })
    }
}

