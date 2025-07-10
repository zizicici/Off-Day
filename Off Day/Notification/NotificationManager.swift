//
//  NotificationManager.swift
//  Off Day
//
//  Created by Ci Zi on 2025/5/30.
//

import Foundation
import UserNotifications

struct NotificationManager {
    enum NotificationType {
        case templateExpiry
        case publicHoliday
        case customDay
        
        var settingsKey: UserDefaults.Settings {
            switch self {
            case .templateExpiry:
                return .NotificationTemplateExpiry
            case .publicHoliday:
                return .NotificationPublicHolidayStart
            case .customDay:
                return .NotificationCustomDayStart
            }
        }
        
        func getValue() -> Bool {
            if let boolValue = UserDefaults.standard.getBool(forKey: settingsKey.rawValue) {
                return boolValue
            } else {
                return false
            }
        }
        
        func setValue(_ value: Bool) {
            UserDefaults.standard.set(value, forKey: settingsKey.rawValue)
            NotificationCenter.default.post(name: Notification.Name.SettingsUpdate, object: nil)
        }
    }
    
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
    
    func isEnabled(for notificationType: NotificationType) -> Bool {
        return notificationType.getValue()
    }
    
    func set(isEnabled: Bool, for notificationType: NotificationType) {
        notificationType.setValue(isEnabled)
    }
}
