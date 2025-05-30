//
//  NotificationManager.swift
//  Off Day
//
//  Created by Ci Zi on 2025/5/30.
//

import Foundation
import UserNotifications

struct NotificationManager {
    static let shared = NotificationManager()
    
    func requestPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
}
