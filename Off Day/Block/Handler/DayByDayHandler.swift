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
        self.selectedYear = ZCCalendar.manager.today.year
    }
    
    func getLeading() -> Int {
        return GregorianDay(year: selectedYear, month: .jan, day: 1).julianDay
    }
    
    func getTrailing() -> Int {
        return GregorianDay(year: selectedYear, month: .dec, day: 31).julianDay
    }
    
    private var selectedYear: Int {
        didSet {
            delegate?.reloadData()
        }
    }
    
    private var anchorYear: Int!
    
    func getCatalogueMenuElements() -> [UIMenuElement] {
        var elements: [UIMenuElement] = []
        for i in -3...3 {
            let year = selectedYear + i
            let subtitle: String? = anchorYear == year ? String(localized: "calendar.title.year.current") : nil
            let action = UIAction(title: String(format: String(localized: "calendar.title.year%i"), year), subtitle: subtitle, state: selectedYear == year ? .on : .off) { [weak self] _ in
                guard let self = self else { return }
                self.updateSelectedYear(to: year)
            }
            elements.append(action)
        }
        return elements
    }
    
    func updateSelectedYear(to year: Int) {
        selectedYear = year
    }
    
    func getSnapshot(customDayInfoDict: [Int : CustomDayInfo]) -> NSDiffableDataSourceSnapshot<Section, Item>? {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        
        LayoutGenerater.dayLayout(for: &snapshot, year: selectedYear, customDayInfoDict: customDayInfoDict)
        
        return snapshot
    }
    
    func getTitle() -> String {
        let title = String(format: (String(localized: "calendar.title.year%i")), selectedYear)
        return title
    }
}
