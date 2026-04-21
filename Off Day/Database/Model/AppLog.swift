//
//  AppLog.swift
//  Off Day
//
//  Created by zici on 20/4/26.
//

import Foundation
import GRDB

enum AppLogCategory: Int, Codable {
    case intent = 0
    case subscription = 1
}

struct AppLog: Identifiable, Hashable, Codable {
    var id: Int64?

    var creationTime: Int64
    var category: AppLogCategory
    var subtype: String
    var planId: Int64?
    var success: Bool
    var inputJSON: String?
    var outputJSON: String?
    var errorMessage: String?

    init(
        id: Int64? = nil,
        creationTime: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        category: AppLogCategory,
        subtype: String,
        planId: Int64? = nil,
        success: Bool,
        inputJSON: String? = nil,
        outputJSON: String? = nil,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.creationTime = creationTime
        self.category = category
        self.subtype = subtype
        self.planId = planId
        self.success = success
        self.inputJSON = inputJSON
        self.outputJSON = outputJSON
        self.errorMessage = errorMessage
    }

    var creationDate: Date {
        Date(timeIntervalSince1970: TimeInterval(creationTime) / 1000.0)
    }

    var displayTitle: String {
        switch category {
        case .intent:
            let localized = NSLocalizedString(subtype, comment: "")
            return localized.isEmpty ? subtype : localized
        case .subscription:
            if let event = AppLogger.SubscriptionEvent(rawValue: subtype) {
                return String(localized: event.localizationKey)
            }
            return subtype
        }
    }
}

extension AppLog {
    enum CodingKeys: String, CodingKey {
        case id
        case creationTime = "creation_time"
        case category
        case subtype
        case planId = "plan_id"
        case success
        case inputJSON = "input_json"
        case outputJSON = "output_json"
        case errorMessage = "error_message"
    }
}

extension AppLog: TableRecord {
    static var databaseTableName: String = "app_log"
}

extension AppLog {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let creationTime = Column(CodingKeys.creationTime)
        static let category = Column(CodingKeys.category)
        static let subtype = Column(CodingKeys.subtype)
        static let planId = Column(CodingKeys.planId)
        static let success = Column(CodingKeys.success)
        static let inputJSON = Column(CodingKeys.inputJSON)
        static let outputJSON = Column(CodingKeys.outputJSON)
        static let errorMessage = Column(CodingKeys.errorMessage)
    }
}

extension AppLog: FetchableRecord, MutablePersistableRecord {
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
