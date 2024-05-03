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
        let weekStartTypeMenu = UIMenu(title: WeekStartType.getTitle(), subtitle: getWeekStartType().getName(), image: UIImage(systemName: "arrow.up.arrow.down"), children: weekStartActions)
    
        return weekStartTypeMenu
    }
}
