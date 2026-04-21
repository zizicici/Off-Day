//
//  AppDatabase.swift
//  Off Day
//
//  Created by zici on 2023/11/25.
//

import Foundation
import os
import GRDB
import MoreKit

extension Notification.Name {
    static let DatabaseUpdated = Notification.Name(rawValue: "com.zizicici.common.database.updated")
}

private let logger = Logger.database

final class AppDatabase {
    init(_ dbWriter: any DatabaseWriter) throws {
        self.dbWriter = dbWriter
        try migrator.migrate(dbWriter)
    }
    
    private(set) var dbWriter: (any DatabaseWriter)?

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
#if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
#endif
        migrator.registerMigration("create_custom_day") { db in
            try db.create(table: "custom_day") { table in
                table.autoIncrementedPrimaryKey("id")
                
                table.column("creation_time", .integer).notNull()
                table.column("modification_time", .integer).notNull()
                table.column("day_index", .integer).notNull()
                table.column("day_type", .integer).notNull()
            }
        }
        migrator.registerMigration("create_basic_calendar_config") { db in
            try db.create(table: "basic_calendar_config") { table in
                table.autoIncrementedPrimaryKey("id")
                
                table.column("type", .integer).notNull()
                
                table.column("standard_offday", .text).notNull()
                
                table.column("week_offset", .integer).notNull()
                table.column("week_count", .integer).notNull()
                table.column("week_indexs", .text).notNull()
                
                table.column("day_start", .integer).notNull()
                table.column("day_work_count", .integer).notNull()
                table.column("day_off_count", .integer).notNull()
            }
        }
        migrator.registerMigration("create_custom_public_plan") { db in
            try db.create(table: "custom_public_plan") { table in
                table.autoIncrementedPrimaryKey("id")
                
                table.column("creation_time", .integer).notNull()
                table.column("modification_time", .integer).notNull()
                
                table.column("name", .text).notNull()
                table.column("start", .integer).notNull()
                table.column("end", .integer).notNull()
            }
            try db.create(table: "custom_public_day") { table in
                table.autoIncrementedPrimaryKey("id")
                
                table.column("name", .text).notNull()
                table.column("date", .text).notNull()
                table.column("type", .integer).notNull()
                
                table.column("plan_id", .integer).notNull()
                    .indexed()
                    .references("custom_public_plan", onDelete: .cascade)
            }
        }
        migrator.registerMigration("update_custom_day_index") { db in
            try db.create(indexOn: "custom_day", columns: ["day_index"], options: .ifNotExists)
        }
        migrator.registerMigration("add_comment_for_day") { db in
            try db.create(table: "custom_comment") { table in
                table.autoIncrementedPrimaryKey("id")
                
                table.column("creation_time", .integer).notNull()
                table.column("modification_time", .integer).notNull()
                table.column("day_index", .integer).notNull()
                table.column("content", .text).notNull()
            }
        }
        migrator.registerMigration("add_app_config") { db in
            try db.create(table: "app_config") { table in
                table.primaryKey("id", .integer, onConflict: .replace)
                        .check { $0 == 1 }
                table.column("notification_a_toggle", .boolean)
                table.column("notification_a_time", .integer).notNull()
                table.column("notification_b_toggle", .boolean)
                table.column("notification_b_time", .integer).notNull()
                table.column("notification_c_toggle", .boolean)
                table.column("notification_c_time", .integer).notNull()
            }
        }
        
        migrator.registerMigration("add_subscription_and_note_fields") { db in
            try db.alter(table: "custom_public_plan") { table in
                table.add(column: "source_url", .text)
                table.add(column: "last_refresh_time", .integer)
                table.add(column: "is_paused", .boolean).defaults(to: false)
                table.add(column: "note", .text)
            }
        }

        migrator.registerMigration("create_app_log") { db in
            try db.create(table: "app_log") { table in
                table.autoIncrementedPrimaryKey("id")

                table.column("creation_time", .integer).notNull().indexed()
                table.column("category", .integer).notNull()
                table.column("subtype", .text).notNull()
                table.column("plan_id", .integer)
                table.column("success", .boolean).notNull()
                table.column("input_json", .text)
                table.column("output_json", .text)
                table.column("error_message", .text)
            }
        }

        return migrator
    }
    
    public func disconnect() {
        self.dbWriter = nil
    }
    
    public func reconnect() {
        do {
            let databasePool = try AppDatabase.generateDatabasePool()
            try migrator.migrate(databasePool)
            self.dbWriter = databasePool
        } catch {
            logger.error("\(error.localizedDescription)")
        }
    }
}

