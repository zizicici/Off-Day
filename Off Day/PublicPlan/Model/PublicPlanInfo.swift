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
    private var appNote: String?
    var language: String?

    var availableLanguages: [String] {
        Set(days.values.flatMap { day in
            (day.localizedNames ?? [:]).filter {
                !$0.key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }.map { PublicPlanLanguage.identifier($0.key) }
        }).sorted()
    }

    func displayDay(_ day: any PublicDay) -> JSONPublicDay {
        JSONPublicDay(name: day.localizedName(language: language), date: day.date, type: day.type)
    }
    
    init(plan: Plan, days: [Int : any PublicDay]) {
        self.plan = plan
        self.days = days
        self.language = PublicPlanLanguage.saved(for: plan)
    }
    
    init?(detail: AppPublicPlan.Detail) {
        if let plan = detail.plan {
            self.plan = .app(plan)
            self.language = PublicPlanLanguage.saved(for: .app(plan))
            self.days = Dictionary(
                grouping: detail.days,
                by: { Int($0.date.julianDay) }
            ).compactMapValues { $0.first }
            self.appNote = detail.note
        } else {
            return nil
        }
    }
    
    init(detail: CustomPublicPlan.Detail) {
        self.plan = .custom(detail.plan)
        self.language = PublicPlanLanguage.saved(for: .custom(detail.plan))
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
    
    var note: String? {
        get {
            switch plan {
            case .app:
                return appNote
            case .custom(let customPublicPlan):
                return customPublicPlan.note
            }
        }
        set {
            switch plan {
            case .app:
                break
            case .custom(let customPublicPlan):
                var plan = customPublicPlan
                plan.note = newValue
                self.plan = .custom(plan)
            }
        }
    }
    
    func getDuplicateCustomPlan() -> PublicPlanInfo {
        let newPlan = Plan.custom(CustomPublicPlan(name: self.name, start: self.start, end: self.end, note: self.note))
        
        return PublicPlanInfo(plan: newPlan, days: days.mapValues({ CustomPublicDay(name: $0.name, date: $0.date, type: $0.type, localizedNames: $0.localizedNames) }))
    }
}
