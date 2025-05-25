//
//  BlockViewController+Layout.swift
//  Off Day
//
//  Created by zici on 2024/1/3.
//

import UIKit

extension BlockViewController {
    func getDayRowSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let containerWidth = environment.container.contentSize.width

        let itemWidth = DayGrid.itemWidth(in: containerWidth)
        let interSpacing = DayGrid.interSpacing
        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(itemWidth),
                                             heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let itemHeight = DayGrid.itemHeight(in: containerWidth)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .absolute(itemHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                         subitems: [item])
        group.interItemSpacing = .fixed(interSpacing)

        let section = NSCollectionLayoutSection(group: group)
        let count: Int = DayGrid.countInRow
        section.interGroupSpacing = interSpacing
        
        let inset = (containerWidth - CGFloat(count)*itemWidth - CGFloat(count - 1) * interSpacing) / 2.0
        section.contentInsets = NSDirectionalEdgeInsets(top: interSpacing / 2.0, leading: inset, bottom: interSpacing / 2.0 + 10.0, trailing: inset)
        
        return section
    }
    
    func getMonthSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let containerWidth = environment.container.contentSize.width

        let itemWidth = DayGrid.itemWidth(in: containerWidth)
        let interSpacing = DayGrid.interSpacing
        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(itemWidth),
                                             heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .absolute(itemWidth))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                         subitems: [item])
        group.interItemSpacing = .fixed(interSpacing)

        let section = NSCollectionLayoutSection(group: group)
        let count: Int = DayGrid.countInRow
        section.interGroupSpacing = interSpacing
        
        let inset = (containerWidth - CGFloat(count)*itemWidth - CGFloat(count - 1) * interSpacing) / 2.0
        section.contentInsets = NSDirectionalEdgeInsets(top: interSpacing / 2.0 + 10.0, leading: inset, bottom: interSpacing / 2.0, trailing: inset)
        
        return section
    }
    
    func sectionProvider(index: Int, environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
        let monthSectionProvider: (NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection = getMonthSection(environment:)
        let dayRowSectionProvider: (NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection = getDayRowSection(environment:)
        
        if let section = dataSource.sectionIdentifier(for: index) {
            switch section {
            case .row:
                return dayRowSectionProvider(environment)
            case .month:
                return monthSectionProvider(environment)
            }
        } else {
            return nil
        }
    }
}
