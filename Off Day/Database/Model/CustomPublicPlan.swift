//
//  CustomPublicPlan.swift
//  Off Day
//
//  Created by zici on 10/5/24.
//

import Foundation
import GRDB
import ZCCalendar

struct CustomPublicPlan: Identifiable, Hashable {
    struct Detail: Decodable, FetchableRecord {
        var plan: CustomPublicPlan
        var days: [CustomPublicDay]
    }
    
    var id: Int64?
    
    var creationTime: Int64?
    var modificationTime: Int64?
    
    var name: String
    var start: GregorianDay
    var end: GregorianDay
}

extension CustomPublicPlan: Codable {
    enum Columns: String, ColumnExpression {
        case id
    }
    
    enum CodingKeys: String, CodingKey {
        case id, creationTime = "creation_time", modificationTime = "modification_time", name, start, end
    }
}

extension CustomPublicPlan: TableRecord {
    static var databaseTableName: String = "custom_public_plan"
}

extension CustomPublicPlan: FetchableRecord {
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

extension CustomPublicPlan: TimestampedRecord {
    
}

extension CustomPublicPlan {
    static let days = hasMany(CustomPublicDay.self).forKey("days")
    
    var days: QueryInterfaceRequest<CustomPublicDay> {
        request(for: CustomPublicPlan.days)
    }
}
