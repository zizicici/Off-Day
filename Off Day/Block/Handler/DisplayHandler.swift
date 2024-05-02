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
    
    func getStart(for section: Section) -> Int?
    func getEnd(for section: Section) -> Int?
    
    func getLeading() -> Int
    func getTrailing() -> Int
    
    func getSnapshot(customDaysDict: [Int : CustomDay]) -> NSDiffableDataSourceSnapshot<Section, Item>?
    func getCatalogueMenuElements() -> [UIMenuElement]
}
