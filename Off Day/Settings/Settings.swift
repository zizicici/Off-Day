//
//  Settings.swift
//  Off Day
//
//  Created by zici on 2/5/24.
//

import Foundation
import MoreKit
import ZCCalendar

extension UserDefaults {
    enum Settings: String {
        case AutoBackup = "com.zizicici.tag.settings.AutoBackup" // Mistake, Don't change
        case BackupFolder = "com.zizicici.tag.settings.BackupFolder" // Mistake, Don't change
        case AppPublicPlanType = "com.zizicici.common.settings.PublicPlanType"
        case CustomPublicPlanType = "com.zizicici.common.settings.CustomPublicPlanType"
        case WeekStartType = "com.zizicici.common.settings.WeekStartType"
        case WeekEndColorType = "com.zizicici.common.settings.WeekEndColorType"
        case WeekEndOffDayType = "com.zizicici.common.settings.WeekEndOffDayType"
        case TutorialEntranceType = "com.zizicici.common.settings.TutorialEntranceType"
        case HolidayWorkColorType = "com.zizicici.common.settings.HolidayWorkColorType"
        case AlternativeCalendarType = "com.zizicici.common.settings.AlternativeCalendarType"
        // Notification
        case NotificationTemplateExpiry = "com.zizicici.common.settings.NotificationTemplateExpiry"
        case NotificationPublicHolidayStart = "com.zizicici.common.settings.NotificationPublicHolidayStart"
        case NotificationCustomDayStart = "com.zizicici.common.settings.NotificationCustomDayStart"
        // Theme
        case Logo = "com.zizicici.common.settings.Logo"
    }
}

enum AutoBackup: Int, CaseIterable, Codable {
    case enable
    case disable
}

extension AutoBackup: UserDefaultSettable {
    static func getKey() -> String {
        return UserDefaults.Settings.AutoBackup.rawValue
    }

    static var defaultOption: AutoBackup {
        return .disable
    }

    func getName() -> String {
        return ""
    }

    static func getTitle() -> String {
        return ""
    }
}

enum WeekStartType: Int, CaseIterable, Codable {
    case followSystem = 0
    case mon = 1
    case tue
    case wed
    case thu
    case fri
    case sat
    case sun
}

extension WeekStartType: UserDefaultSettable {
    static func getKey() -> String {
        return UserDefaults.Settings.WeekStartType.rawValue
    }

    static var defaultOption: WeekStartType {
        return .followSystem
    }

    func getName() -> String {
        switch self {
        case .followSystem:
            return String(localized: "settings.weekStartType.followSystem")
        default:
            return (WeekdayOrder(rawValue: rawValue) ?? .mon).getShortSymbol()
        }
    }

    static func getTitle() -> String {
        return String(localized: "settings.weekStartType.title")
    }

    static func getHeader() -> String? {
        return nil
    }

    static func getFooter() -> String? {
        return nil
    }
}

enum WeekEndColorType: Int, CaseIterable, Codable {
    case offDay = 0
    case blue
}

extension WeekEndColorType: UserDefaultSettable {
    static func getKey() -> String {
        return UserDefaults.Settings.WeekEndColorType.rawValue
    }

    static var defaultOption: WeekEndColorType {
        return .offDay
    }

    func getName() -> String {
        switch self {
        case .offDay:
            return String(localized: "settings.weekEndColorType.offDay")
        case .blue:
            return String(localized: "settings.weekEndColorType.blue")
        }
    }

    static func getTitle() -> String {
        return String(localized: "settings.weekEndColorType.title")
    }
}

enum HolidayWorkColorType: Int, CaseIterable {
    case workDay
    case paper
}

extension HolidayWorkColorType: UserDefaultSettable {
    static func getKey() -> String {
        return UserDefaults.Settings.HolidayWorkColorType.rawValue
    }

    static var defaultOption: HolidayWorkColorType {
        return .workDay
    }

    func getName() -> String {
        switch self {
        case .workDay:
            return String(localized: "settings.holidayWorkColorType.workDay")
        case .paper:
            return String(localized: "settings.holidayWorkColorType.paper")
        }
    }

    static func getTitle() -> String {
        return String(localized: "settings.holidayWorkColorType.title")
    }
}

enum WeekEndOffDayType: Int, CaseIterable, Codable {
    case two = 0
    case one
    case zero
}

extension WeekEndOffDayType: UserDefaultSettable {
    static func getKey() -> String {
        return UserDefaults.Settings.WeekEndOffDayType.rawValue
    }

    static var defaultOption: WeekEndOffDayType {
        return .two
    }

    func getName() -> String {
        switch self {
        case .two:
            return String(localized: "settings.weekEndOffDayType.two")
        case .one:
            return String(localized: "settings.weekEndOffDayType.one")
        case .zero:
            return String(localized: "settings.weekEndOffDayType.zero")
        }
    }

    static func getTitle() -> String {
        return String(localized: "settings.weekEndOffDayType.title")
    }

    static func getFooter() -> String? {
        return String(localized: "settings.weekEndOffDayType.footer")
    }
}

enum TutorialEntranceType: Int, CaseIterable, Codable {
    case firstTab = 0
    case secondTab
    case hidden
}

extension TutorialEntranceType: UserDefaultSettable {
    static func getKey() -> String {
        UserDefaults.Settings.TutorialEntranceType.rawValue
    }

    static var defaultOption: TutorialEntranceType {
        return .firstTab
    }

    func getName() -> String {
        switch self {
        case .firstTab:
            return String(localized: "settings.tutorialEntranceType.first")
        case .secondTab:
            return String(localized: "settings.tutorialEntranceType.second")
        case .hidden:
            return String(localized: "settings.tutorialEntranceType.hidden")
        }
    }

    static func getTitle() -> String {
        return String(localized: "settings.tutorialEntranceType.title")
    }
}

enum AlternativeCalendarType: Int, CaseIterable, Codable {
    case off = 0
    case chineseCalendar
}

extension AlternativeCalendarType: UserDefaultSettable {
    static func getKey() -> String {
        return UserDefaults.Settings.AlternativeCalendarType.rawValue
    }

    static var defaultOption: AlternativeCalendarType {
        if Language.type() == .zh {
            return .chineseCalendar
        } else {
            return .off
        }
    }

    func getName() -> String {
        switch self {
        case .off:
            return String(localized: "settings.alternativeCalendarType.off")
        case .chineseCalendar:
            return String(localized: "settings.alternativeCalendarType.chineseCalendar")
        }
    }

    static func getTitle() -> String {
        return String(localized: "settings.alternativeCalendarType.title")
    }

    static func getFooter() -> String? {
        return String(localized: "settings.alternativeCalendarType.footer")
    }
}

extension Logo: UserDefaultSettable {
    static func getKey() -> String {
        return UserDefaults.Settings.Logo.rawValue
    }

    static var defaultOption: Self {
        return .glass
    }

    func getName() -> String {
        return name
    }

    static func getTitle() -> String {
        return String(localized: "settings.logo.title")
    }

    static func getFooter() -> String? {
        return String(localized: "settings.logo.footer")
    }
}
