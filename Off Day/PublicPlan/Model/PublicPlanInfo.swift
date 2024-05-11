//
//  PublicPlanInfo.swift
//  Off Day
//
//  Created by zici on 10/5/24.
//

import Foundation

struct PublicPlanInfo {
    enum Plan: Equatable, Hashable {
        case app(AppPublicPlan)
        case custom(CustomPublicPlan)
    }
    
    var plan: Plan!
    var days: [Int: any PublicDay]
    
    static func generate(by detail: AppPublicPlan.Detail) -> Self? {
        if let plan = detail.plan {
            return Self.init(
                plan: .app(plan),
                days: Dictionary(
                    grouping: detail.days,
                    by: { Int($0.date.julianDay) }
                ).compactMapValues { $0.first }
            )
        } else {
            return nil
        }
    }
    
    static func generate(by detail: CustomPublicPlan.Detail) -> Self {
        return Self.init(
            plan: .custom(detail.plan),
            days: Dictionary(
                grouping: detail.days,
                by: { Int($0.date.julianDay) }
            ).compactMapValues { $0.first })
    }
    
    var name: String {
        get {
            switch plan {
            case .app(let appPublicPlan):
                return appPublicPlan.title
            case .custom(let customPublicPlan):
                return customPublicPlan.name
            case .none:
                return ""
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
            case .none:
                break
            }
        }
    }
    
    func getDuplicateCustomPlan() -> PublicPlanInfo {
        let newPlan = Plan.custom(CustomPublicPlan(name: self.name))
        
        return PublicPlanInfo(plan: newPlan, days: days.mapValues({ CustomPublicDay(name: $0.name, date: $0.date, type: $0.type) }))
    }
}
