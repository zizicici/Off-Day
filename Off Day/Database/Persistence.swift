//
//  Persistence.swift
//  Off Day
//
//  Created by zici on 2023/11/25.
//

import Foundation
import GRDB

extension AppDatabase {
    static let shared = makeShared()
    
    static let dbName: String = "db.sqlite"
    
    private static func makeShared() -> AppDatabase {
        do {
            let databasePool = try generateDatabasePool()
            
            // Create the AppDatabase
            let database = try AppDatabase(databasePool)
            
            return database
        } catch {
            fatalError("Unresolved error \(error)")
        }
    }
    
    static func generateDatabasePool() throws -> DatabasePool {
        let folderURL = try databaseFolderURL()
        try FileManager().createDirectory(at: folderURL, withIntermediateDirectories: true)
        
        let dbURL = folderURL.appendingPathComponent(dbName)
        var config = Configuration()
        config.automaticMemoryManagement = true
        let dbPool = try DatabasePool(path: dbURL.path, configuration: config)
        return dbPool
    }
    
    static func databaseFolderURL() throws -> URL {
        return try FileManager()
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("database", isDirectory: true)
    }
    
    static func getDatabaseCreationDate() throws -> Date? {
        let folderURL = try databaseFolderURL()
        let dbURL = folderURL.appendingPathComponent(dbName)
        
        let attributes = try FileManager.default.attributesOfItem(atPath: dbURL.path)
        return attributes[.creationDate] as? Date
    }
}
