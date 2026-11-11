//
//  BlockViewController+Menu.swift
//  Off Day
//
//  Created by zici on 2/5/24.
//

import UIKit
import MoreKit

extension BlockViewController {
    func getCalendarAppearanceMenu() -> UIMenu {
        let current = CalendarAppearanceSettings.load()
        let choices = WidgetCalendarPalette.allCases.map { palette in
            UIAction(title: palette.calendarAppearanceName,
                     identifier: UIAction.Identifier("calendar.appearance.palette.\(palette.rawValue)"),
                     state: current.palette == palette ? .on : .off) { _ in
                var updated = CalendarAppearanceSettings.load()
                updated.palette = palette
                CalendarAppearanceSettings.save(updated)
            }
        }
        var sections: [UIMenuElement] = [UIMenu(options: .displayInline, children: choices)]
        if current.palette == .classic {
            let patterns = UIAction(title: String(localized: "calendar.appearance.coloredPatterns"),
                subtitle: String(localized: "calendar.appearance.coloredPatterns.description"),
                identifier: UIAction.Identifier("calendar.appearance.coloredPatterns"),
                state: current.coloredPatterns ? .on : .off) { _ in
                    var updated = CalendarAppearanceSettings.load()
                    updated.coloredPatterns.toggle()
                    CalendarAppearanceSettings.save(updated)
                }
            sections.append(UIMenu(options: .displayInline, children: [patterns]))
        }
        sections.append(contentsOf: [getWeekEndColorMenu(), getHolidayWorkColorMenu()])
        return UIMenu(title: String(localized: "calendar.appearance.title"),
                      subtitle: current.palette.calendarAppearanceName,
                      image: UIImage(systemName: "swatchpalette"),
                      identifier: UIMenu.Identifier("calendar.appearance"), children: sections)
    }

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
        let weekEndColorTypeMenu = UIMenu(title: WeekEndColorType.getTitle(),
                                        identifier: UIMenu.Identifier("calendar.appearance.baseOffDay"),
                                        options: .displayInline, children: weekEndCOlorActions)
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
        let holidayWorkColorTypeMenu = UIMenu(title: HolidayWorkColorType.getTitle(),
                                            identifier: UIMenu.Identifier("calendar.appearance.holidayWorkday"),
                                            options: .displayInline, children: weekEndCOlorActions)
        return holidayWorkColorTypeMenu
    }
}

extension WidgetCalendarPalette {
    var calendarAppearanceName: String {
        switch self {
        case .classic: String(localized: "widget.calendar.palette.classic")
        case .mono: String(localized: "widget.calendar.palette.mono")
        }
    }
}
