//
//  BlockViewController+Layout.swift
//  Off Day
//
//  Created by zici on 2024/1/3.
//

import UIKit

extension BlockViewController {
    func getInfoSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                             heightDimension: .estimated(400))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .estimated(400))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                         subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        
        section.contentInsets = NSDirectionalEdgeInsets(top: 20.0, leading: 0, bottom: 20.0, trailing: 0)
        
        return section
    }
    
    func getDayRowSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
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
        let count: Int = DayGrid.getCount(in: containerWidth)
        section.interGroupSpacing = interSpacing
        
        let monthTagView = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(itemWidth)), elementKind: Self.monthTagElementKind, alignment: .top)
        section.boundarySupplementaryItems = [monthTagView]
        
        let inset = (containerWidth - CGFloat(count)*itemWidth - CGFloat(count - 1) * interSpacing) / 2.0
        section.contentInsets = NSDirectionalEdgeInsets(top: interSpacing / 2.0, leading: inset, bottom: interSpacing / 2.0 + 20.0, trailing: inset)
        
        return section
    }
    
    func sectionProvider(index: Int, environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? {
        let infoSectionProvider = getInfoSection()
        let dayRowSectionProvider: (NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection = getDayRowSection(environment:)
        
        if let section = dataSource.sectionIdentifier(for: index) {
            switch section {
            case .info:
                return infoSectionProvider
            case .row:
                return dayRowSectionProvider(environment)
            }
        } else {
            return nil
        }
    }
}
