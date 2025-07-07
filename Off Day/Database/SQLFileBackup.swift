//
//  AppDatabase+Backup.swift
//  Off Day
//
//  Created by Ci Zi on 2025/7/7.
//

import Foundation
import GRDB
import ZipArchive

extension AppDatabase {
    // Backup
    func backupToTempPath() -> String? {
        // Build a temporary path
        let fileName = "db.sqlite"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let time = dateFormatter.string(from: Date())
        let subdirectoryName = "\(time)/database"
        let tempDirPath = NSTemporaryDirectory()
        let directoryPath = (tempDirPath as NSString).appendingPathComponent(subdirectoryName)
        do {
            try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print(error)
        }
        
        let filePath = (directoryPath as NSString).appendingPathComponent(fileName)

        // Export
        do {
            try dbWriter?.backup(to: DatabasePool(path: filePath))
        }
        catch {
            print(error)
            return nil
        }
        
        // Zip
        let targetPath = (tempDirPath as NSString).appendingPathComponent(time)
        let zipFile = (tempDirPath as NSString).appendingPathComponent("\(time).zip")
        SSZipArchive.createZipFile(atPath: zipFile, withContentsOfDirectory: targetPath)
        
        do {
            try FileManager.default.removeItem(atPath: targetPath)
        }
        catch {
            print(error)
        }
        
        return zipFile
    }
    
    public func importDatabase(_ fileURL: URL) {
        do {
            try copyFileToTempImportDirectory(fileURL)
            if try findDatabaseFileInImportDirectory() {
                disconnect()
                _ = try copySQLiteFilesToDestination(AppDatabase.databaseFolderURL())
                reconnect()
                NotificationCenter.default.post(name: Notification.Name.DatabaseUpdated, object: nil)
            }
        } catch {
            print(error)
        }
    }
    
    @discardableResult
    func copyFileToTempImportDirectory(_ fileURL: URL) throws -> URL {
        let fileManager = FileManager.default
        
        // 创建 temp/import 目录的路径
        var importURL = URL(fileURLWithPath: NSTemporaryDirectory())
        importURL.appendPathComponent("import", isDirectory: true)
        
        // 删除现有的 import 目录及其内容
        if fileManager.fileExists(atPath: importURL.path) {
            try fileManager.removeItem(at: importURL)
        }
        
        // 创建 import 目录
        try fileManager.createDirectory(at: importURL, withIntermediateDirectories: true, attributes: nil)
        
        // 将文件复制到 import 目录
        let destinationURL = importURL.appendingPathComponent(fileURL.lastPathComponent)
        try fileManager.copyItem(at: fileURL, to: destinationURL)
        
        return destinationURL
    }
    
    func findDatabaseFileInImportDirectory() throws -> Bool {
        let fileManager = FileManager.default
        
        var findDatabase = false
        
        // 1. 获取 temp/import 目录
        var rootURL = URL(fileURLWithPath: NSTemporaryDirectory())
        rootURL.appendPathComponent("import", isDirectory: true)
        
        // 2. 检查 import 目录是否存在
        guard fileManager.fileExists(atPath: rootURL.path) else {
            return findDatabase
        }
        
        let unzipURL = rootURL.appendingPathComponent("unzip", isDirectory: true)
        
        // 如果之前解压过就删除 unzip 文件夹和 zip 文件
        if fileManager.fileExists(atPath: unzipURL.path) {
            try fileManager.removeItem(at: unzipURL)
        }
        
        // 3. 查找并遍历二级目录中的所有 zip 文件
        let unfilteredContents = try fileManager.contentsOfDirectory(at: rootURL, includingPropertiesForKeys: nil)
        
        for itemURL in unfilteredContents {
            if itemURL.pathExtension == "zip",
               let archivePath = itemURL.path.removingPercentEncoding {
                
                // 4. 解压缩 zip 文件内容到 unzip 目录
                let success = SSZipArchive.unzipFile(
                    atPath: archivePath,
                    toDestination: unzipURL.path,
                    overwrite: true,
                    password: nil,
                    progressHandler: nil,
                    completionHandler: nil
                )
                
                guard success else { return findDatabase }
                
                // 5. 遍历 unzip 目录中的所有文件夹和文件，将 .sqlite 文件移动到 temp 目录
                if try findAndMoveSQLiteFiles(in: unzipURL) {
                    findDatabase = true
                }
                
                // 6. 删除解压目录和 zip 文件
                try fileManager.removeItem(at: itemURL)
                try fileManager.removeItem(atPath: unzipURL.path)
            } else {
                if itemURL.pathExtension == "sqlite" {
                    findDatabase = true
                }
            }
        }
        
        return findDatabase
    }

    func findAndMoveSQLiteFiles(in directoryURL: URL) throws -> Bool {
        var findDatabase = false

        let fileManager = FileManager.default
        
        // 获取目录下的所有项目，包括子文件夹
        let contents = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
        
        for itemURL in contents {
            var isDirectory: ObjCBool = false
            
            // 如果是文件夹，则递归查找子文件夹
            if fileManager.fileExists(atPath: itemURL.path, isDirectory: &isDirectory), isDirectory.boolValue {
                if try findAndMoveSQLiteFiles(in: itemURL) {
                    findDatabase = true
                }
            } else if itemURL.pathExtension == "sqlite" {
                // 如果是 .sqlite 文件，则将其移动到 temp/import 目录
                let newLocationURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("import", isDirectory: true).appendingPathComponent(itemURL.lastPathComponent)
                
                try fileManager.moveItem(at: itemURL, to: newLocationURL)
                findDatabase = true
            }
        }
        
        return findDatabase
    }
    
    func copySQLiteFilesToDestination(_ destinationURL: URL) throws -> Bool {
        var result = false
        let fileManager = FileManager.default
        // 获取 temp/import 目录
        var sourceURL = URL(fileURLWithPath: NSTemporaryDirectory())
        sourceURL.appendPathComponent("import", isDirectory: true)
        
        // 检查源目录是否存在
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            return result
        }
        
        try fileManager.removeItem(at: destinationURL)
        try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true)
        
        // 查找所有 .sqlite 文件并复制它们
        let unfilteredContents = try fileManager.contentsOfDirectory(at: sourceURL, includingPropertiesForKeys: nil)
        
        for itemURL in unfilteredContents {
            if itemURL.pathExtension == "sqlite" {
                let destinationFileURL = destinationURL.appendingPathComponent("db.sqlite")
                try fileManager.copyItem(at: itemURL, to: destinationFileURL)
                result = true
            }
        }
        
        return result
    }
}

