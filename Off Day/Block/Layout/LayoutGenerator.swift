//
//  LayoutGenerator.swift
//  Off Day
//
//  Created by zici on 2024/1/4.
//

import UIKit
import ZCCalendar

struct LayoutGenerater {
    static func dayLayout(for snapshot: inout NSDiffableDataSourceSnapshot<Section, Item>, year: Int, eventsDict: [Int : [Event]]) {
        let firstDayOfWeek: WeekdayOrder = .mon
        
        snapshot.appendSections([.topTag])
        snapshot.appendItems(rearrangeArray(startingFrom: firstDayOfWeek, in: WeekdayOrder.allCases).map({ .tag($0.getShortSymbol(), false) }), toSection: .topTag)
        
        for month in Month.allCases {
            snapshot.appendSections([.row(month.rawValue, month.getShortSymbol())])
            let firstDay = GregorianDay(year: year, month: month, day: 1)
            let firstWeekOrder = firstDay.weekdayOrder()
            let firstOffset = (firstWeekOrder.rawValue - (firstDayOfWeek.rawValue % 7) + 7) % 7
            if firstOffset >= 1 {
                snapshot.appendItems(Array(1...firstOffset).map({ index in
                    let uuid = "\(month)-\(index)"
                    return Item.invisible(uuid)
                }))
            }
            snapshot.appendItems(Array(1...ZCCalendar.manager.dayCount(at: month, year: year)).map({ day in
                let gregorianDay = GregorianDay(year: year, month: month, day: day)
                let isSpecial = false
                return Item.block(BlockItem(index: gregorianDay.julianDay, events: eventsDict[gregorianDay.julianDay], isSpecial: isSpecial, isDay: true))
            }))
        }
    }
}

extension LayoutGenerater {
    static func rearrangeArray(startingFrom value: WeekdayOrder, in array: [WeekdayOrder]) -> [WeekdayOrder] {
        guard let index = array.firstIndex(of: value) else {
            return array
        }
        let firstPart = array.suffix(from: index)
        let secondPart = array.prefix(index)
        return Array(firstPart + secondPart)
    }
}