extension AppDatabase {
    func add(customDay: CustomDay) -> Bool {
        guard customDay.id == nil else {
            return false
        }
        do {
            try dbWriter?.write{ db in
                var saveCustomDay = customDay
                try saveCustomDay.save(db)
            }
        }
        catch {
            logger.error("\(error.localizedDescription)")
            return false
        }
        NotificationCenter.default.post(name: Notification.Name.DatabaseUpdated, object: nil)
        return true
    }
    
    func update(customDay: CustomDay) -> Bool {
        guard customDay.id != nil else {
            return false
        }
        do {
            _ = try dbWriter?.write{ db in
                var saveCustomDay = customDay
                try saveCustomDay.updateWithTimestamp(db)
            }
        }
        catch {
            logger.error("\(error.localizedDescription)")
            return false
        }
        NotificationCenter.default.post(name: Notification.Name.DatabaseUpdated, object: nil)
        return true
    }
    
    func delete(customDay: CustomDay) -> Bool {
        guard let customDayId = customDay.id else {
            return false
        }
        do {
            _ = try dbWriter?.write{ db in
                try CustomDay.deleteAll(db, ids: [customDayId])
            }
        }
        catch {
            logger.error("\(error.localizedDescription)")
            return false
        }
        NotificationCenter.default.post(name: Notification.Name.DatabaseUpdated, object: nil)
        return true
    }
    
    func batchDeleteCustomDay(from startJulianDay: Int, to endJulianDay: Int) -> Bool {
        guard startJulianDay <= endJulianDay else {
            return false
        }
        do {
            _ = try dbWriter?.write{ db in
                let dayIndex = CustomDay.Columns.dayIndex
                let request = CustomDay.filter(dayIndex >= startJulianDay).filter(dayIndex <= endJulianDay)
                try request.deleteAll(db)
            }
        }
        catch {
            logger.error("\(error.localizedDescription)")
            return false
        }
        NotificationCenter.default.post(name: Notification.Name.DatabaseUpdated, object: nil)
        return true
    }
    
    func batchAddCustomDay(dayType: DayType, from startJulianDay: Int, to endJulianDay: Int) -> Bool {
        guard startJulianDay <= endJulianDay else {
            return false
        }
        do {
            _ = try dbWriter?.write{ db in
                for index in startJulianDay...endJulianDay {
                    var saveCustomDay = CustomDay(dayIndex: Int64(index), dayType: dayType)
                    try saveCustomDay.save(db)
                }
            }
        }
        catch {
            logger.error("\(error.localizedDescription)")
            return false
        }
        NotificationCenter.default.post(name: Notification.Name.DatabaseUpdated, object: nil)
        return true
    }
}

extension AppDatabase {
    func add(customComment: CustomComment) -> Bool {
        guard customComment.id == nil else {
            return false
        }
        do {
            try dbWriter?.write{ db in
                var saveCustomComment = customComment
                try saveCustomComment.save(db)
            }
        }
        catch {
            logger.error("\(error.localizedDescription)")
            return false
        }
        NotificationCenter.default.post(name: Notification.Name.DatabaseUpdated, object: nil)
        return true
    }
    
    func update(customComment: CustomComment) -> Bool {
        guard customComment.id != nil else {
            return false
        }
        do {
            _ = try dbWriter?.write{ db in
                var saveCustomComment = customComment
                try saveCustomComment.updateWithTimestamp(db)
            }
        }
        catch {
            logger.error("\(error.localizedDescription)")
            return false
        }
        NotificationCenter.default.post(name: Notification.Name.DatabaseUpdated, object: nil)
        return true
    }
    
    func delete(customComment: CustomComment) -> Bool {
        guard let customCommentId = customComment.id else {
            return false
        }
        do {
            _ = try dbWriter?.write{ db in
                try CustomComment.deleteAll(db, ids: [customCommentId])
            }
        }
        catch {
            logger.error("\(error.localizedDescription)")
            return false
        }
        NotificationCenter.default.post(name: Notification.Name.DatabaseUpdated, object: nil)
        return true
    }
}

extension AppDatabase {
    func add(baseCalendarConfig: BaseCalendarConfig) -> Bool {
        guard baseCalendarConfig.id == nil else {
            return false
        }
        do {
            _ = try dbWriter?.write{ db in
                var config = baseCalendarConfig
                try config.save(db)
            }
        }
        catch {
            logger.error("\(error.localizedDescription)")
            return false
        }
        NotificationCenter.default.post(name: Notification.Name.DatabaseUpdated, object: nil)
        return true
    }
    
    func update(baseCalendarConfig: BaseCalendarConfig) -> Bool {
        guard baseCalendarConfig.id != nil else {
            return false
        }
        do {
            _ = try dbWriter?.write{ db in
                try baseCalendarConfig.update(db)
            }
        }
        catch {
            logger.error("\(error.localizedDescription)")
            return false
        }
        NotificationCenter.default.post(name: Notification.Name.DatabaseUpdated, object: nil)
        return true
    }
}

