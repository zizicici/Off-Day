//
//  BlockViewController+Menu.swift
//  Off Day
//
//  Created by zici on 2/5/24.
//

import UIKit
import MoreKit

extension BlockViewController {
    func getPublicPlanLanguageMenu() -> UIMenu? {
        guard let info = PublicPlanManager.shared.dataSource, !info.availableLanguages.isEmpty else { return nil }
        let languages: [String?] = [nil] + info.availableLanguages.map { Optional($0) }
        let actions = languages.map { language in
            UIAction(title: PublicPlanLanguage.title(for: language),
                     identifier: UIAction.Identifier("publicPlan.language.\(language ?? "original")"),
                     state: language == info.language ? .on : .off) { [weak self] _ in
                self?.selectPublicPlanLanguage(language)
            }
        }
        return UIMenu(title: String(localized: "publicPlan.language.title"),
                      subtitle: PublicPlanLanguage.title(for: info.language),
                      image: UIImage(systemName: "character.bubble"),
                      identifier: UIMenu.Identifier("publicPlan.language"), children: actions)
    }

    func selectPublicPlanLanguage(_ language: String?) {
        guard let info = PublicPlanManager.shared.dataSource else { return }
        let language = language.map(PublicPlanLanguage.identifier)
        if let language, !info.availableLanguages.contains(language) { return }
        PublicPlanManager.shared.select(plan: info.plan, language: language)
    }

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
