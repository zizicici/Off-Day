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
        let visualStyle = CalendarAppearanceSettings.load()
        
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
            snapshot.appendItems([.month(MonthItem(text: gregorianMonth.month.name, color: AppColor.text.withAlphaComponent(0.8)))])
            
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

                let palette = CalendarDayAppearance.palette(
                    baseIsOffDay: BaseCalendarManager.shared.isOff(day: gregorianDay),
                    publicIsOffDay: publicDay.map { $0.type == .offDay },
                    blueWeekends: WeekEndColorType.getValue() == .blue,
                    paperHolidayWorkdays: HolidayWorkColorType.getValue() == .paper)
                let presentation = CalendarCellPresentation(style: visualStyle, appearance: palette)
                let backgroundColor = presentation.background
                let foregroundColor = presentation.foreground
                
                var alternativeCalendarDayName: String? = nil
                var alternativeCalendarA11yName: String? = nil
                switch AlternativeCalendarType.getValue() {
                case .off:
                    break
                case .chineseCalendar:
                    let chineseDayInfo = ChineseCalendarManager.shared.findChineseDayInfo(gregorianDay, variant: .chinese)
                    if let solarTerm = ChineseCalendarManager.shared.getSolarTerm(for: gregorianDay) {
                        alternativeCalendarDayName = solarTerm.name
                        alternativeCalendarA11yName = (chineseDayInfo?.pronounceString() ?? "") + solarTerm.name
                    } else {
                        alternativeCalendarDayName = chineseDayInfo?.shortDisplayString()
                        alternativeCalendarA11yName = chineseDayInfo?.pronounceString()
                    }
                }
                
                return Item.block(BlockItem(index: julianDay, publicDayName: publicDay?.name, baseCalendarDayType: BaseCalendarManager.shared.isOff(day: gregorianDay) ? .offDay : .workDay, publicDayType: publicDay?.type, customDayInfo: customDayInfo, backgroundColor: backgroundColor, foregroundColor: foregroundColor, isToday: ZCCalendar.manager.isToday(gregorianDay: gregorianDay), alternativeCalendarDayName: alternativeCalendarDayName, alternativeCalendarA11yName: alternativeCalendarA11yName,
                    appearance: palette, visualStyle: visualStyle))
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
