//
//  PublicPlanManager.swift
//  Off Day
//
//  Created by zici on 4/5/24.
//

import Foundation
import ZCCalendar
import GRDB

final class PublicPlanManager {
    static let shared: PublicPlanManager = PublicPlanManager()
    
    private(set) var dataSource: PublicPlanInfo?
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(load), name: .DatabaseUpdated, object: nil)
    }
    
    @objc
    public func load() {
#if DEBUG
//        for file in AppPublicPlan.File.allCases {
//            if let url = Bundle.main.url(forResource: file.resource, withExtension: "json") {
//                do {
//                    let jsonPlan = try JSONPublicPlan(from: url)
//                    print(jsonPlan.name)
//                }
//                catch {
//                    fatalError()
//                }
//            }
//        }
#endif
        
        var appPlanDetail: AppPublicPlan.Detail?
        if let appPlanFile = UserDefaults.standard.string(forKey: UserDefaults.Settings.AppPublicPlanType.rawValue) {
            if let appPlanFile = AppPublicPlan.File(rawValue: appPlanFile) {
                let appPlan = AppPublicPlan(file: appPlanFile)
                appPlanDetail = AppPublicPlan.Detail(plan: appPlan)
            }
        }
        var customPlanDetail: CustomPublicPlan.Detail?
        if let customPlanId = UserDefaults.standard.getInt(forKey: UserDefaults.Settings.CustomPublicPlanType.rawValue) {
            customPlanDetail = try? fetchCustomPublicPlan(with: Int64(customPlanId))
        }
        switch (appPlanDetail != nil, customPlanDetail != nil) {
        case (true, _):
            // Use AppPlan
            dataSource = PublicPlanInfo(detail: appPlanDetail!)
        case (false, true):
            // Use CustomPlan
            dataSource = PublicPlanInfo(detail: customPlanDetail!)
        default:
            // Use NONE
            dataSource = nil
        }
    }
    
    public func publicDay(at julianDay: Int) -> (any PublicDay)? {
        return dataSource?.days[julianDay]
    }
    
    public func fetchPublicDay(after julianDay: Int, dayType: DayType) -> (any PublicDay)? {
        guard let days = dataSource?.days else { return nil }
        for (index, day) in days {
            if index > julianDay && day.type == dayType {
                return day
            }
        }
        return nil
    }
    
    public func isOverReach(at julianDay: Int) -> Bool {
        guard let dataSource = dataSource else {
            return false
        }
        if julianDay < dataSource.start.julianDay || julianDay > dataSource.end.julianDay {
            return true
        } else {
            return false
        }
    }
    
    public func hasHolidayShift() -> Bool {
        var result: Bool = false
        if let values = dataSource?.days.values {
            for value in values {
                if value.type == .workDay {
                    result = true
                    break
                }
            }
        }
        return result
    }
    
    public func select(plan: PublicPlanInfo.Plan?) {
        guard dataSource?.plan != plan else {
            return
        }
        let appPlanStoredKey = UserDefaults.Settings.AppPublicPlanType.rawValue
        let customPlanStoredKey = UserDefaults.Settings.CustomPublicPlanType.rawValue
        if let plan = plan {
            switch plan {
            case .app(let appPublicPlan):
                UserDefaults.standard.setValue(appPublicPlan.file.rawValue, forKey: appPlanStoredKey)
                UserDefaults.standard.removeObject(forKey: customPlanStoredKey)
            case .custom(let customPublicPlan):
                UserDefaults.standard.setValue(customPublicPlan.id, forKey: customPlanStoredKey)
                UserDefaults.standard.removeObject(forKey: appPlanStoredKey)
            }
        } else {
            UserDefaults.standard.removeObject(forKey: appPlanStoredKey)
            UserDefaults.standard.removeObject(forKey: customPlanStoredKey)
        }
        load()
        NotificationCenter.default.post(name: Notification.Name.SettingsUpdate, object: nil)
    }
    
    public func getExpirationDate() -> GregorianDay? {
        return dataSource?.end
    }
    
    public func getDaysAfter(day: GregorianDay) -> [(key: Int, value: any PublicDay)] {
        guard let days = dataSource?.days else { return [] }
        let filteredAndSorted = days
            .filter { $0.key > day.julianDay }
            .sorted { $0.key < $1.key }
        
        guard !filteredAndSorted.isEmpty else { return [] }
        
        var result: [(key: Int, value: any PublicDay)] = []
        var previousDayName: String? = nil
        
        for day in filteredAndSorted {
            let currentDayName = day.value.name
            
            if currentDayName != previousDayName {
                result.append(day)
                previousDayName = currentDayName
            }
        }
        
        return result
    }
}

