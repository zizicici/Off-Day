//
//  YearRange.swift
//  Off Day
//
//  Created by Ci Zi on 2025/5/25.
//

import Foundation
import ZCCalendar

struct YearRange {
    static let max: Int = 2099
    static let min: Int = 1900
    
    static func isAvailable(day: GregorianDay) -> Bool {
        return isAvailable(year: day.year)
    }
    
    static func isAvailable(year: Int) -> Bool {
        if year < min || year > max {
            return false
        } else {
            return true
        }
    }
}
