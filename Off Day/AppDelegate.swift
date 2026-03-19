//
//  AppDelegate.swift
//  Off Day
//
//  Created by zici on 1/5/24.
//

import UIKit
import os
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
        
        NotificationManager.shared.registerBGTasks()
        Task {
            await NotificationManager.shared.updateNotifications()
        }
        
        SubscriptionManager.shared.registerBGTasks()
        Task {
            await SubscriptionManager.shared.refreshAll()
            SubscriptionManager.shared.presentPendingUpdateAlertIfNeeded()
        }
        
        _ = ThemeManager.shared
        
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
        NotificationManager.shared.cancelBGTasks()
        SubscriptionManager.shared.cancelBGTasks()
    }
    
    @objc
    func scheduleBGTasks() {
        BackupManager.shared.scheduleBGTasks()
        NotificationManager.shared.scheduleBGTasks()
        SubscriptionManager.shared.scheduleBGTasks()
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
            Logger.database.error("Failed to check app review eligibility: \(error.localizedDescription)")
        }
    }
    
}
