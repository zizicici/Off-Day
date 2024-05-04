//
//  DayInfoManager.swift
//  Off Day
//
//  Created by zici on 4/5/24.
//

import Foundation
import ZCCalendar

struct DayInfoProvider: Codable {
    let name: String
    let days: [Int: DayInfo] // julian day as Key
    let start: Int
    let end: Int
    
    enum CodingKeys: String, CodingKey {
        case name
        case days
        case start
        case end
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decode(String.self, forKey: .name)
        
        if let dayArray = try? container.decode([DayInfo].self, forKey: .days) {
            days = Dictionary(grouping: dayArray, by: { Int($0.date.julianDay) }).compactMapValues { $0.first }
        } else {
            throw DecodingError.dataCorruptedError(forKey: .start, in: container, debugDescription: "Expected to decode Array(DayInfo)")
        }
        
        if let startString = try? container.decode(String.self, forKey: .start), let startInt = Int(startString) {
            start = startInt
        } else if let startInt = try? container.decode(Int.self, forKey: .start) {
            start = startInt
        } else {
            throw DecodingError.dataCorruptedError(forKey: .start, in: container, debugDescription: "Expected to decode Int")
        }
        if let endString = try? container.decode(String.self, forKey: .end), let endInt = Int(endString) {
            end = endInt
        } else if let endInt = try? container.decode(Int.self, forKey: .end) {
            end = endInt
        } else {
            throw DecodingError.dataCorruptedError(forKey: .start, in: container, debugDescription: "Expected to decode Int")
        }
    }
}

final class DayInfoManager {
    enum PublicDayPlan: String {
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
            }
        }
    }
    
    static let shared: DayInfoManager = DayInfoManager()
    
    private var publicDayPlanProvider: DayInfoProvider?
    
    public func load() {
        load(publicDayPlan: planByUserDefault())
    }
    
    private func load(publicDayPlan: PublicDayPlan?) {
        guard let publicDayPlan = publicDayPlan else {
            publicDayPlanProvider = nil
            return
        }
        if let url = Bundle.main.url(forResource: publicDayPlan.resource, withExtension: "json"), let data = try? Data(contentsOf: url) {
            do {
                publicDayPlanProvider = try JSONDecoder().decode(DayInfoProvider.self, from: data)
            } catch {
                print("Unexpected error: \(error).")
            }
        }
    }
    
    var plan: PublicDayPlan? {
        get {
            return planByUserDefault()
        }
        set {
            guard plan != newValue else {
                return
            }
            let key = UserDefaults.Settings.PublicPlanType.rawValue
            if let value = newValue {
                UserDefaults.standard.setValue(value.rawValue, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
            load(publicDayPlan: planByUserDefault())
            NotificationCenter.default.post(name: NSNotification.Name.SettingsUpdate, object: nil)
        }
    }
    
    private func planByUserDefault() -> PublicDayPlan? {
        if let storedPlan = UserDefaults.standard.string(forKey: UserDefaults.Settings.PublicPlanType.rawValue), let plan = PublicDayPlan(rawValue: storedPlan) {
            return plan
        } else {
            return nil
        }
    }
    
    private func planForCurrentLocale() -> PublicDayPlan? {
        var targetPlan: PublicDayPlan? = nil
        let localeIdentifier = Locale.current.identifier
        if localeIdentifier.hasSuffix("CN") {
            targetPlan = .cn
        } else if localeIdentifier.hasPrefix("JP") {
            targetPlan = .jp
        }
        return targetPlan
    }
    
    public func publicDay(at julianDay: Int) -> DayInfo? {
        return publicDayPlanProvider?.days[julianDay]
    }
}
