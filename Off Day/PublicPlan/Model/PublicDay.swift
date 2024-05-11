//
//  PublicDay.swift
//  Off Day
//
//  Created by zici on 11/5/24.
//

import Foundation
import ZCCalendar

protocol PublicDay: Hashable {
    var name: String { get set }
    var date: GregorianDay { get set }
    var type: DayType { get set }
}

extension PublicDay {
    func isEqual(_ otherDay: (any PublicDay)?) -> Bool {
        guard let otherDay = otherDay else {
            return false
        }
        return (date == otherDay.date) && (type == otherDay.type) && (name == otherDay.name) && Swift.type(of: self) == Swift.type(of: otherDay)
    }
}

struct AppPublicDay: Hashable, Codable, PublicDay {
    var name: String
    var date: GregorianDay
    var type: DayType
}
