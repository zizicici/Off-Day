//
//  PublicPlanInfo.swift
//  Off Day
//
//  Created by zici on 10/5/24.
//

import Foundation
import ZCCalendar

struct PublicPlanInfo {
    enum Plan: Equatable, Hashable {
        case app(AppPublicPlan)
        case custom(CustomPublicPlan)
    }
    
    var plan: Plan
    var days: [Int: any PublicDay] // julian day as Key
    
    init(plan: Plan, days: [Int : any PublicDay]) {
        self.plan = plan
        self.days = days
    }
    
    init?(detail: AppPublicPlan.Detail) {
        if let plan = detail.plan {
            self.plan = .app(plan)
            self.days = Dictionary(
                grouping: detail.days,
                by: { Int($0.date.julianDay) }
            ).compactMapValues { $0.first }
        } else {
            return nil
        }
    }
    
    init(detail: CustomPublicPlan.Detail) {
        self.plan = .custom(detail.plan)
        self.days = Dictionary(
            grouping: detail.days,
            by: { Int($0.date.julianDay) }
        ).compactMapValues { $0.first }
    }
    
    var name: String {
        get {
            switch plan {
            case .app(let appPublicPlan):
                return appPublicPlan.title
            case .custom(let customPublicPlan):
                return customPublicPlan.name
            }
        }
        set {
            switch plan {
            case .app:
                break
            case .custom(let customPublicPlan):
                var plan = customPublicPlan
                plan.name = newValue
                self.plan = .custom(plan)
            }
        }
    }
    
    var start: GregorianDay {
        get {
            switch plan {
            case .app(let appPublicPlan):
                return appPublicPlan.start
            case .custom(let customPublicPlan):
                return customPublicPlan.start
            }
        }
        set {
            switch plan {
            case .app:
                break
            case .custom(let customPublicPlan):
                var plan = customPublicPlan
                plan.start = newValue
                self.plan = .custom(plan)
            }
        }
    }
    
    var end: GregorianDay {
        get {
            switch plan {
            case .app(let appPublicPlan):
                return appPublicPlan.end
            case .custom(let customPublicPlan):
                return customPublicPlan.end
            }
        }
        set {
            switch plan {
            case .app:
                break
            case .custom(let customPublicPlan):
                var plan = customPublicPlan
                plan.end = newValue
                self.plan = .custom(plan)
            }
        }
    }
    
    func getDuplicateCustomPlan() -> PublicPlanInfo {
        let newPlan = Plan.custom(CustomPublicPlan(name: self.name, start: self.start, end: self.end))
        
        return PublicPlanInfo(plan: newPlan, days: days.mapValues({ CustomPublicDay(name: $0.name, date: $0.date, type: $0.type) }))
    }
}
