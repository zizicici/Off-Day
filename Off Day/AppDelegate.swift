//
//  AppDelegate.swift
//  Off Day
//
//  Created by zici on 1/5/24.
//

import UIKit
import Toast

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        _ = AppDatabase.shared
        var style = ToastStyle()
        style.messageColor = .text
        style.backgroundColor = .paper
        style.shadowColor = UIColor.gray
        style.shadowOpacity = 0.1
        style.shadowOffset = CGSize(width: 0, height: 2)
        style.shadowRadius = 3.0
        style.displayShadow = true
        ToastManager.shared.style = style
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

