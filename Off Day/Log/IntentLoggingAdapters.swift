//
//  IntentLoggingAdapters.swift
//  Off Day
//
//  Created by zici on 20/4/26.
//

import Foundation
import AppIntents

extension AppIntent {
    static var titleLogKey: String {
        "\(Self.title.key)"
    }
}

struct DayDetailLog: Encodable {
    let id: Int
    let date: Date
    let finalOffDay: Bool
    let userOffDay: Bool?
    let publicOffDay: Bool?
    let baseOffDay: Bool
    let publicDayName: String?
    let userComment: String?

    init(_ entity: DayDetailEntity) {
        self.id = entity.id
        self.date = entity.date
        self.finalOffDay = entity.finalOffDay
        self.userOffDay = entity.userOffDay
        self.publicOffDay = entity.publicOffDay
        self.baseOffDay = entity.baseOffDay
        self.publicDayName = entity.publicDayName
        self.userComment = entity.userComment
    }
}
