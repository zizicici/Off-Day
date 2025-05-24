//
//  DisplayHandler.swift
//  Off Day
//
//  Created by zici on 2024/1/4.
//

import UIKit

protocol DisplayHandlerDelegate: AnyObject {
    func reloadData()
}

protocol DisplayHandler {
    init(delegate: DisplayHandlerDelegate)
    
    func getLeading() -> Int
    func getTrailing() -> Int
    
    func getSnapshot(customDayInfoDict: [Int : CustomDayInfo]) -> NSDiffableDataSourceSnapshot<Section, Item>?
    func getCatalogueMenuElements() -> [UIMenuElement]
    func getTitle() -> String
}