extension AppDatabase {
    func add(publicPlan: CustomPublicPlan) -> CustomPublicPlan? {
        guard publicPlan.id == nil else {
            return nil
        }
        var savePublicPlan = publicPlan
        do {
            try dbWriter?.write{ db in
                try savePublicPlan.save(db)
            }
        }
        catch {
            logger.error("\(error.localizedDescription)")
            return nil
        }
        NotificationCenter.default.post(name: Notification.Name.DatabaseUpdated, object: nil)
        return savePublicPlan
    }
    
    func update(publicPlan: CustomPublicPlan) -> Bool {
        guard publicPlan.id != nil else {
            return false
        }
        do {
            _ = try dbWriter?.write{ db in
                var savePublicPlan = publicPlan
                try savePublicPlan.updateWithTimestamp(db)
            }
        }
        catch {
            logger.error("\(error.localizedDescription)")
            return false
        }
        NotificationCenter.default.post(name: Notification.Name.DatabaseUpdated, object: nil)
        return true
    }
    
    func delete(publicPlan: CustomPublicPlan) -> Bool {
        guard let publicPlanId = publicPlan.id else {
            return false
        }
        do {
            _ = try dbWriter?.write{ db in
                try CustomPublicPlan.deleteAll(db, ids: [publicPlanId])
            }
        }
        catch {
            logger.error("\(error.localizedDescription)")
            return false
        }
        NotificationCenter.default.post(name: Notification.Name.DatabaseUpdated, object: nil)
        return true
    }
}

extension AppDatabase {
    private enum AppDatabaseError: Error {
        case databaseUnavailable
    }

    func fetchAllSubscribedPlans() throws -> [CustomPublicPlan] {
        guard let dbWriter = dbWriter else { throw AppDatabaseError.databaseUnavailable }
        var result: [CustomPublicPlan] = []
        try dbWriter.read { db in
            result = try CustomPublicPlan
                .filter(Column("source_url") != nil)
                .fetchAll(db)
        }
        return result
    }

    func fetchCustomPublicDays(for planId: Int64) throws -> [CustomPublicDay] {
        guard let dbWriter = dbWriter else { throw AppDatabaseError.databaseUnavailable }
        var result: [CustomPublicDay] = []
        try dbWriter.read { db in
            let planIdColumn = CustomPublicDay.Columns.planId
            result = try CustomPublicDay.filter(planIdColumn == planId).fetchAll(db)
        }
        return result
    }

    func savePlanWithDays(plan: CustomPublicPlan, days: [CustomPublicDay]) throws -> CustomPublicPlan? {
        guard let dbWriter = dbWriter else { throw AppDatabaseError.databaseUnavailable }
        var savedPlan = plan
        try dbWriter.write { db in
            try savedPlan.save(db)
            guard let planId = savedPlan.id else { return }
            for var day in days {
                day.planId = planId
                try day.save(db)
            }
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name.DatabaseUpdated, object: nil)
        }
        return savedPlan
    }

    func replacePlanDaysAndUpdate(planId: Int64, fields: (inout CustomPublicPlan) -> Void, days: [CustomPublicDay]) throws {
        guard let dbWriter = dbWriter else { throw AppDatabaseError.databaseUnavailable }
        try dbWriter.write { db in
            guard var current = try CustomPublicPlan.fetchOne(db, id: planId) else { return }
            fields(&current)
            let planIdColumn = CustomPublicDay.Columns.planId
            try CustomPublicDay.filter(planIdColumn == planId).deleteAll(db)
            for var day in days {
                day.planId = planId
                try day.save(db)
            }
            try current.updateWithTimestamp(db)
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name.DatabaseUpdated, object: nil)
        }
    }

    func updateRefreshTime(for planId: Int64) throws {
        guard let dbWriter = dbWriter else { throw AppDatabaseError.databaseUnavailable }
        try dbWriter.write { db in
            guard var current = try CustomPublicPlan.fetchOne(db, id: planId) else { return }
            current.lastRefreshTime = Int64(Date().timeIntervalSince1970)
            try current.updateWithTimestamp(db)
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name.DatabaseUpdated, object: nil)
        }
    }
}

extension AppDatabase {
    func add(publicDay: CustomPublicDay) -> Bool {
        guard publicDay.id == nil else {
            return false
        }
        do {
            try dbWriter?.write{ db in
                var savePublicDay = publicDay
                try savePublicDay.save(db)
            }
        }
        catch {
            logger.error("\(error.localizedDescription)")
            return false
        }
        NotificationCenter.default.post(name: Notification.Name.DatabaseUpdated, object: nil)
        return true
    }
    
