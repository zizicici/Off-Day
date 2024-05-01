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
    var calendarDay: CalendarDay
    var publicDay: PublicDay?
    var events: [Event]?
}

extension BlockItem {
    var day: GregorianDay {
        return GregorianDay(JDN: index)
    }
}
