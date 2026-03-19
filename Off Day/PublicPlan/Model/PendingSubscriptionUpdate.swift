//
//  PendingSubscriptionUpdate.swift
//  Off Day
//
//  Created by zici on 8/3/26.
//

import Foundation
import ZCCalendar

struct DayChange: Codable {
    let date: GregorianDay
    let name: String
    let oldType: DayType?
    let newType: DayType?
}

struct SubscriptionDiff: Codable {
    let planId: Int64
    let planName: String
    let addedDays: [DayChange]
    let removedDays: [DayChange]
    let modifiedDays: [DayChange]

    var hasChanges: Bool {
        !addedDays.isEmpty || !removedDays.isEmpty || !modifiedDays.isEmpty
    }
}

struct PendingSubscriptionUpdate: Codable {
    let planId: Int64
    let planName: String
    let fetchTime: Int64
    let jsonPlan: JSONPublicPlan
    let diff: SubscriptionDiff
}
