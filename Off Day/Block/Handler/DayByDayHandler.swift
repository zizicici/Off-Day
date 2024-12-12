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
        self.anchorYear = ZCCalendar.manager.today.year
        self.currentYear = ZCCalendar.manager.today.year
    }
    
    func getLeading() -> Int {
        return GregorianDay(year: currentYear, month: .jan, day: 1).julianDay
    }
    
    func getTrailing() -> Int {
        return GregorianDay(year: currentYear, month: .dec, day: 31).julianDay
    }
    
    private var currentYear: Int {
        didSet {
            delegate?.reloadData()
        }
    }
    
    private var anchorYear: Int!
    
    func getCatalogueMenuElements() -> [UIMenuElement] {
        var elements: [UIMenuElement] = []
        for i in -3...3 {
            let year = currentYear + i
            let action = UIAction(title: String(format: (String(localized: "calendar.title.year%i")), year), subtitle: nil, state: currentYear == year ? .on : .off) { [weak self] _ in
                guard let self = self else { return }
                self.updateCurrentYear(to: year)
            }
            elements.append(action)
        }
        return elements
    }
    
    func updateCurrentYear(to year: Int) {
        currentYear = year
    }
    
    func getSnapshot(customDaysDict: [Int : CustomDay]) -> NSDiffableDataSourceSnapshot<Section, Item>? {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        
        LayoutGenerater.dayLayout(for: &snapshot, year: currentYear, customDaysDict: customDaysDict)
        
        return snapshot
    }
    
    func getTitle() -> String {
        let title = String(format: (String(localized: "calendar.title.year%i")), currentYear)
        return title
    }
}
