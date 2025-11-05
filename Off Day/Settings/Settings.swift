//
//  Settings.swift
//  Off Day
//
//  Created by zici on 2/5/24.
//

import Foundation
import ZCCalendar

extension UserDefaults {
    enum Settings: String {
        case AutoBackup = "com.zizicici.tag.settings.AutoBackup"
        case BackupFolder = "com.zizicici.tag.settings.BackupFolder"
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

extension Notification.Name {
    static let SettingsUpdate = Notification.Name(rawValue: "com.zizicici.common.settings.updated")
}

protocol SettingsOption: Hashable, Equatable {
    func getName() -> String
    static func getHeader() -> String?
    static func getFooter() -> String?
    static func getTitle() -> String
    static func getOptions() -> [Self]
    static var current: Self { get set}
}

extension SettingsOption {
    static func getHeader() -> String? {
        return nil
    }
    
    static func getFooter() -> String? {
        return nil
    }
}

extension SettingsOption {
    static func == (lhs: Self, rhs: Self) -> Bool {
        if type(of: lhs) != type(of: rhs) {
            return false
        } else {
            return lhs.hashValue == rhs.hashValue
        }
    }
}

protocol UserDefaultSettable: SettingsOption {
    static func getKey() -> UserDefaults.Settings
    static var defaultOption: Self { get }
}

extension UserDefaultSettable where Self: RawRepresentable, Self.RawValue == Int {
    static func getValue() -> Self {
        if let intValue = UserDefaults.standard.getInt(forKey: getKey().rawValue), let value = Self(rawValue: intValue) {
            return value
        } else {
            return defaultOption
        }
    }
    
    static func setValue(_ value: Self) {
        UserDefaults.standard.set(value.rawValue, forKey: getKey().rawValue)
        NotificationCenter.default.post(name: Notification.Name.SettingsUpdate, object: nil)
    }
    
    static func getOptions<T: CaseIterable>() -> [T] {
        return Array(T.allCases)
    }
    
    static var current: Self {
        get {
            return getValue()
        }
        set {
            setValue(newValue)
        }
    }
}

extension UserDefaults {
    func getInt(forKey key: String) -> Int? {
        return object(forKey: key) as? Int
    }
    
    func getBool(forKey key: String) -> Bool? {
        return object(forKey: key) as? Bool
    }
    
    func getString(forKey key: String) -> String? {
        return object(forKey: key) as? String
    }
}

enum AutoBackup: Int, CaseIterable, Codable {
    case enable
    case disable
}

extension AutoBackup: UserDefaultSettable {
    static func getKey() -> UserDefaults.Settings {
        return .AutoBackup
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
    static func getKey() -> UserDefaults.Settings {
        return .WeekStartType
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
    static func getKey() -> UserDefaults.Settings {
        return .WeekEndColorType
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
    static func getKey() -> UserDefaults.Settings {
        return .HolidayWorkColorType
    }
    
    static var defaultOption: HolidayWorkColorType {
        return .workDay
    }
    
    func getName() -> String {
        switch self {
        case .workDay:
            return String(localized: "settings.holidayWorkColorType.workDay")
        case .paper:
            return String(localized: "settings.holidayWorkColorType.papaer")
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
    static func getKey() -> UserDefaults.Settings {
        return .WeekEndOffDayType
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
    static func getKey() -> UserDefaults.Settings {
        .TutorialEntranceType
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
    static func getKey() -> UserDefaults.Settings {
        return .AlternativeCalendarType
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
    static func getKey() -> UserDefaults.Settings {
        return .Logo
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
