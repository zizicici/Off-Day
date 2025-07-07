//
//  AppDelegate.swift
//  Off Day
//
//  Created by zici on 1/5/24.
//

import UIKit
import StoreKit
import ZCCalendar

extension UserDefaults {
    enum Support: String {
        case AppReviewRequestDate = "com.zizicici.common.support.AppReviewRequestDate"
    }
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        _ = AppDatabase.shared
        
        PublicPlanManager.shared.load()
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5.0) {
            self.requestAppReview()
        }
        
        BackupManager.shared.registerBGTasks()
        
        NotificationCenter.default.addObserver(self, selector: #selector(scheduleBGTasks), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(cancelBGTasks), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    @objc
    func cancelBGTasks() {
        BackupManager.shared.cancelBGTasks()
    }
    
    @objc
    func scheduleBGTasks() {
        BackupManager.shared.scheduleBGTasks()
    }
}

extension AppDelegate {
    func requestAppReview() {
        do {
            guard let creationDate = try AppDatabase.getDatabaseCreationDate() else { return }
            guard let daysSinceCreation = Calendar.current.dateComponents([.day], from: creationDate, to: Date()).day else { return }
            guard daysSinceCreation >= 10 else { return }
            
            let userDefaultsFlag: Bool
            let userDefaultsKey = UserDefaults.Support.AppReviewRequestDate.rawValue
            if let storedJDN = UserDefaults.standard.getInt(forKey: userDefaultsKey) {
                userDefaultsFlag = (ZCCalendar.manager.today.julianDay - storedJDN) >= 180
            } else {
                userDefaultsFlag = true
            }
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, userDefaultsFlag {
                UserDefaults.standard.set(ZCCalendar.manager.today.julianDay, forKey: userDefaultsKey)
                AppStore.requestReview(in: windowScene)
            }
        } catch {
            print("\(error.localizedDescription)")
        }
    }
    
    func debugPrintEntireSandbox(includeHidden: Bool = true) {
        guard let sandboxURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .deletingLastPathComponent() else {
            print("无法获取沙盒根目录")
            return
        }
        
        print("======= 沙盒完整扫描 (包含隐藏文件: \(includeHidden)) =======")
        print("沙盒根目录: \(sandboxURL.path)")
        
        let options: FileManager.DirectoryEnumerationOptions = includeHidden ? [] : [.skipsHiddenFiles]
        
        if let enumerator = FileManager.default.enumerator(
            at: sandboxURL,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .isHiddenKey],
            options: options,  // 关键修改：控制是否跳过隐藏文件
            errorHandler: { url, error in
                print("扫描错误: \(url.path) - \(error.localizedDescription)")
                return true
            }
        ) {
            var totalSize: Int64 = 0
            let maxDepth = 10  // 防止无限递归
            
            for case let url as URL in enumerator {
                // 控制扫描深度
                let depth = url.pathComponents.count - sandboxURL.pathComponents.count
                if depth > maxDepth {
                    enumerator.skipDescendants()
                    continue
                }
                
                do {
                    let values = try url.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey, .isHiddenKey])
                    let size = Int64(values.fileSize ?? 0)
                    totalSize += size
                    
                    let indent = String(repeating: "  ", count: depth)
                    let hiddenFlag = (values.isHidden ?? false) ? " (隐藏)" : ""
                    let dirFlag = (values.isDirectory ?? false) ? "/" : ""
                    
                    print("\(indent)\(url.lastPathComponent)\(dirFlag): \(formattedFileSize(size))\(hiddenFlag)")
                    
                    // 跳过某些系统目录的深层遍历
                    if shouldSkipDirectory(url: url, depth: depth) {
                        enumerator.skipDescendants()
                    }
                } catch {
                    print("\(String(repeating: "  ", count: depth))❌ 读取错误: \(url.lastPathComponent) - \(error.localizedDescription)")
                }
            }
            
            print("\n总大小: \(formattedFileSize(totalSize))")
        }
    }

    private func shouldSkipDirectory(url: URL, depth: Int) -> Bool {
        let skipDirs = [
            "_EXTERNAL_DATA",
            "temp",
            "Caches/Snapshots",  // 系统快照缓存
            "SystemData"         // 系统数据目录
        ]
        
        // 只在深度>=2时开始检查（避免误判根目录）
        guard depth >= 2 else { return false }
        
        return skipDirs.contains { url.lastPathComponent == $0 }
    }

    private func formattedFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}
