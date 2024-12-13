//
//  BlockViewController+Menu.swift
//  Off Day
//
//  Created by zici on 2/5/24.
//

import UIKit

extension BlockViewController {
    func getWeekStartType() -> WeekStartType {
        return WeekStartType.getValue()
    }
    
    func getWeekStartTypeMenu() -> UIMenu {
        let weekStartDays: [WeekStartType] = WeekStartType.allCases
        let weekStartActions = weekStartDays.map { type in
            let action = UIAction(title: type.getName(), state: type == getWeekStartType() ? .on : .off) { _ in
                WeekStartType.setValue(type)
            }
            return action
        }
        let weekStartTypeMenu = UIMenu(title: WeekStartType.getTitle(), subtitle: getWeekStartType().getName(), image: UIImage(systemName: "calendar"), children: weekStartActions)
    
        return weekStartTypeMenu
    }
    
    func getWeekEndColorType() -> WeekEndColorType {
        return WeekEndColorType.getValue()
    }
    
    func getWeekEndColorMenu() -> UIMenu {
        let weekEndColor: [WeekEndColorType] = WeekEndColorType.allCases
        let weekEndCOlorActions = weekEndColor.map { type in
            let action = UIAction(title: type.getName(), state: type == getWeekEndColorType() ? .on : .off) { _ in
                WeekEndColorType.setValue(type)
            }
            return action
        }
        let weekEndColorTypeMenu = UIMenu(title: WeekEndColorType.getTitle(), subtitle: getWeekEndColorType().getName(), image: UIImage(systemName: "swatchpalette"), children: weekEndCOlorActions)
        return weekEndColorTypeMenu
    }
    
    func getHolidayWorkColorType() -> HolidayWorkColorType {
        return HolidayWorkColorType.getValue()
    }
    
    func getHolidayWorkColorMenu() -> UIMenu {
        let holidayWorkColor: [HolidayWorkColorType] = HolidayWorkColorType.allCases
        let weekEndCOlorActions = holidayWorkColor.map { type in
            let action = UIAction(title: type.getName(), state: type == getHolidayWorkColorType() ? .on : .off) { _ in
                HolidayWorkColorType.setValue(type)
            }
            return action
        }
        let holidayWorkColorTypeMenu = UIMenu(title: HolidayWorkColorType.getTitle(), subtitle: getHolidayWorkColorType().getName(), image: UIImage(systemName: "swatchpalette"), children: weekEndCOlorActions)
        return holidayWorkColorTypeMenu
    }
}
