//
//  DayType.swift
//  Off Day
//
//  Created by zici on 10/5/24.
//

import Foundation

enum DayType: Int, Codable {
    case offDay = 0
    case workDay
}

extension DayType {
    var title: String {
        switch self {
        case .offDay:
            return String(localized: "dayType.offDay.title")
        case .workDay:
            return String(localized: "dayType.workDay.title")
        }
    }
}
