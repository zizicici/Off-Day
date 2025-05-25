//
//  LayoutGenerator.swift
//  Off Day
//
//  Created by zici on 2024/1/4.
//

import UIKit
import ZCCalendar

struct LayoutGenerater {
    static func dayLayout(for snapshot: inout NSDiffableDataSourceSnapshot<Section, Item>, year: Int, customDayInfoDict: [Int : CustomDayInfo]) {
        let firstDayOfWeek: WeekdayOrder = WeekdayOrder(rawValue: WeekStartType.current.rawValue) ?? WeekdayOrder.firstDayOfWeek
        
        for month in Month.allCases {
            let firstDay = GregorianDay(year: year, month: month, day: 1)
            let firstWeekOrder = firstDay.weekdayOrder()
            
            let firstOffset = (firstWeekOrder.rawValue - (firstDayOfWeek.rawValue % 7) + 7) % 7

            let gregorianMonth = GregorianMonth(year: year, month: month)
            snapshot.appendSections([.month(gregorianMonth)])
            if firstOffset >= 1 {
                snapshot.appendItems(Array(1...firstOffset).map({ index in
                    let uuid = UUID().uuidString
                    return Item.invisible(uuid)
                }))
            }
            snapshot.appendItems([.month(MonthItem(text: gregorianMonth.month.name, color: .label.withAlphaComponent(0.8)))])
            
            snapshot.appendSections([.row(gregorianMonth)])
            if firstOffset >= 1 {
                snapshot.appendItems(Array(1...firstOffset).map({ index in
                    let uuid = "\(month)-\(index)"
                    return Item.invisible(uuid)
                }))
            }
            let items: [Item] = Array(1...ZCCalendar.manager.dayCount(at: month, year: year)).map({ day in
                let gregorianDay = GregorianDay(year: year, month: month, day: day)
                let julianDay = gregorianDay.julianDay
                let publicDay = PublicPlanManager.shared.publicDay(at: julianDay)
                let customDayInfo = customDayInfoDict[julianDay] ?? CustomDayInfo(dayIndex: julianDay)

                let backgroundColor: UIColor
                let foregroundColor: UIColor
                
                if let dayType = publicDay?.type {
                    switch dayType {
                    case .offDay:
                        backgroundColor = AppColor.offDay
                        foregroundColor = .white
                    case .workDay:
                        switch HolidayWorkColorType.getValue() {
                        case .workDay:
                            backgroundColor = AppColor.workDay
                            foregroundColor = .white
                        case .paper:
                            backgroundColor = AppColor.paper
                            foregroundColor = AppColor.text
                        }
                    }
                } else {
                    if BaseCalendarManager.shared.isOff(day: gregorianDay) {
                        backgroundColor = WeekEndColorType.getValue().getColor()
                        foregroundColor = .white
                    } else {
                        backgroundColor = AppColor.paper
                        foregroundColor = AppColor.text
                    }
                }
                
                var alternativeCalendarName: String? = nil
                switch AlternativeCalendarType.getValue() {
                case .off:
                    alternativeCalendarName = nil
                case .chineseCalendar:
                    alternativeCalendarName = ChineseCalendarManager.shared.findChineseDayInfo(gregorianDay, variant: .chinese)?.shortDisplayString()
                }
                
                return Item.block(BlockItem(index: julianDay, publicDayName: publicDay?.name, baseCalendarDayType: BaseCalendarManager.shared.isOff(day: gregorianDay) ? .offDay : .workDay, publicDayType: publicDay?.type, customDayInfo: customDayInfo, backgroundColor: backgroundColor, foregroundColor: foregroundColor, isToday: ZCCalendar.manager.isToday(gregorianDay: gregorianDay), alternativeCalendarName: alternativeCalendarName))
            })
            snapshot.appendItems(items)
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

extension WeekEndColorType {
    func getColor() -> UIColor {
        switch self {
        case .offDay:
            return AppColor.offDay
        case .blue:
            return AppColor.weekEnd
        }
    }
}
