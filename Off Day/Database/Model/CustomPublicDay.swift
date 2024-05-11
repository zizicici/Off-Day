//
//  CustomPublicDay.swift
//  Off Day
//
//  Created by zici on 1/5/24.
//

import Foundation
import GRDB
import ZCCalendar

struct CustomPublicDay: PublicDay, Identifiable, Codable, Equatable, Hashable {
    var id: Int64?

    var name: String
    var date: GregorianDay
    var type: DayType
    
    var planId: Int64 = -1
    
    init(name: String, date: GregorianDay, type: DayType) {
        self.name = name
        self.date = date
        self.type = type
    }
    
    enum Columns: String, ColumnExpression {
        case id

        static let planId = Column(CodingKeys.planId)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, date, type, planId = "plan_id"
    }
}

extension CustomPublicDay: TableRecord {
    static var databaseTableName: String = "custom_public_day"
}

extension CustomPublicDay: FetchableRecord {
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

extension CustomPublicDay: MutablePersistableRecord {
    
}

extension CustomPublicDay {
    static let plan = belongsTo(CustomPublicPlan.self)
    
    var plan: QueryInterfaceRequest<CustomPublicPlan> {
        request(for: CustomPublicDay.plan)
    }
}

extension CustomPublicDay {
    func allowSave() -> Bool {
        if name.count == 0 {
            return false
        } else {
            return true
        }
    }
}
