//
//  BlockViewController+Enum.swift
//  Off Day
//
//  Created by zici on 2024/1/4.
//

import Foundation

enum Catalogue: Hashable {
    case targetYear(Int)
}

enum Section: Hashable {
    case info
    case row(Int, String)
}

enum Item: Hashable {
    case info(TitleCellItem)
    case tag(String, Bool)
    case block(BlockItem)
    case invisible(String)
}
