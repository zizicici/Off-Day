//
//  CustomDayManager.swift
//  Off Day
//
//  Created by zici on 2023/12/22.
//

import Foundation
import GRDB

struct CustomDayInfo: Equatable, Hashable {
    var dayIndex: Int
    var customDay: CustomDay?
    var customComment: CustomComment?
}

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
    
    func fetchAllBetween(start: Int, end: Int, completion: (([CustomDayInfo]) -> ())?) {
        AppDatabase.shared.reader?.asyncRead{ dbResult in
            do {
                let db = try dbResult.get()
                
                let dayIndexInDay = CustomDay.Columns.dayIndex
                let dayRequest = CustomDay.filter(dayIndexInDay >= start).filter(dayIndexInDay <= end).order(dayIndexInDay.asc)
                let resultDays = try dayRequest.fetchAll(db)
                
                let dayIndexInComment = CustomComment.Columns.dayIndex
                let commentRequest = CustomComment.filter(dayIndexInComment >= start).filter(dayIndexInComment <= end).order(dayIndexInComment.asc)
                let resultComments = try commentRequest.fetchAll(db)
                
                let dayDict = Dictionary(grouping: resultDays, by: { $0.dayIndex })
                let commentDict = Dictionary(grouping: resultComments, by: { $0.dayIndex })
                
                let result: [CustomDayInfo] = (start...end).compactMap { dayIndex in
                    let dayKey = dayIndex
                    
                    let day = dayDict[Int64(dayKey)]?.first
                    let comment = commentDict[Int64(dayKey)]?.first
                    
                    if day == nil && comment == nil {
                        return nil
                    } else {
                        return CustomDayInfo(dayIndex: dayKey, customDay: day, customComment: comment)
                    }
                }
                
                DispatchQueue.main.async {
                    completion?(result)
                }
            }
            catch {
                print(error)
            }
        }
    }
    
    func fetchCustomDayInfo(by dayIndex: Int) -> CustomDayInfo {
        var result: CustomDayInfo = CustomDayInfo(dayIndex: dayIndex)
        do {
            try AppDatabase.shared.reader?.read{ db in
                let dayIndexColumn = CustomDay.Columns.dayIndex
                let customDay = try CustomDay.filter(dayIndexColumn == dayIndex).fetchOne(db)
                result.customDay = customDay
                
                let commentIndexColumn = CustomComment.Columns.dayIndex
                let customComment = try CustomComment.filter(commentIndexColumn == dayIndex).fetchOne(db)
                result.customComment = customComment
            }
        }
        catch {
            print(error)
        }
        return result
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
    
    func fetchAll(after startDayIndex: Int) -> [CustomDay] {
        var result: [CustomDay] = []
        do {
            try AppDatabase.shared.reader?.read{ db in
                let dayIndexInDay = CustomDay.Columns.dayIndex
                let dayRequest = CustomDay.filter(dayIndexInDay > startDayIndex).order(dayIndexInDay.asc)
                result = try dayRequest.fetchAll(db)
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
    func fetchCustomComment(by dayIndex: Int) -> CustomComment? {
        var result: CustomComment?
        do {
            try AppDatabase.shared.reader?.read{ db in
                let commentIndexColumn = CustomComment.Columns.dayIndex
                result = try CustomComment.filter(commentIndexColumn == Int64(dayIndex)).fetchOne(db)
            }
        }
        catch {
            print(error)
        }
        return result
    }
    
    func add(customComment: CustomComment) -> Bool {
        guard customComment.id == nil else {
            return false
        }
        return AppDatabase.shared.add(customComment: customComment)
    }
    
    func update(customComment: CustomComment) -> Bool {
        guard customComment.id != nil else {
            return false
        }
        return AppDatabase.shared.update(customComment: customComment)
    }
    
    func delete(customComment: CustomComment) -> Bool {
        guard customComment.id != nil else {
            return false
        }
        return AppDatabase.shared.delete(customComment: customComment)
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
