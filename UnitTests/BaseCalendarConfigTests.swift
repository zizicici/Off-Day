//
//  BaseCalendarConfigTests.swift
//  UnitTests
//
//  Created by Codex on 2026/2/13.
//

import Foundation
import Testing
import GRDB
import MoreKit
import ZCCalendar
@testable import Off_Day

struct BaseCalendarConfigTests {
    @Test func baseCalendarConfigStringParsersShouldSplitValuesCorrectly() {
        let sat = WeekdayOrder.sat.rawValue
        let sun = WeekdayOrder.sun.rawValue
        let config = BaseCalendarConfig(
            type: .standard,
            standardOffday: "\(sat)/\(sun)/999",
            weekOffset: 1,
            weekCount: .two,
            weekIndexes: "0/3/8",
            dayStart: 0,
            dayWorkCount: 2,
            dayOffCount: 1
        )
        
        let weekdayOrders = config.standardWeekdayOrders()
        let weekIndexes = config.weeksCircleIndexes()
        
        #expect(weekdayOrders.contains(.sat))
        #expect(weekdayOrders.contains(.sun))
        #expect(weekdayOrders.count == 2)
        
        #expect(weekIndexes == [0, 3, 8])
    }

    @Test func defaultBaseCalendarConfigShouldUseStandardWeekendPattern() {
        let key = UserDefaults.Settings.WeekEndOffDayType.rawValue
        let userDefaults = WeekEndOffDayType.userDefaults
        let previousValue = userDefaults.object(forKey: key)
        userDefaults.removeObject(forKey: key)
        defer {
            if let previousValue {
                userDefaults.set(previousValue, forKey: key)
            } else {
                userDefaults.removeObject(forKey: key)
            }
        }

        let config = BaseCalendarConfig.makeDefault()

        #expect(config.type == .standard)
        #expect(config.standardWeekdayOrders() == [.sat, .sun])
        #expect(config.weekOffset == 0)
        #expect(config.weekCount == .two)
        #expect(config.weekIndexes.isEmpty)
        #expect(config.dayStart == 0)
        #expect(config.dayWorkCount == 1)
        #expect(config.dayOffCount == 1)
    }

    @Test func appDatabaseInitializationShouldInsertDefaultBaseCalendarConfig() throws {
        let dbQueue = try DatabaseQueue()
        _ = try AppDatabase(dbQueue)

        let config = try dbQueue.read { db in
            try BaseCalendarConfig.fetchOne(db)
        }

        #expect(config != nil)
        #expect(config?.type == .standard)
    }
    
    @Test func standardConfigComputedPropertiesShouldMatchWeekdayData() {
        let offAll = StandardConfig(weekdayOrders: [.mon, .tue, .wed, .thu, .fri, .sat, .sun])
        let offNone = StandardConfig(weekdayOrders: [])
        
        #expect(offAll.length == 7)
        #expect(offAll.hasOff)
        #expect(!offAll.hasWork)
        
        #expect(offNone.length == 7)
        #expect(!offNone.hasOff)
        #expect(offNone.hasWork)
    }
    
    @Test func circleConfigsShouldExposeLengthAndWorkOffAvailability() {
        let weeksCircle = WeeksCircleConfig(offset: 0, weekCount: .three, indexs: [0, 1, 7])
        let emptyWeeksCircle = WeeksCircleConfig(offset: 0, weekCount: .two, indexs: [])
        
        #expect(weeksCircle.length == 21)
        #expect(weeksCircle.hasOff)
        #expect(weeksCircle.hasWork)
        
        #expect(emptyWeeksCircle.length == 14)
        #expect(!emptyWeeksCircle.hasOff)
        #expect(emptyWeeksCircle.hasWork)
        
        let daysCircle = DaysCircleConfig(start: 100, workCount: 4, offCount: 2)
        let workOnly = DaysCircleConfig(start: 100, workCount: 3, offCount: 0)
        
        #expect(daysCircle.length == 6)
        #expect(daysCircle.hasOff)
        #expect(daysCircle.hasWork)
        
        #expect(workOnly.length == 3)
        #expect(!workOnly.hasOff)
        #expect(workOnly.hasWork)
    }
    
    @Test func managerConfigEnumShouldForwardComputedProperties() {
        let standard = BaseCalendarManager.Config.standard(StandardConfig(weekdayOrders: [.sat, .sun]))
        let weeks = BaseCalendarManager.Config.weeksCircle(WeeksCircleConfig(offset: 0, weekCount: .two, indexs: [0]))
        let days = BaseCalendarManager.Config.daysCircle(DaysCircleConfig(start: 0, workCount: 1, offCount: 1))
        
        #expect(standard.type == .standard)
        #expect(standard.length == 7)
        #expect(standard.hasOff)
        #expect(standard.hasWork)
        
        #expect(weeks.type == .weeksCircle)
        #expect(weeks.length == 14)
        #expect(weeks.hasOff)
        #expect(weeks.hasWork)
        
        #expect(days.type == .daysCircle)
        #expect(days.length == 2)
        #expect(days.hasOff)
        #expect(days.hasWork)
    }
}