extension PublicPlanManager {
    public func create(_ planInfo: PublicPlanInfo) -> Bool {
        if let plan = AppDatabase.shared.add(publicPlan: CustomPublicPlan(name: planInfo.name, start: planInfo.start, end: planInfo.end)), let planId = plan.id {
            for day in planInfo.days.values.sorted(by: { $0.date.julianDay < $1.date.julianDay }) {
                if var saveDay = day as? CustomPublicDay {
                    saveDay.planId = planId
                    _ = AppDatabase.shared.add(publicDay: saveDay)
                }
            }
            return true
        } else {
            return false
        }
    }
    
    public func update(_ planInfo: PublicPlanInfo) -> Bool {
        switch planInfo.plan {
        case .app:
            return false
        case .custom(let customPlan):
            if AppDatabase.shared.update(publicPlan: customPlan), let planId = customPlan.id {
                _ = AppDatabase.shared.deleteCustomPublicDays(with: planId)
                for day in planInfo.days.values.sorted(by: { $0.date.julianDay < $1.date.julianDay }) {
                    if var saveDay = day as? CustomPublicDay {
                        saveDay.id = nil
                        saveDay.planId = planId
                        _ = AppDatabase.shared.add(publicDay: saveDay)
                    }
                }
            }
            return true
        }
    }
    
    public func delete(_ planInfo: PublicPlanInfo) -> Bool {
        switch planInfo.plan {
        case .app:
            return false
        case .custom(let customPlan):
            _ = AppDatabase.shared.delete(publicPlan: customPlan)
            return false
        }
    }
    
    public func fetchCustomPublicPlan(with id: Int64) throws -> CustomPublicPlan.Detail? {
        var result: CustomPublicPlan.Detail?
        try AppDatabase.shared.reader?.read({ db in
            do {
                result = try CustomPublicPlan
                    .filter(id: id)
                    .including(all: CustomPublicPlan.days)
                    .asRequest(of: CustomPublicPlan.Detail.self)
                    .fetchOne(db)
            }
            catch {
                print(error)
            }
        })
        
        return result
    }
    
    public func fetchAllPublicPlan() throws -> [CustomPublicPlan] {
        var result: [CustomPublicPlan] = []
        try AppDatabase.shared.reader?.read({ db in
            do {
                let idColumn = CustomPublicPlan.Columns.id
                result = try CustomPublicPlan
                    .order(idColumn)
                    .including(all: CustomPublicPlan.days)
                    .asRequest(of: CustomPublicPlan.self)
                    .fetchAll(db)
            }
            catch {
                print(error)
            }
        })
        
        return result
    }
}

extension PublicPlanManager {
    func importPlan(from url: URL) -> Bool {
        if let jsonPlan = try? JSONPublicPlan(from: url) {
            let newCustomPlan = CustomPublicPlan.Detail(plan: CustomPublicPlan(name: jsonPlan.name, start: jsonPlan.start, end: jsonPlan.end), days: jsonPlan.days.map({ CustomPublicDay(name: $0.name, date: $0.date, type: $0.type) }))
            let planInfo = PublicPlanInfo(detail: newCustomPlan)
            return create(planInfo)
        } else {
            return false
        }
    }
    
    func exportCustomPlanToFile(from customPlan: CustomPublicPlan) -> URL? {
        guard let customPlanId = customPlan.id else { return nil }

        do {
            guard let planDetail = try fetchCustomPublicPlan(with: customPlanId) else { return nil }
            let exportPlan = JSONPublicPlan(name: planDetail.plan.name, days: planDetail.days.map{ JSONPublicDay(name: $0.name, date: $0.date, type: $0.type)}, start: planDetail.plan.start, end: planDetail.plan.end)
            
            guard let jsonString = try exportPlan.jsonContent() else { return nil }
            
            let fileName = "\(exportPlan.name).json"
            let url = try saveContentToTemporary(content: jsonString, fileName: fileName)
            
            return url
        }
        catch {
            print("Error encoding JSON: \(error)")
            return nil
        }
    }
    
    func saveContentToTemporary(content: String, fileName: String) throws -> URL? {
        let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let targetURL = tempDirectoryURL.appendingPathComponent(fileName)
        try content.write(to: targetURL, atomically: true, encoding: .utf8)

        return targetURL
    }
}
