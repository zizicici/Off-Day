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
}
