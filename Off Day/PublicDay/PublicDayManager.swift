//
//  PublicDayManager.swift
//  Off Day
//
//  Created by zici on 4/5/24.
//

import Foundation
import ZCCalendar

struct PublicDayProvider: Codable {
    var name: String
    var days: [Int: PublicDay] // julian day as Key
    
    enum CodingKeys: String, CodingKey {
        case name
        case days
    }
    
    init(name: String, days: [Int: PublicDay]) {
        self.name = name
        self.days = days
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decode(String.self, forKey: .name)
        
        if let dayArray = try? container.decode([PublicDay].self, forKey: .days) {
            days = Dictionary(grouping: dayArray, by: { Int($0.date.julianDay) }).compactMapValues { $0.first }
        } else {
            throw DecodingError.dataCorruptedError(forKey: .days, in: container, debugDescription: "Expected to decode Array(DayInfo)")
        }
    }
}

final class PublicDayManager {
    enum PublicPlan: String {
        case cn
        case cn_xj
        case cn_xz
        case cn_gx
        case cn_nx
        case hk
        case mo_public
        case mo_force
        case mo_cs
        case jp
        case sg
        case us
        case th
        case kr
        
        var resource: String {
            switch self {
            case .cn:
                return "cn-mainland"
            case .cn_xj:
                return "cn-xinjiang"
            case .cn_xz:
                return "cn-xizang"
            case .cn_gx:
                return "cn-guangxi"
            case .cn_nx:
                return "cn-ningxia"
            case .hk:
                return "hk"
            case .mo_public:
                return "mo-public"
            case .mo_force:
                return "mo-force"
            case .mo_cs:
                return "mo-civil-servant"
            case .jp:
                return "jp"
            case .sg:
                return "sg"
            case .us:
                return "us"
            case .th:
                return "th"
            case .kr:
                return "kr"
            }
        }
        
        var title: String {
            switch self {
            case .cn:
                return String(localized: "publicDay.item.cn.mainland")
            case .cn_xj:
                return String(localized: "publicDay.item.cn.xinjiang")
            case .cn_xz:
                return String(localized: "publicDay.item.cn.xizang")
            case .cn_nx:
                return String(localized: "publicDay.item.cn.ningxia")
            case .cn_gx:
                return String(localized: "publicDay.item.cn.guangxi")
            case .hk:
                return String(localized: "publicDay.item.hk")
            case .mo_public:
                return String(localized: "publicDay.item.mo.public")
            case .mo_force:
                return String(localized: "publicDay.item.mo.force")
            case .mo_cs:
                return String(localized: "publicDay.item.mo.cs")
            case .jp:
                return String(localized: "publicDay.item.jp")
            case .sg:
                return String(localized: "publicDay.item.sg")
            case .us:
                return String(localized: "publicDay.item.us")
            case .th:
                return String(localized: "publicDay.item.th")
            case .kr:
                return String(localized: "publicDay.item.kr")
            }
        }
        
        var subtitle: String {
            switch self {
            case .cn:
                return String(localized: "publicDay.item.cn.mainland.subtitle")
            case .cn_xj:
                return String(localized: "publicDay.item.cn.xinjiang.subtitle")
            case .cn_xz:
                return String(localized: "publicDay.item.cn.xizang.subtitle")
            case .cn_nx:
                return String(localized: "publicDay.item.cn.ningxia.subtitle")
            case .cn_gx:
                return String(localized: "publicDay.item.cn.guangxi.subtitle")
            case .hk:
                return String(localized: "publicDay.item.hk.subtitle")
            case .mo_public:
                return String(localized: "publicDay.item.mo.public.subtitle")
            case .mo_force:
                return String(localized: "publicDay.item.mo.force.subtitle")
            case .mo_cs:
                return String(localized: "publicDay.item.mo.cs.subtitle")
            case .jp:
                return String(localized: "publicDay.item.jp.subtitle")
            case .sg:
                return String(localized: "publicDay.item.sg.subtitle")
            case .us:
                return String(localized: "publicDay.item.us.subtitle")
            case .th:
                return String(localized: "publicDay.item.th.subtitle")
            case .kr:
                return String(localized: "publicDay.item.kr.subtitle")
            }
        }
    }
    
    static let shared: PublicDayManager = PublicDayManager()
    
    private var publicPlanProvider: PublicDayProvider?
    
    public func load() {
        load(publicPlan: planByUserDefault())
    }
    
    private func load(publicPlan: PublicPlan?) {
        guard let publicPlan = publicPlan else {
            publicPlanProvider = nil
            return
        }
        if let url = Bundle.main.url(forResource: publicPlan.resource, withExtension: "json"), let data = try? Data(contentsOf: url) {
            do {
                publicPlanProvider = try JSONDecoder().decode(PublicDayProvider.self, from: data)
            } catch {
                print("Unexpected error: \(error).")
            }
        }
    }
    
    var publicPlan: PublicPlan? {
        get {
            return planByUserDefault()
        }
        set {
            guard publicPlan != newValue else {
                return
            }
            let key = UserDefaults.Settings.PublicPlanType.rawValue
            if let value = newValue {
                UserDefaults.standard.setValue(value.rawValue, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
            load(publicPlan: planByUserDefault())
            NotificationCenter.default.post(name: NSNotification.Name.SettingsUpdate, object: nil)
        }
    }
    
    private func planByUserDefault() -> PublicPlan? {
        if let storedPlan = UserDefaults.standard.string(forKey: UserDefaults.Settings.PublicPlanType.rawValue), let plan = PublicPlan(rawValue: storedPlan) {
            return plan
        } else {
            return nil
        }
    }
    
    private func planForCurrentLocale() -> PublicPlan? {
        var targetPlan: PublicPlan? = nil
        let localeIdentifier = Locale.current.identifier
        if localeIdentifier.hasSuffix("CN") {
            targetPlan = .cn
        } else if localeIdentifier.hasPrefix("JP") {
            targetPlan = .jp
        }
        return targetPlan
    }
    
    public func publicDay(at julianDay: Int) -> PublicDay? {
        return publicPlanProvider?.days[julianDay]
    }
    
    public func hasHolidayShift() -> Bool {
        var result: Bool = false
        if let values = publicPlanProvider?.days.values {
            for value in values {
                if value.type == .workDay {
                    result = true
                    break
                }
            }
        }
        return result
    }
}