    func update(publicDay: CustomPublicDay) -> Bool {
        guard publicDay.id != nil else {
            return false
        }
        do {
            _ = try dbWriter?.write{ db in
                try publicDay.update(db)
            }
        }
        catch {
            logger.error("\(error.localizedDescription)")
            return false
        }
        NotificationCenter.default.post(name: Notification.Name.DatabaseUpdated, object: nil)
        return true
    }
    
    func deleteCustomPublicDays(with planId: Int64) -> Bool {
        do {
            _ = try dbWriter?.write{ db in
                let planIdColumn = CustomPublicDay.Columns.planId
                let records = try CustomPublicDay.filter(planIdColumn == planId).fetchAll(db)
                let ids = records.compactMap{ $0.id }
                
                try CustomPublicDay.deleteAll(db, ids: ids)
            }
        }
        catch {
            logger.error("\(error.localizedDescription)")
            return false
        }
        NotificationCenter.default.post(name: Notification.Name.DatabaseUpdated, object: nil)
        return true
    }
    
    func delete(publicDay: CustomPublicDay) -> Bool {
        guard let publicPlanId = publicDay.id else {
            return false
        }
        do {
            _ = try dbWriter?.write{ db in
                try CustomPublicDay.deleteAll(db, ids: [publicPlanId])
            }
        }
        catch {
            logger.error("\(error.localizedDescription)")
            return false
        }
        NotificationCenter.default.post(name: Notification.Name.DatabaseUpdated, object: nil)
        return true
    }
}

extension AppDatabase {
    func save(appConfig: AppConfiguration) -> Bool {
        do {
            _ = try dbWriter?.write{ db in
                try appConfig.save(db)
            }
        }
        catch {
            logger.error("\(error.localizedDescription)")
            return false
        }
        NotificationCenter.default.post(name: Notification.Name.DatabaseUpdated, object: nil)
        return true
    }
}

extension AppDatabase {
    /// Provides a read-only access to the database
    var reader: DatabaseReader? {
        dbWriter
    }
}

extension Notification.Name {
    static let AppLogAdded = Notification.Name(rawValue: "com.zizicici.common.appLog.added")
    static let AppLogCleared = Notification.Name(rawValue: "com.zizicici.common.appLog.cleared")
}

extension AppDatabase {
    @discardableResult
    func add(appLog: AppLog) -> Bool {
        guard appLog.id == nil else {
            return false
        }
        guard let dbWriter = dbWriter else {
            return false
        }
        let retention = LogRetentionType.getValue()
        if retention == .disabled {
            return false
        }
        do {
            try dbWriter.write { db in
                var saveLog = appLog
                try saveLog.insert(db)
                if let limit = retention.limit {
                    try Self.pruneAppLogs(db: db, keeping: limit)
                }
            }
        }
        catch {
            logger.error("\(error.localizedDescription)")
            return false
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name.AppLogAdded, object: nil)
        }
        return true
    }

    private static func pruneAppLogs(db: Database, keeping limit: Int) throws {
        let survivors = AppLog
            .select(AppLog.Columns.id)
            .order(AppLog.Columns.creationTime.desc)
            .limit(limit)
        try AppLog
            .filter(!survivors.contains(AppLog.Columns.id))
            .deleteAll(db)
    }

    func fetchAppLogs(limit: Int? = nil, offset: Int? = nil) -> [AppLog] {
        guard let dbWriter = dbWriter else { return [] }
        var result: [AppLog] = []
        do {
            try dbWriter.read { db in
                var request = AppLog.order(AppLog.Columns.creationTime.desc)
                if let limit = limit {
                    request = request.limit(limit, offset: offset)
                }
                result = try request.fetchAll(db)
            }
        }
        catch {
            logger.error("\(error.localizedDescription)")
            return []
        }
        return result
    }

    @discardableResult
    func deleteAllAppLogs() -> Bool {
        guard let dbWriter = dbWriter else {
            return false
        }
        do {
            _ = try dbWriter.write { db in
                try AppLog.deleteAll(db)
            }
        }
        catch {
            logger.error("\(error.localizedDescription)")
            return false
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name.AppLogCleared, object: nil)
        }
        return true
    }

    @discardableResult
    func trimAppLogs(to retention: LogRetentionType) -> Bool {
        guard let dbWriter = dbWriter else {
            return false
        }
        guard retention != .disabled, let limit = retention.limit else {
            return false
        }
        var didDelete = false
        do {
            try dbWriter.write { db in
                try Self.pruneAppLogs(db: db, keeping: limit)
                didDelete = db.changesCount > 0
            }
        }
        catch {
            logger.error("\(error.localizedDescription)")
            return false
        }
        if didDelete {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name.AppLogCleared, object: nil)
            }
        }
        return didDelete
    }
}
