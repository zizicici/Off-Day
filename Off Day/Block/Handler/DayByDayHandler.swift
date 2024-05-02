//
//  DayByDayViewController.swift
//  Off Day
//
//  Created by zici on 2023/12/30.
//

import UIKit
import ZCCalendar

class DayDisplayHandler: DisplayHandler {
    weak var delegate: DisplayHandlerDelegate?
    
    required init(delegate: DisplayHandlerDelegate) {
        self.delegate = delegate
        self.anchorYear = 2024
        self.currentCatalogue = .targetYear(2024)
    }
    
    func getStart(for section: Section) -> Int? {
        switch section {
        case .info, .topTag:
            switch currentCatalogue {
            case .targetYear(let year):
                return GregorianDay(year: year, month: .jan, day: 1).julianDay
            }
        case .row(let int, _):
            switch currentCatalogue {
            case .targetYear(let year):
                return GregorianDay(year: year, month: Month(rawValue: int) ?? .jan, day: 1).julianDay
            }
        }
    }
    
    func getEnd(for section: Section) -> Int? {
        switch section {
        case .info, .topTag:
            return nil
        case .row(let int, _):
            switch currentCatalogue {
            case .targetYear(let year):
                return GregorianDay(year: year, month: Month(rawValue: int) ?? .dec, day: 31).julianDay
            }
        }
    }
    
    func getLeading() -> Int {
        return GregorianDay(year: currentYear, month: .jan, day: 1).julianDay
    }
    
    func getTrailing() -> Int {
        return GregorianDay(year: currentYear, month: .dec, day: 31).julianDay
    }
    
    private var currentCatalogue: Catalogue {
        didSet {
            delegate?.reloadData()
        }
    }
    
    private var anchorYear: Int!
    private var currentYear: Int {
        switch currentCatalogue {
        case .targetYear(let year):
            return year
        }
    }
    
    func getCatalogueMenuElements() -> [UIMenuElement] {
        let anchorAction = UIAction(title: "\(anchorYear + 0)", subtitle: String(localized: "calendar.preferred.year"), state: currentYear == anchorYear ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            self.updateCurrentYear(to: self.anchorYear)
        }
        var dividerChildren: [UIMenuElement] = []
        let previousYearAction = UIAction(title: "\(currentYear - 1)", subtitle: String(localized: "calendar.previous.year"), image: UIImage(systemName: "arrow.up")) { [weak self] _ in
            guard let self = self else { return }
            self.updateCurrentYear(to: self.currentYear - 1)
        }
        dividerChildren.append(previousYearAction)
        if currentYear != anchorYear {
            let currentYearAction = UIAction(title: "\(currentYear + 0)", state: .on) { _ in
                // Do nothing
            }
            dividerChildren.append(currentYearAction)
        }
        let nextYearAction = UIAction(title: "\(currentYear + 1)", subtitle: String(localized: "calendar.next.year"), image: UIImage(systemName: "arrow.down")) { [weak self] _ in
            guard let self = self else { return }
            self.updateCurrentYear(to: self.currentYear + 1)
        }
        dividerChildren.append(nextYearAction)
        let divider = UIMenu(title: "", options: .displayInline, children: dividerChildren)
        
        return [anchorAction, divider]
    }
    
    func updateCurrentYear(to year: Int) {
        currentCatalogue = .targetYear(year)
    }
    
    func getSnapshot(customDaysDict: [Int : CustomDay]) -> NSDiffableDataSourceSnapshot<Section, Item>? {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        
        snapshot.appendSections([.info])
        snapshot.appendItems([.info(TitleInfoCellItem(catalogue: .targetYear(currentYear)))])
        
        LayoutGenerater.dayLayout(for: &snapshot, year: currentYear, customDaysDict: customDaysDict)
        
        return snapshot
    }
}
