//
//  BasicCalendarManager.swift
//  Off Day
//
//  Created by zici on 8/5/24.
//

import Foundation
import ZCCalendar

enum BasicCalendarType: Int {
    case standard = 0
    case weeksCircle
    case daysCircle
}

struct StandardConfig: Codable {
    var weekdayOrders: [WeekdayOrder]
    
    static let `default` = Self.init(weekdayOrders: [.sat, .sun])
}

enum WeekCount: Int, CaseIterable, Hashable, Equatable, Codable {
    case two = 2
    case three
    case four
    
    var title: String {
        switch self {
        case .two:
            return String(localized: "basicCalendar.weeks.2")
        case .three:
            return String(localized: "basicCalendar.weeks.3")
        case .four:
            return String(localized: "basicCalendar.weeks.4")
        }
    }
}

struct WeeksCircleConfig: Hashable, Codable {
    var offset: Int
    var weekCount: WeekCount
    var indexs: [Int]
}

struct DaysCircleConfig: Hashable, Codable {
    var start: Int
    var workCount: Int
    var offCount: Int
}

extension Notification.Name {
    static let BasicCalendarUpdate = Notification.Name(rawValue: "com.zizicici.offday.basicCalendar.updated")
}

class BasicCalendarManager {
    static let shared = BasicCalendarManager()
    
    enum Config {
        case standard(StandardConfig)
        case weeksCircle(WeeksCircleConfig)
        case daysCircle(DaysCircleConfig)
        
        var type: BasicCalendarType {
            switch self {
            case .standard:
                return .standard
            case .weeksCircle:
                return .weeksCircle
            case .daysCircle:
                return .daysCircle
            }
        }
    }
    
    static let configKey: String = UserDefaults.Settings.BasicCalendarConfig.rawValue
    static let typeKey: String = UserDefaults.Settings.BasicCalendarType.rawValue

    func getConfigType() -> BasicCalendarType {
        if let storedValue = UserDefaults.standard.getInt(forKey: Self.typeKey), let type = BasicCalendarType(rawValue: storedValue) {
            return type
        } else {
            return .standard
        }
    }
    
    func getConfig() -> Config {
        if let storedValue = UserDefaults.standard.getInt(forKey: Self.typeKey), let type = BasicCalendarType(rawValue: storedValue) {
            if let savedData = UserDefaults.standard.object(forKey: Self.configKey) as? Data {
                switch type {
                case .standard:
                    if let loadedConfig = try? JSONDecoder().decode(StandardConfig.self, from: savedData) {
                        return .standard(loadedConfig)
                    } else {
                        let result = Config.standard(StandardConfig.default)
                        save(config: result)
                        return result
                    }
                case .weeksCircle:
                    if let loadedConfig = try? JSONDecoder().decode(WeeksCircleConfig.self, from: savedData) {
                        return .weeksCircle(loadedConfig)
                    } else {
                        let result = Config.standard(StandardConfig.default)
                        save(config: result)
                        return result
                    }
                case .daysCircle:
                    if let loadedConfig = try? JSONDecoder().decode(DaysCircleConfig.self, from: savedData) {
                        return .daysCircle(loadedConfig)
                    } else {
                        let result = Config.standard(StandardConfig.default)
                        save(config: result)
                        return result
                    }
                }
            } else {
                let result = Config.standard(StandardConfig.default)
                save(config: result)
                return result
            }
        } else {
            // Translate WeekendType to Config
            switch WeekEndOffDayType.getValue() {
            case .two:
                let config: StandardConfig = StandardConfig(weekdayOrders: [.sat, .sun])
                let result: Config = .standard(config)
                save(config: result)
                return result
            case .one:
                let config: StandardConfig = StandardConfig(weekdayOrders: [.sun])
                let result: Config = .standard(config)
                save(config: result)
                return result
            case .zero:
                let config: StandardConfig = StandardConfig(weekdayOrders: [])
                let result: Config = .standard(config)
                save(config: result)
                return result
            }
        }
    }
    
    func save(config: Config) {
        var result: Bool = false
        switch config {
        case .standard(let standardConfig):
            if let encodedData = try? JSONEncoder().encode(standardConfig) {
                result = true
                UserDefaults.standard.set(encodedData, forKey: Self.configKey)
            }
        case .weeksCircle(let weeksCircleConfig):
            if let encodedData = try? JSONEncoder().encode(weeksCircleConfig) {
                result = true
                UserDefaults.standard.set(encodedData, forKey: Self.configKey)
            }
        case .daysCircle(let daysCircleConfig):
            if let encodedData = try? JSONEncoder().encode(daysCircleConfig) {
                result = true
                UserDefaults.standard.set(encodedData, forKey: Self.configKey)
            }
        }
        if result {
            UserDefaults.standard.setValue(config.type.rawValue, forKey: Self.typeKey)
            NotificationCenter.default.post(name: NSNotification.Name.SettingsUpdate, object: nil)
        }
    }
    
    func isOff(day: GregorianDay) -> Bool {
        switch getConfig() {
        case .standard(let config):
            return config.weekdayOrders.contains(day.weekdayOrder())
        case .weeksCircle(let config):
            return config.indexs.contains(day.julianDay % (7 * config.weekCount.rawValue))
        case .daysCircle(let config):
            let cycle = config.workCount + config.offCount
            var offset = (day.julianDay - config.start) % cycle
            if offset < 0 {
                offset += cycle
            }
            return offset >= config.workCount
        }
    }
}
