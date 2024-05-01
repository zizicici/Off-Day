//
//  Event.swift
//  Off Day
//
//  Created by zici on 2023/12/12.
//

import Foundation
import GRDB
import ZCCalendar

enum DisplayPriority: Int, Hashable, Codable, CaseIterable {
    case high = 99
    case middle = 50
    case low = 1
    
    var title: String {
        switch self {
        case .high:
            String(localized: "event.priority.high")
        case .middle:
            String(localized: "event.priority.middle")
        case .low:
            String(localized: "event.priority.low")
        }
    }
}

enum DateType: Int, Hashable, Codable, CaseIterable, Comparable {
    static func < (lhs: DateType, rhs: DateType) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    case year = 0
    case month = 1
//    case week = 2
    case day = 3
//    case hour = 4
//    case minute = 5
//    case second = 6
//    case nano = 7
}

struct Event: Identifiable, Hashable {
    var id: Int64?
    
    var creationTime: Int64?
    var modificationTime: Int64?
    
    var title: String
    var color: String

    var comment: String?

    var startType: DateType
    var start: Int64
    var endType: DateType
    var end: Int64
    
    var priority: DisplayPriority?
    
    var bookId: Int64
}

extension Event {
    var startDate: EventDate {
        get {
            switch startType {
            case .year:
                return .year(Int(start))
            case .month:
                return .month(GregorianMonth.generate(by: Int(start)))
            case .day:
                let day = GregorianDay(JDN: Int(start))
                return .day(day)
            }
        }
        set {
            switch newValue {
            case .year(let year):
                start = Int64(year)
                startType = .year
            case .month(let yearMonth):
                start = Int64(yearMonth.index)
                startType = .month
            case .day(let day):
                start = Int64(day.julianDay)
                startType = .day
            }
        }
    }
    
    var endDate: EventDate {
        get {
            switch endType {
            case .year:
                return .year(Int(end))
            case .month:
                return .month(GregorianMonth.generate(by: Int(end)))
            case .day:
                return .day(GregorianDay(JDN: Int(end)))
            }
        }
        set {
            switch newValue {
            case .year(let year):
                end = Int64(year)
                endType = .year
            case .month(let yearMonth):
                end = Int64(yearMonth.index)
                endType = .month
            case .day(let day):
                end = Int64(day.julianDay)
                endType = .day
            }
        }
    }
    
    var isValidDate: Bool {
        return startDate.isValid(with: endDate)
    }
}

extension Event: Codable {
    enum CodingKeys: String, CodingKey {
        case id, creationTime = "creation_time", modificationTime = "modification_time", title, comment, startType = "start_type", start, endType = "end_type", end, bookId = "book_id", color, priority
    }
}

extension Event {
    static func emptyMonthEvent(monthIndex: Int, bookId: Int64) -> Self {
        return Self.init(title: "", color: "", startType: .month, start: Int64(monthIndex), endType: .month, end: Int64(monthIndex), bookId: bookId)
    }
    
    static func emptyDayEvent(day: GregorianDay, bookId: Int64) -> Self {
        return Self.init(title: "", color: "", startType: .day, start: Int64(day.julianDay), endType: .day, end: Int64(day.julianDay), bookId: bookId)
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
        static let title = Column(CodingKeys.title)
        static let priority = Column(CodingKeys.priority)
        static let bookId = Column(CodingKeys.bookId)
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
    func sortedByPriority() -> Self {
        return self.sorted(by: { lhs, rhs in
            guard let lPriority = lhs.priority, let rlPriority = rhs.priority else {
                return lhs.priority != nil
            }
            return lPriority.rawValue > rlPriority.rawValue
        })
    }
    
    func sortedByStart() -> Self {
        return self.sorted(by: { lhs, rhs in
            return lhs.startDate.leadingIndex(for: .day) < rhs.startDate.leadingIndex(for: .day)
        })
    }
}
