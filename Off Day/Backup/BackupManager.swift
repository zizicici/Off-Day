//
//  BackupManager.swift
//  Off Day
//
//  Created by Ci Zi on 2025/7/7.
//

import Foundation
import UIKit
import BackgroundTasks

class BackupManager {
    static let shared = BackupManager()
    
    let taskIdentifier = "com.zizicici.zzz.backup"
    
    func registerBGTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            if let task = task as? BGProcessingTask {
                self.handleDatabaseBackup(task: task)
            }
        }
    }
    
    func cancelBGTasks() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskIdentifier)
    }
    
    func scheduleBGTasks() {
        guard iCloudDocumentIsAccessable, AutoBackup.getValue() == .enable else {
            return
        }
        let request = BGProcessingTaskRequest(identifier: taskIdentifier)
        request.requiresExternalPower = false
        request.requiresNetworkConnectivity = true
        
        do {
            try BGTaskScheduler.shared.submit(request)
        }
        catch {
            print("Could not schedule database cleaning: \(error)")
        }
    }
    
    var iCloudDocumentIsAccessable: Bool {
        return FileManager.iCloudDocumentsURL != nil
    }
    
    var allowAutoBackup: Bool {
        return BackupManager.shared.iCloudDocumentIsAccessable
    }
}

extension BackupManager {
    func backup(overwrite: Bool = false) -> Bool {
        guard let zipPath = AppDatabase.shared.backupToTempPath(), let backupURL = getCurrentDeviceICloudBackupURL() else {
            return false
        }
        let destination = backupURL.appendingPathComponent(URL(fileURLWithPath: zipPath).lastPathComponent)
        let zipURL = URL(fileURLWithPath: zipPath)
        do {
            try FileManager.default.createDirectory(at: backupURL, withIntermediateDirectories: true, attributes: nil)
            if overwrite {
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
            }
            try FileManager.default.moveItem(at: zipURL, to: destination)
            return true
        }
        catch {
            print(error)
            return false
        }
    }
    
    func handleDatabaseBackup(task: BGProcessingTask) {
        guard allowAutoBackup, AutoBackup.getValue() == .enable else {
            task.setTaskCompleted(success: false)
            return
        }
        task.expirationHandler = {
            // Do nothing
        }
        if let latestTime = getLatestiCloudBackupDate() {
            if Calendar.current.isDate(latestTime, inSameDayAs: Date()) {
                task.setTaskCompleted(success: false)
                return
            }
        }
        
        let result = backup()
        task.setTaskCompleted(success: result)
    }
}

extension BackupManager {
    private func getCurrentDeviceICloudBackupURL() -> URL? {
        let folderName = getFolderName()
        return FileManager.iCloudBackupURL?.appendingPathComponent(folderName)
    }
    
    func getFolderName() -> String {
        if let storedName = UserDefaults.standard.getString(forKey: UserDefaults.Settings.BackupFolder.rawValue) {
            return storedName
        } else {
            let number = Int.random(in: 1000...9999)
            let randomString = String(format: "%04d", number)
            set(folderName: randomString)
            return randomString
        }
    }
    
    func set(folderName: String) {
        UserDefaults.standard.set(folderName, forKey: UserDefaults.Settings.BackupFolder.rawValue)
    }
    
    func getLatestiCloudBackupDate() -> Date? {
        guard let backupURL = getCurrentDeviceICloudBackupURL() else { return nil}
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: backupURL, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles),
              let latestFile = files.max(by: { (fileURL1, fileURL2) -> Bool in
                  if let creationDate1 = try? fileManager.attributesOfItem(atPath: fileURL1.path)[.creationDate] as? Date,
                     let creationDate2 = try? fileManager.attributesOfItem(atPath: fileURL2.path)[.creationDate] as? Date {
                      return creationDate1.compare(creationDate2) == .orderedAscending
                  } else {
                      return false
                  }
              }) else {
            // 无法获取目录下的文件或目录为空
            return nil
        }
        
        return try? fileManager.attributesOfItem(atPath: latestFile.path)[.creationDate] as? Date
    }
}

extension FileManager {
    static var iCloudDocumentsURL: URL? {
        if let icloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) {
            return icloudURL.appendingPathComponent("Documents")
        }
        return nil
    }
    
    static var iCloudBackupURL: URL? {
        return iCloudDocumentsURL?.appendingPathComponent("backup")
    }
}
