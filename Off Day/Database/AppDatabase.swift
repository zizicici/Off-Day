//
//  AppDatabase.swift
//  Off Day
//
//  Created by zici on 2023/11/25.
//

import Foundation
import GRDB

extension Notification.Name {
    static let DatabaseUpdated = Notification.Name(rawValue: "com.zizicici.common.database.updated")
}

final class AppDatabase {
    init(_ dbWriter: any DatabaseWriter) throws {
        self.dbWriter = dbWriter
        try migrator.migrate(dbWriter)
    }
    
    private var dbWriter: (any DatabaseWriter)?

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
        migrator.registerMigration("add_custom_subscription") { db in
            try db.create(table: "custom_subscription") { table in
                table.autoIncrementedPrimaryKey("id")
                
                table.column("creation_time", .integer).notNull()
                table.column("modification_time", .integer).notNull()
                table.column("url", .text).notNull()
            }
            
            try db.create(table: "custom_subscription_fetch_result") { table in
                table.autoIncrementedPrimaryKey("id")

                table.column("creation_time", .integer).notNull()
                table.column("modification_time", .integer).notNull()
                
                table.column("is_success", .boolean).notNull()
                
                table.column("error_code", .text)
                table.column("error_message", .text)
                
                table.column("start", .integer)
                table.column("end", .integer)
                
                table.column("sum", .integer)
                table.column("add_count", .integer)
                table.column("delete_count", .integer)
                table.column("update_count", .integer)
                
                table.column("subscription_id", .integer).notNull()
                    .indexed()
                    .references("custom_subscription", onDelete: .cascade)
            }
            
            try db.alter(table: "custom_public_plan") { table in
                table.add(column: "source", .integer).notNull().defaults(to: 1)
                table.add(column: "url", .text).notNull().defaults(to: "")
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
            print(error)
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
            print(error)
            return false
        }
        NotificationCenter.default.post(name: NSNotification.Name.DatabaseUpdated, object: nil)
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
            print(error)
            return false
        }
        NotificationCenter.default.post(name: NSNotification.Name.DatabaseUpdated, object: nil)
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
            print(error)
            return false
        }
        NotificationCenter.default.post(name: NSNotification.Name.DatabaseUpdated, object: nil)
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
            print(error)
            return false
        }
        NotificationCenter.default.post(name: NSNotification.Name.DatabaseUpdated, object: nil)
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
            print(error)
            return false
        }
        NotificationCenter.default.post(name: NSNotification.Name.DatabaseUpdated, object: nil)
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
            print(error)
            return false
        }
        NotificationCenter.default.post(name: NSNotification.Name.DatabaseUpdated, object: nil)
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
            print(error)
            return false
        }
        NotificationCenter.default.post(name: NSNotification.Name.DatabaseUpdated, object: nil)
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
            print(error)
            return false
        }
        NotificationCenter.default.post(name: NSNotification.Name.DatabaseUpdated, object: nil)
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
            print(error)
            return false
        }
        NotificationCenter.default.post(name: NSNotification.Name.DatabaseUpdated, object: nil)
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
            print(error)
            return false
        }
        NotificationCenter.default.post(name: NSNotification.Name.DatabaseUpdated, object: nil)
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
            print(error)
            return nil
        }
        NotificationCenter.default.post(name: NSNotification.Name.DatabaseUpdated, object: nil)
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
            print(error)
            return false
        }
        NotificationCenter.default.post(name: NSNotification.Name.DatabaseUpdated, object: nil)
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
            print(error)
            return false
        }
        NotificationCenter.default.post(name: NSNotification.Name.DatabaseUpdated, object: nil)
        return true
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
            print(error)
            return false
        }
        NotificationCenter.default.post(name: NSNotification.Name.DatabaseUpdated, object: nil)
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
            print(error)
            return false
        }
        NotificationCenter.default.post(name: NSNotification.Name.DatabaseUpdated, object: nil)
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
            print(error)
            return false
        }
        NotificationCenter.default.post(name: NSNotification.Name.DatabaseUpdated, object: nil)
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
            print(error)
            return false
        }
        NotificationCenter.default.post(name: NSNotification.Name.DatabaseUpdated, object: nil)
        return true
    }
}

extension AppDatabase {
    /// Provides a read-only access to the database
    var reader: DatabaseReader? {
        dbWriter
    }
}
