//
//  NotificationManager.swift
//  Off Day
//
//  Created by Ci Zi on 2025/5/30.
//

import Foundation
import UserNotifications
import ZCCalendar

class NotificationManager {
    enum NotificationType: Hashable {
        case templateExpiry
        case publicHoliday
        case customDay
    }
    
    struct Item: Hashable {
        var type: NotificationType
        var day: Int
        var notificationTime: Int64?
        var notificationText: String?
    }
    
    static let shared = NotificationManager()
    
    private var items: [Item] = []
    
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
    
    func updateNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        items.removeAll()
        
        let appConfig = AppConfiguration.get()
        
        // Update Items and Sort by date
        if appConfig.isTemplateNotificationEnabled {
            if let expirationDate = PublicPlanManager.shared.getExpirationDate() {
                for i in 1..<6 {
                    // Need Check Day after fire date
                    items.append(Item(type: .templateExpiry, day: expirationDate.julianDay - i))
                }
            }
        }
        
        if appConfig.isPublicDayNotificationEnabled {
            let publicDayInfos = PublicPlanManager.shared.getDaysAfter(day: ZCCalendar.manager.today)
            for publicDayInfo in publicDayInfos {
                // Need Check Day after fire date
                items.append(Item(type: .publicHoliday, day: publicDayInfo.value.date.julianDay - 1))
            }
        }
        
        if appConfig.isCustomDayNotificationEnabled {
            let customDays = CustomDayManager.shared.fetchAll(after: ZCCalendar.manager.today.julianDay)
            var filterCustomDays: [CustomDay] = []
            
            for customDay in customDays {
                guard let lastDay = customDays.last else {
                    filterCustomDays.append(customDay)
                    return
                }
                
                if !(customDay.dayIndex == lastDay.dayIndex + 1 && customDay.dayType == lastDay.dayType) {
                    filterCustomDays.append(customDay)
                }
            }
            
            for filterCustomDay in filterCustomDays {
                // Need Check Day after fire date
                items.append(Item(type: .publicHoliday, day: Int(filterCustomDay.dayIndex) - 1))
            }
        }
        
        // Register Notification by Item, limit 20 notifications
        for i in 0..<min(items.count, 20) {
            setupNotification(for: items[i])
        }
    }
    
    func setupNotification(for config: Item) {
        
    }
}
