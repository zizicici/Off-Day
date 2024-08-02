//
//  BlockViewController+Enum.swift
//  Off Day
//
//  Created by zici on 2024/1/4.
//

import Foundation
import ZCCalendar

enum Section: Hashable {
    case month(GregorianMonth)
    case row(GregorianMonth)
}

enum Item: Hashable {
    case month(MonthItem)
    case block(BlockItem)
    case invisible(String)
}
