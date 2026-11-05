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
    var localizedNames: [String: String]? = nil

    private enum CodingKeys: String, CodingKey {
        case name, date, type, localizedNames
    }

    private enum LegacyCodingKeys: String, CodingKey {
        case names
    }
}

extension JSONPublicDay {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        date = try PublicPlanDateDecoder.decode(from: container, forKey: .date)
        type = try container.decode(DayType.self, forKey: .type)
        if container.contains(.localizedNames) {
            localizedNames = try container.decodeIfPresent([String: String].self, forKey: .localizedNames)
        } else {
            let legacy = try decoder.container(keyedBy: LegacyCodingKeys.self)
            localizedNames = try legacy.decodeIfPresent([String: String].self, forKey: .names)
        }
    }
}

struct JSONPublicPlan: Codable {
    var name: String
    var days: [JSONPublicDay]
    var start: GregorianDay
    var end: GregorianDay
    var note: String?

    private enum CodingKeys: String, CodingKey {
        case name, days, start, end, note
    }
    
    init(name: String, days: [JSONPublicDay], start: GregorianDay, end: GregorianDay, note: String? = nil) {
        self.name = name
        self.days = days
        self.start = start
        self.end = end
        self.note = note
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

extension JSONPublicPlan {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        start = try PublicPlanDateDecoder.decode(from: container, forKey: .start)
        end = try PublicPlanDateDecoder.decode(from: container, forKey: .end)
        days = try container.decode([JSONPublicDay].self, forKey: .days)
        note = try container.decodeIfPresent(String.self, forKey: .note)
    }
}

private enum PublicPlanDateDecoder {
    static func decode<Key: CodingKey>(from container: KeyedDecodingContainer<Key>, forKey key: Key) throws -> GregorianDay {
        let text = try container.decode(String.self, forKey: key)
        let parts = text.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3,
              let year = Int(parts[0]), (1...9999).contains(year),
              let monthValue = Int(parts[1]), let month = Month(rawValue: monthValue),
              let day = Int(parts[2]), isValidDay(day, month: month, year: year) else {
            throw DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: "Expected a valid calendar date with a year from 1 to 9999.")
        }
        // Keep the existing decoder after validation; it also accepts legacy unpadded dates.
        return try container.decode(GregorianDay.self, forKey: key)
    }

    private static func isValidDay(_ day: Int, month: Month, year: Int) -> Bool {
        // The calendar cutover removes dates, not October's highest day number.
        let maximumDay = month == .oct ? 31 : Manager.dayCount(at: month, year: year)
        let isSkippedDate = year == 1582 && month == .oct && (5...14).contains(day)
        return (1...maximumDay).contains(day) && !isSkippedDate
    }
}
