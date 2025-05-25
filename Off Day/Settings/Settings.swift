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
        case AppPublicPlanType = "com.zizicici.common.settings.PublicPlanType"
        case CustomPublicPlanType = "com.zizicici.common.settings.CustomPublicPlanType"
        case WeekStartType = "com.zizicici.common.settings.WeekStartType"
        case WeekEndColorType = "com.zizicici.common.settings.WeekEndColorType"
        case WeekEndOffDayType = "com.zizicici.common.settings.WeekEndOffDayType"
        case TutorialEntranceType = "com.zizicici.common.settings.TutorialEntranceType"
        case HolidayWorkColorType = "com.zizicici.offday.settings.HolidayWorkColorType"
        case AlternativeCalendarType = "com.zizicici.common.settings.AlternativeCalendarType"
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
            return lhs.getName() == rhs.getName()
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
        NotificationCenter.default.post(name: NSNotification.Name.SettingsUpdate, object: nil)
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
        if value(forKey: key) == nil {
            return nil
        } else {
            return integer(forKey: key)
        }
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
