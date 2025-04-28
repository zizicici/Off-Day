//
//  CustomDayManager.swift
//  Off Day
//
//  Created by zici on 2023/12/22.
//

import Foundation
import GRDB

struct CustomDayManager {
    static let shared: CustomDayManager = CustomDayManager()
    
    func fetchAll(completion: (([CustomDay]) -> ())?) {
        AppDatabase.shared.reader?.asyncRead{ dbResult in
            do {
                let db = try dbResult.get()
                let customDays = try CustomDay.fetchAll(db)
                DispatchQueue.main.async {
                    completion?(customDays)
                }
            }
            catch {
                print(error)
            }
        }
    }
    
    func fetchAllBetween(start: Int, end: Int, completion: (([CustomDay]) -> ())?) {
        AppDatabase.shared.reader?.asyncRead{ dbResult in
            do {
                let db = try dbResult.get()
                let dayIndex = CustomDay.Columns.dayIndex
                let request = CustomDay.filter(dayIndex >= start).filter(dayIndex <= end).order(dayIndex.asc)
                let resultDays = try request.fetchAll(db)
                DispatchQueue.main.async {
                    completion?(resultDays)
                }
            }
            catch {
                print(error)
            }
        }
    }
    
    func fetchCustomDay(by dayIndex: Int) -> CustomDay? {
        var result: CustomDay?
        do {
            try AppDatabase.shared.reader?.read{ db in
                let dayIndexColumn = CustomDay.Columns.dayIndex
                result = try CustomDay.filter(dayIndexColumn == Int64(dayIndex)).fetchOne(db)
            }
        }
        catch {
            print(error)
        }
        return result
    }
    
    func fetchCustomDay(after dayIndex: Int, dayType: DayType) -> CustomDay? {
        var result: CustomDay?
        do {
            try AppDatabase.shared.reader?.read{ db in
                let dayIndexColumn = CustomDay.Columns.dayIndex
                let dayTypeColumn = CustomDay.Columns.dayType
                result = try CustomDay.filter(dayIndexColumn > Int64(dayIndex)).filter(dayTypeColumn == dayType).fetchOne(db)
            }
        }
        catch {
            print(error)
        }
        return result
    }
    
    func add(customDay: CustomDay) {
        // Check is there a same CustomDay before save
        guard customDay.id == nil else {
            return
        }
        _ = AppDatabase.shared.add(customDay: customDay)
    }
    
    func update(customDay: CustomDay) {
        guard customDay.id != nil else {
            return
        }
        _ = AppDatabase.shared.update(customDay: customDay)
    }
    
    func delete(customDay: CustomDay) {
        guard customDay.id != nil else {
            return
        }
        _ = AppDatabase.shared.delete(customDay: customDay)
    }
    
    func add(dayType: DayType, from startJulianDay: Int, to endJulianDay: Int) {
        _ = AppDatabase.shared.batchAddCustomDay(dayType: dayType, from: startJulianDay, to: endJulianDay)
    }
    
    func delete(from startJulianDay: Int, to endJulianDay: Int) {
        _ = AppDatabase.shared.batchDeleteCustomDay(from: startJulianDay, to: endJulianDay)
    }
}

extension CustomDayManager {
    func update(dayType: DayType?, to julianDay: Int) {
        if let dayType = dayType {
            if var customDay = CustomDayManager.shared.fetchCustomDay(by: julianDay) {
                if customDay.dayType != dayType{
                    customDay.dayType = dayType
                    CustomDayManager.shared.update(customDay: customDay)
                }
            } else {
                let customDay = CustomDay(dayIndex: Int64(julianDay), dayType: dayType)
                CustomDayManager.shared.add(customDay: customDay)
            }
        } else {
            if let customDay = CustomDayManager.shared.fetchCustomDay(by: julianDay) {
                CustomDayManager.shared.delete(customDay: customDay)
            } else {
                //
            }
        }
    }
    
    func update(dayType: DayType?, from startJulianDay: Int, to endJulianDay: Int) {
        delete(from: startJulianDay, to: endJulianDay)
        if let dayType = dayType {
            add(dayType: dayType, from: startJulianDay, to: endJulianDay)
        }
    }
}
