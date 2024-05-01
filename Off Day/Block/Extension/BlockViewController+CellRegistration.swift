//
//  BlockViewController+CellRegistration.swift
//  Off Day
//
//  Created by zici on 2024/1/3.
//

import UIKit

extension BlockViewController {
    func getInfoSectionCellRegistration() -> UICollectionView.CellRegistration<TitleCell, Item> {
        let cellRegistration = UICollectionView.CellRegistration<TitleCell, Item> { [weak self] (cell, indexPath, identifier) in
            guard let self = self else { return }
            switch identifier {
            case .info(let bookCellItem):
                cell.update(with: bookCellItem)
                cell.setup(menu: self.getCatalogueMenu())
            case .block, .tag, .invisible:
                break
            }
        }
        
        return cellRegistration
    }
    
    func getBlockCellRegistration() -> UICollectionView.CellRegistration<BlockCell, Item> {
        let cellRegistration = UICollectionView.CellRegistration<BlockCell, Item> { (cell, indexPath, identifier) in
            switch identifier {
            case .info, .tag, .invisible:
                break
            case .block(let blockItem):
                cell.update(with: blockItem)
            }
        }
        return cellRegistration
    }
    
    func getMonthCellRegistration() -> UICollectionView.CellRegistration<MonthCell, Item> {
        let cellRegistration = UICollectionView.CellRegistration<MonthCell, Item> { (cell, indexPath, identifier) in
            switch identifier {
            case .info, .block, .invisible:
                break
            case .tag(let text, _):
                cell.titleLabel.text = text
            }
        }
        return cellRegistration
    }
    
    func getWeekCellRegistration() -> UICollectionView.CellRegistration<MonthCell, Item> {
        let cellRegistration = UICollectionView.CellRegistration<MonthCell, Item> { (cell, indexPath, identifier) in
            switch identifier {
            case .info, .block, .invisible:
                break
            case .tag(let weekOrder, let showSpecialColor):
                if showSpecialColor {
                    cell.setupSpecialColor()
                }
                cell.titleLabel.text = weekOrder
            }
        }
        return cellRegistration
    }
    
    func getMonthTagRegistration() -> UICollectionView.SupplementaryRegistration<MonthTagView> {
        let monthTagRegistration = UICollectionView.SupplementaryRegistration<MonthTagView>(elementKind: Self.monthTagElementKind) { [weak self] supplementaryView, elementKind, indexPath in
            guard let self = self else { return }
            guard let section = self.dataSource.sectionIdentifier(for: indexPath.section) else { fatalError("Unknown section") }
            switch section {
            case .info:
                return
            case .topTag:
                supplementaryView.titleLabel.text = ""
            case .row(_, let text):
                if indexPath.item == 0 {
                    supplementaryView.titleLabel.text = text
                } else {
                    supplementaryView.titleLabel.text = ""
                }
            }
        }
        return monthTagRegistration
    }
}
