//
//  AppConfiguration.swift
//  Off Day
//
//  Created by Ci Zi on 2025/7/10.
//

import Foundation
import GRDB

struct AppConfiguration: Codable {
    private var id = 1
    
    private var notificationAToggle: Bool? {
        didSet {
            _ = AppDatabase.shared.save(appConfig: self)
        }
    }
    var templateNanoseconds: Int64 {
        didSet {
            _ = AppDatabase.shared.save(appConfig: self)
        }
    }
    private var notificationBToggle: Bool? {
        didSet {
            _ = AppDatabase.shared.save(appConfig: self)
        }
    }
    var publicDayNanoseconds: Int64 {
        didSet {
            _ = AppDatabase.shared.save(appConfig: self)
        }
    }
    private var notificationCToggle: Bool? {
        didSet {
            _ = AppDatabase.shared.save(appConfig: self)
        }
    }
    var customDayNanoseconds: Int64 {
        didSet {
            _ = AppDatabase.shared.save(appConfig: self)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, notificationAToggle = "notification_a_toggle", templateNanoseconds = "notification_a_time", notificationBToggle = "notification_b_toggle", publicDayNanoseconds = "notification_b_time", notificationCToggle = "notification_c_toggle", customDayNanoseconds = "notification_c_time"
    }
}

extension AppConfiguration {
    var isTemplateNotificationEnabled: Bool {
        get {
            notificationAToggle ?? true
        }
        set {
            notificationAToggle = newValue
        }
    }
    
    var isPublicDayNotificationEnabled: Bool {
        get {
            notificationBToggle ?? true
        }
        set {
            notificationBToggle = newValue
        }
    }
    
    var isCustomDayNotificationEnabled: Bool {
        get {
            notificationCToggle ?? false
        }
        set {
            notificationCToggle = newValue
        }
    }
}

extension AppConfiguration {
    static let `default` = AppConfiguration(templateNanoseconds: Int64(3600 * 20 * 1000), publicDayNanoseconds: Int64(3600 * 20 * 1000), customDayNanoseconds: Int64(3600 * 20 * 1000))
}

extension AppConfiguration: TableRecord {
    static var databaseTableName: String = "app_config"
}

extension AppConfiguration: FetchableRecord, PersistableRecord {
    func willUpdate(_ db: Database, columns: Set<String>) throws {
        if try !exists(db) {
            try AppConfiguration.default.insert(db)
        }
    }
    
    static func find(_ db: Database) throws -> AppConfiguration {
        try fetchOne(db) ?? .default
    }
}

extension AppConfiguration {
    static func get() -> AppConfiguration {
        let result = try? AppDatabase.shared.reader?.read { db in
            try AppConfiguration.find(db)
        }
        return result ?? .default
    }
}
