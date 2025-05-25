//
//  ChineseCalendarDataSource.swift
//  Off Day
//
//  Created by Ci Zi on 2025/5/25.
//

import Foundation
import ZCCalendar

enum ChineseCalendarVariant: Codable {
    case chinese
    case kyureki
}

struct ChineseCalendarDataSource: Codable {
    let name: String
    let reference: String
    let start: GregorianDay
    let end: GregorianDay
    let years: [ChineseYear]
    var variant: ChineseCalendarVariant = .chinese
    
    enum CodingKeys: CodingKey {
        case name
        case reference
        case start
        case end
        case years
    }

    func findChineseDayInfo(_ day: GregorianDay) -> ChineseDayInfo? {
        return years.findElement(containing: day)?.dayInfo(at: day, variant: variant)
    }
}

extension ChineseCalendarDataSource: GregorianDayContainerProtocol {
    func firstDay() -> Int {
        return start.julianDay
    }

    func lastDay() -> Int {
        return end.julianDay
    }
}
