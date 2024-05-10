//
//  PublicPlanInfo.swift
//  Off Day
//
//  Created by zici on 10/5/24.
//

import Foundation

struct PublicPlanInfo: Codable {
    var name: String
    var days: [Int: PublicDay] // julian day as Key
    
    enum CodingKeys: String, CodingKey {
        case name
        case days
    }
    
    init(name: String, days: [Int: PublicDay]) {
        self.name = name
        self.days = days
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decode(String.self, forKey: .name)
        
        if let dayArray = try? container.decode([PublicDay].self, forKey: .days) {
            days = Dictionary(grouping: dayArray, by: { Int($0.date.julianDay) }).compactMapValues { $0.first }
        } else {
            throw DecodingError.dataCorruptedError(forKey: .days, in: container, debugDescription: "Expected to decode Array(DayInfo)")
        }
    }
}
