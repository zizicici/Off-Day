//
//  AppPublicPlan.swift
//  Off Day
//
//  Created by zici on 11/5/24.
//

import Foundation
import ZCCalendar

enum AppPublicPlan: String {
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
    
    struct Detail {
        var plan: AppPublicPlan?
        var days: [any PublicDay]
        var name: String
        
        init?(plan: AppPublicPlan) {
            if let url = Bundle.main.url(forResource: plan.resource, withExtension: "json") {
                do {
                    let jsonPlan = try JSONPublicPlan(from: url)
                    self.name = jsonPlan.name
                    self.days = jsonPlan.days
                    self.plan = plan
                } catch {
                    print("Unexpected error: \(error).")
                    return nil
                }
            } else {
                return nil
            }
        }
    }
}
