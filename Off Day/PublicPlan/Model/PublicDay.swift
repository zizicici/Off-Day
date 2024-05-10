//
//  PublicDay.swift
//  Off Day
//
//  Created by zici on 1/5/24.
//

import Foundation
import ZCCalendar

enum DayType: Int, Codable {
    case offDay = 0
    case workDay
    
    var title: String {
        switch self {
        case .offDay:
            return String(localized: "dayType.offDay.title")
        case .workDay:
            return String(localized: "dayType.workDay.title")
        }
    }
}

struct PublicDay: Codable, Equatable, Hashable {
    var name: String
    var date: GregorianDay
    var type: DayType
}

extension PublicDay {
    func allowSave() -> Bool {
        if name.count == 0 {
            return false
        } else {
            return true
        }
    }
}
