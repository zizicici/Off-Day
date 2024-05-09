//
//  BasicCalendarManager.swift
//  Off Day
//
//  Created by zici on 8/5/24.
//

import Foundation
import ZCCalendar

enum BasicCalendarType: Int, Codable {
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
        
        static func generate(by config: BasicCalendarConfig) -> Self {
            switch config.type {
            case .standard:
                return .standard(StandardConfig(weekdayOrders: config.standardWeekdayOrders()))
            case .weeksCircle:
                return .weeksCircle(WeeksCircleConfig(offset: Int(config.weekOffset), weekCount: config.weekCount, indexs: config.weeksCircleIndexs()))
            case .daysCircle:
                return .daysCircle(DaysCircleConfig(start: Int(config.dayStart), workCount: Int(config.dayWorkCount), offCount: Int(config.dayOffCount)))
            }
        }
    }
    
    private(set) var config: Config

    init() {
        if let storedConfig = BasicCalendarConfigManager.fetch() {
            config = Config.generate(by: storedConfig)
        } else {
            let standardOffday: String
            switch WeekEndOffDayType.getValue() {
            case .two:
                standardOffday = "6/7"
            case .one:
                standardOffday = "7"
            case .zero:
                standardOffday = ""
            }
            let needSaveConfig = BasicCalendarConfig(type: .standard, standardOffday: standardOffday, weekOffset: 0, weekCount: .two, weekIndexs: "", dayStart: 0, dayWorkCount: 1, dayOffCount: 1)
            BasicCalendarConfigManager.add(config: needSaveConfig)
            
            config = Config.generate(by: needSaveConfig)
        }
    }
    
    func save(config: Config) {
        guard var databaseConfig = BasicCalendarConfigManager.fetch() else {
            return
        }
        databaseConfig.type = config.type
        switch config {
        case .standard(let standardConfig):
            databaseConfig.standardOffday = standardConfig.weekdayOrders.map{ "\($0.rawValue)" }.joined(separator: "/")
        case .weeksCircle(let weeksCircleConfig):
            databaseConfig.weekCount = weeksCircleConfig.weekCount
            databaseConfig.weekOffset = Int64(weeksCircleConfig.offset)
            databaseConfig.weekIndexs = weeksCircleConfig.indexs.map{ "\($0)" }.joined(separator: "/")
        case .daysCircle(let daysCircleConfig):
            databaseConfig.dayStart = Int64(daysCircleConfig.start)
            databaseConfig.dayOffCount = Int64(daysCircleConfig.offCount)
            databaseConfig.dayWorkCount = Int64(daysCircleConfig.workCount)
        }
        self.config = Config.generate(by: databaseConfig)
        BasicCalendarConfigManager.update(config: databaseConfig)
    }
    
    func isOff(day: GregorianDay) -> Bool {
        switch config {
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

// Database
struct BasicCalendarConfigManager {
    static func fetch() -> BasicCalendarConfig? {
        var result: BasicCalendarConfig?
        do {
            try AppDatabase.shared.reader?.read{ db in
                result = try BasicCalendarConfig.fetchOne(db)
            }
        }
        catch {
            print(error)
        }
        return result
    }
    
    static func add(config: BasicCalendarConfig) {
        guard config.id == nil else {
            return
        }
        _ = AppDatabase.shared.add(basicCalendarConfig: config)
    }
    
    static func update(config: BasicCalendarConfig) {
        guard config.id != nil else {
            return
        }
        _ = AppDatabase.shared.update(basicCalendarConfig: config)
    }
}
