//
//  DayInfo.swift
//  Off Day
//
//  Created by zici on 1/5/24.
//

import Foundation
import ZCCalendar

enum DayType: Int, Codable {
    case offDay = 0
    case workDay
}

struct DayInfo: Codable, Equatable, Hashable {
    let name: String
    let date: GregorianDay
    let type: DayType
}
