//
//  BlockItem.swift
//  Off Day
//
//  Created by zici on 2023/12/26.
//

import Foundation
import ZCCalendar

struct BlockItem: Hashable {
    var index: Int
    var publicDay: PublicDay?
    var events: [Event]?
    var isToday: Bool
}

extension BlockItem {
    var day: GregorianDay {
        return GregorianDay(JDN: index)
    }
}
