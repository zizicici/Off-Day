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
        var appPlanDetail: AppPublicPlan.Detail?
        if let appPlanFile = UserDefaults.standard.string(forKey: UserDefaults.Settings.AppPublicPlanType.rawValue) {
            if let appPlan = AppPublicPlan(rawValue: appPlanFile) {
                appPlanDetail = AppPublicPlan.Detail(plan: appPlan)
            }
        }
        var customPlanDetail: CustomPublicPlan.Detail?
        if let customPlanId = UserDefaults.standard.getInt(forKey: UserDefaults.Settings.CustomPublicPlanType.rawValue) {
            customPlanDetail = try? fetchCustomPublicPlan(with: Int64(customPlanId))
        }
        switch (appPlanDetail != nil, customPlanDetail != nil) {
        case (true, false):
            // Use AppPlan
            dataSource = PublicPlanInfo.generate(by: appPlanDetail!)
        case (false, true):
            // Use CustomPlan
            dataSource = PublicPlanInfo.generate(by: customPlanDetail!)
        default:
            // Use NONE
            dataSource = nil
        }
    }
    
    public func publicDay(at julianDay: Int) -> (any PublicDay)? {
        return dataSource?.days[julianDay]
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
                UserDefaults.standard.setValue(appPublicPlan.rawValue, forKey: appPlanStoredKey)
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
        NotificationCenter.default.post(name: NSNotification.Name.SettingsUpdate, object: nil)
    }
}

extension PublicPlanManager {
    public func create(_ planInfo: PublicPlanInfo) -> Bool {
        if let plan = AppDatabase.shared.add(publicPlan: CustomPublicPlan(name: planInfo.name)), let planId = plan.id {
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
        case .none:
            return false
        }
    }
    
    public func delete(_ planInfo: PublicPlanInfo) -> Bool {
        switch planInfo.plan {
        case .app:
            return false
        case .custom(let customPlan):
            _ = AppDatabase.shared.delete(publicPlan: customPlan)
            return false
        case .none:
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
        if let data = try? Data(contentsOf: url) {
            do {
                let detail = try JSONDecoder().decode(AppPublicPlan.Detail.self, from: data)
                let newCustomPlan = CustomPublicPlan.Detail(plan: CustomPublicPlan(name: detail.name), days: detail.days.map({ CustomPublicDay(name: $0.name, date: $0.date, type: $0.type) }))
                let planInfo = PublicPlanInfo.generate(by: newCustomPlan)
                return create(planInfo)
            } catch {
                print("Unexpected error: \(error).")
                return false
            }
        } else {
            return false
        }
    }
}
