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
    
    func getMonthTagRegistration() -> UICollectionView.SupplementaryRegistration<CalendarTitleView> {
        let monthTagRegistration = UICollectionView.SupplementaryRegistration<CalendarTitleView>(elementKind: Self.monthTagElementKind) { [weak self] supplementaryView, elementKind, indexPath in
            guard let self = self else { return }
            guard let section = self.dataSource.sectionIdentifier(for: indexPath.section) else { fatalError("Unknown section") }
            switch section {
            case .info:
                return
            case .row(let month):
                let firstDay = GregorianDay(year: month.year, month: month.month, day: 1)
                let firstIndex = (firstDay.weekdayOrder().rawValue) % 7
                supplementaryView.update(text: month.month.getShortSymbol(), at: firstIndex, spilt: 7, color: AppColor.text.withAlphaComponent(0.8))
                return
            }
        }
        return monthTagRegistration
    }
}
