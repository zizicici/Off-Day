//
//  BlockViewController+Enum.swift
//  Off Day
//
//  Created by zici on 2024/1/4.
//

import Foundation
import ZCCalendar

enum Catalogue: Hashable {
    case targetYear(Int)
}

enum Section: Hashable {
    case info
    case month(GregorianMonth)
    case row(GregorianMonth)
}

enum Item: Hashable {
    case info(TitleCellItem)
    case month(MonthItem)
    case block(BlockItem)
    case invisible(String)
}
