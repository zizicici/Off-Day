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
    var events: [Event]?
    var isSpecial: Bool = false
    var isDay: Bool
}

extension BlockItem {
    var yearMonth: GregorianMonth {
        return GregorianMonth.generate(by: index)
    }
    
    var day: GregorianDay {
        return GregorianDay(JDN: index)
    }
}
