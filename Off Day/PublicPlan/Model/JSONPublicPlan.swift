//
//  JSONPublicPlan.swift
//  Off Day
//
//  Created by zici on 12/5/24.
//

import Foundation
import ZCCalendar

struct JSONPublicDay: Hashable, Codable, PublicDay {
    var name: String
    var date: GregorianDay
    var type: DayType
}

struct JSONPublicPlan: Codable {
    var name: String
    var days: [JSONPublicDay]
    var start: GregorianDay
    var end: GregorianDay
    
    init(name: String, days: [JSONPublicDay], start: GregorianDay, end: GregorianDay) {
        self.name = name
        self.days = days
        self.start = start
        self.end = end
    }
    
    init(from url: URL) throws {
        let data = try Data(contentsOf: url)
        self = try JSONDecoder().decode(Self.self, from: data)
    }
    
    func jsonContent() throws -> String? {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        let jsonData = try jsonEncoder.encode(self)
        let jsonString = String(data: jsonData, encoding: .utf8)
        
        return jsonString
    }
}
