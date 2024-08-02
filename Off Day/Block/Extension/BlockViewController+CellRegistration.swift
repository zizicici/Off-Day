//
//  BlockViewController+CellRegistration.swift
//  Off Day
//
//  Created by zici on 2024/1/3.
//

import UIKit
import ZCCalendar

extension BlockViewController {
    func getInfoSectionCellRegistration() -> UICollectionView.CellRegistration<TitleCell, Item> {
        let cellRegistration = UICollectionView.CellRegistration<TitleCell, Item> { [weak self] (cell, indexPath, identifier) in
            guard let self = self else { return }
            switch identifier {
            case .info(let bookCellItem):
                cell.update(with: bookCellItem)
                cell.setup(menu: self.getCatalogueMenu())
            case .block, .invisible, .month:
                break
            }
        }
        
        return cellRegistration
    }
    
    func getMonthSectionCellRegistration() -> UICollectionView.CellRegistration<MonthTitleCell, Item> {
        let cellRegistration = UICollectionView.CellRegistration<MonthTitleCell, Item> {(cell, indexPath, identifier) in
            switch identifier {
            case .info, .block, .invisible:
                break
            case .month(let monthItem):
                cell.update(with: monthItem)
            }
        }
        return cellRegistration
    }
    
    func getBlockCellRegistration() -> UICollectionView.CellRegistration<BlockCell, Item> {
        let cellRegistration = UICollectionView.CellRegistration<BlockCell, Item> { (cell, indexPath, identifier) in
            switch identifier {
            case .info, .invisible, .month:
                break
            case .block(let blockItem):
                cell.update(with: blockItem)
            }
        }
        return cellRegistration
    }
}
