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
}

extension AppDatabase {
    func add(basicCalendarConfig: BasicCalendarConfig) -> Bool {
        guard basicCalendarConfig.id == nil else {
            return false
        }
        do {
            _ = try dbWriter?.write{ db in
                var config = basicCalendarConfig
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
    
    func update(basicCalendarConfig: BasicCalendarConfig) -> Bool {
        guard basicCalendarConfig.id != nil else {
            return false
        }
        do {
            _ = try dbWriter?.write{ db in
                try basicCalendarConfig.update(db)
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
