//
//  DayManager.swift
//  Off Day
//
//  Created by zici on 26/9/24.
//

import Foundation
import ZCCalendar

struct DayManager {
    static func check(_ day: GregorianDay, is type: DayType) -> Bool {
        let baseCalendarDayType: DayType = BaseCalendarManager.shared.isOff(day: day) ? .offDay : .workDay
        let publicDayType = PublicPlanManager.shared.publicDay(at: day.julianDay)?.type
        let customDayType = CustomDayManager.shared.fetchCustomDay(by: day.julianDay)?.dayType
        
        let isOffDay = isOffDay(baseCalendarDayType: baseCalendarDayType, publicDayType: publicDayType, customDayType: customDayType)
        
        switch type {
        case .offDay:
            return isOffDay
        case .workDay:
            return !isOffDay
        }
    }
    
    static func isOffDay(baseCalendarDayType: DayType, publicDayType: DayType?, customDayType: DayType?) -> Bool {
        var isOffDay = baseCalendarDayType == .offDay
        if let publicDayType = publicDayType {
            isOffDay = publicDayType == .offDay
        }
        if let customDayType = customDayType {
            isOffDay = customDayType == .offDay
        }
        
        return isOffDay
    }
    
    static func checkClashDay(_ day: GregorianDay, customMarkEnabled: Bool) -> Bool {
        let baseOffValue = BaseCalendarManager.shared.isOff(day: day)
        var publicOffValue: Bool? = nil
        if let publicDay = PublicPlanManager.shared.publicDay(at: day.julianDay) {
            publicOffValue = publicDay.type == .offDay
        }
        if customMarkEnabled {
            let customOffValue: Bool?
            if let customDay = CustomDayManager.shared.fetchCustomDay(by: day.julianDay) {
                customOffValue = customDay.dayType == .offDay
            } else {
                customOffValue = nil
            }
            if let publicOffValue = publicOffValue {
                if let customOffValue = customOffValue {
                    return !((baseOffValue == publicOffValue) && (customOffValue == baseOffValue))
                } else {
                    return publicOffValue != baseOffValue
                }
            } else {
                if let customOffValue = customOffValue {
                    return customOffValue != baseOffValue
                } else {
                    return false
                }
            }
        } else {
            if let publicOffValue = publicOffValue {
                return baseOffValue != publicOffValue
            } else {
                return false
            }
        }
    }
    
    static func getDayDetail(from day: GregorianDay) -> DayDetailEntity? {
        let baseOffValue = BaseCalendarManager.shared.isOff(day: day)
        let publicDay = PublicPlanManager.shared.publicDay(at: day.julianDay)
        let publicOffValue: Bool = publicDay?.type == .offDay
        let customOffValue: Bool? = CustomDayManager.shared.fetchCustomDay(by: day.julianDay)?.dayType == .offDay
        if let date = day.generateDate(secondsFromGMT: Calendar.current.timeZone.secondsFromGMT()) {
            let detail = DayDetailEntity(id: day.julianDay, date: date, userOffDay: customOffValue, publicOffDay: publicOffValue, baseOffDay: baseOffValue, publicDayName: publicDay?.name)
            return detail
        } else {
            return nil
        }
    }
    
    static func fetchNextDay(type: DayType, after day: GregorianDay) -> GregorianDay? {
        let dayIndex = day.julianDay
        
        for i in 1...365 {
            let newDay = GregorianDay(JDN: dayIndex + i)
            if check(newDay, is: type) {
                return newDay
            }
        }
        
        return nil
    }
}
