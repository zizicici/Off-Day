//
//  NotificationManager.swift
//  Off Day
//
//  Created by Ci Zi on 2025/5/30.
//

import Foundation
import UserNotifications
import ZCCalendar
import BackgroundTasks
import UIKit

extension Notification.Name {
    static let NotificationPermissionUpdated = Notification.Name(rawValue: "com.zizicici.common.notification.permission.updated")
}

class NotificationManager {
    enum NotificationType: Hashable {
        case template
        case publicHoliday
        case customDay
    }
    
    struct Item: Hashable {
        var type: NotificationType
        var day: Int
        var notificationTime: Int64
        var notificationTitle: String
        var notificationText: String
    }
    
    static let shared = NotificationManager()
    
    private var items: [Item] = [] {
        didSet {
            if oldValue != items {
                updateWithItems()
            }
        }
    }
    
    private let taskIdentifier = "com.zizicici.zzz.notification"
    
    private var reloadDataDebounce: Debounce<Int>?
    
    private(set) var hasAuthorization: Bool = false {
        didSet {
            if oldValue != hasAuthorization {
                NotificationCenter.default.post(name: .NotificationPermissionUpdated, object: nil)
            }
        }
    }
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(reloadDataInMainAsync), name: .DatabaseUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadDataInMainAsync), name: .SettingsUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadDataInMainAsync), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadDataInMainAsync), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    func requestPermission(completion: ((Bool) -> ())?) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, error in
            self?.hasAuthorization = granted
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                completion?(granted)
            }
        }
    }
    
    @objc
    private func reloadDataInMainAsync() {
        DispatchQueue.main.async {
            self.reloadData()
        }
    }
    
    private func reloadData() {
        if reloadDataDebounce == nil {
            reloadDataDebounce = Debounce(duration: 0.5, block: { [weak self] value in
                await self?.updateNotifications()
            })
        }
        reloadDataDebounce?.emit(value: 0)
    }
    
    func updateNotifications() async {
        guard await UNUserNotificationCenter.current().notificationSettings().authorizationStatus == .authorized else {
            hasAuthorization = false
            return
        }
        hasAuthorization = true
        
        var newItems: [Item] = []
        
        let todayIndex = ZCCalendar.manager.today.julianDay
        let appConfig = AppConfiguration.get()
        
        // Update Items and Sort by date
        if appConfig.isTemplateNotificationEnabled {
            if let expirationDate = PublicPlanManager.shared.getExpirationDate(), expirationDate.julianDay >= todayIndex {
                let notificationType = NotificationType.template
                for i in 0..<5 {
                    let notificationTitle = String(localized: "notification.type.template.title")
                    let notificationText = String(format: String(localized: "notification.type.template.text, %i"), i + 1)
                    let targetDayIndex = expirationDate.julianDay - i
                    if targetDayIndex > todayIndex {
                        newItems.append(Item(type: notificationType, day: targetDayIndex, notificationTime: appConfig.templateNanoseconds, notificationTitle: notificationTitle, notificationText: notificationText))
                    } else if targetDayIndex == todayIndex {
                        if Int64(Date().timeIntervalSince(expirationDate.generateDate(secondsFromGMT: Calendar.current.timeZone.secondsFromGMT()) ?? Date()) * 1000) <= appConfig.templateNanoseconds {
                            newItems.append(Item(type: notificationType, day: targetDayIndex, notificationTime: appConfig.templateNanoseconds, notificationTitle: notificationTitle, notificationText: notificationText))
                        } else {
                            break
                        }
                    } else {
                        break
                    }
                }
            }
        }
        
        if appConfig.isPublicDayNotificationEnabled {
            let notificationType = NotificationType.publicHoliday
            let publicDayInfos = PublicPlanManager.shared.getDaysAfter(day: GregorianDay(JDN: todayIndex - 1))
            for publicDayInfo in publicDayInfos {
                let notificationTitle: String
                let notificationText: String
                switch publicDayInfo.value.type {
                case .offDay:
                    notificationTitle = String(localized: "notification.type.publicDay.offDay.title")
                    notificationText = String(format: String(localized: "notification.type.publicDay.offDay.text, %@, %@"), publicDayInfo.value.date.completeFormatString() ?? "", publicDayInfo.value.name)
                case .workDay:
                    notificationTitle = String(localized: "notification.type.publicDay.workDay.title")
                    notificationText = String(format: String(localized: "notification.type.publicDay.workDay.text, %@, %@"), publicDayInfo.value.date.completeFormatString() ?? "", publicDayInfo.value.name)
                }
                let targetDayIndex = publicDayInfo.value.date.julianDay - 1
                if targetDayIndex > todayIndex {
                    newItems.append(Item(type: notificationType, day: targetDayIndex, notificationTime: appConfig.publicDayNanoseconds, notificationTitle: notificationTitle, notificationText: notificationText))
                } else if targetDayIndex == todayIndex {
                    if Int64(Date().timeIntervalSince(GregorianDay(JDN: targetDayIndex).generateDate(secondsFromGMT: Calendar.current.timeZone.secondsFromGMT()) ?? Date()) * 1000) <= appConfig.publicDayNanoseconds {
                        newItems.append(Item(type: notificationType, day: targetDayIndex, notificationTime: appConfig.publicDayNanoseconds, notificationTitle: notificationTitle, notificationText: notificationText))
                    } else {
                        break
                    }
                } else {
                    break
                }
            }
        }
        
        if appConfig.isCustomDayNotificationEnabled {
            let customDays = CustomDayManager.shared.fetchAll(after: todayIndex - 1)
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
                let notificationTitle: String
                let notificationText: String
                switch filterCustomDay.dayType {
                case .offDay:
                    notificationTitle = String(localized: "notification.type.customDay.offDay.title")
                    notificationText = String(format: String(localized: "notification.type.customDay.offDay.text, %@"), GregorianDay(JDN: Int(filterCustomDay.dayIndex)).completeFormatString() ?? "")
                case .workDay:
                    notificationTitle = String(localized: "notification.type.customDay.workDay.title")
                    notificationText = String(format: String(localized: "notification.type.customDay.workDay.text, %@"), GregorianDay(JDN: Int(filterCustomDay.dayIndex)).completeFormatString() ?? "")
                }
                
                let targetDayIndex = Int(filterCustomDay.dayIndex) - 1
                if targetDayIndex > todayIndex {
                    newItems.append(Item(type: .customDay, day: targetDayIndex, notificationTime: appConfig.customDayNanoseconds, notificationTitle: notificationTitle, notificationText: notificationText))
                } else if targetDayIndex == todayIndex {
                    if Int64(Date().timeIntervalSince(GregorianDay(JDN: targetDayIndex).generateDate(secondsFromGMT: Calendar.current.timeZone.secondsFromGMT()) ?? Date()) * 1000) <= appConfig.customDayNanoseconds {
                        newItems.append(Item(type: .customDay, day: targetDayIndex, notificationTime: appConfig.customDayNanoseconds, notificationTitle: notificationTitle, notificationText: notificationText))
                    } else {
                        break
                    }
                } else {
                    break
                }
            }
        }
        
        newItems = newItems.sorted(by: { $0.day < $1.day })
        
        // limit 20 notifications
        self.items = Array(newItems.prefix(20))
    }
    
    private func updateWithItems() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        // Register Notification by Items
        items.forEach{ setupNotification(for: $0) }
    }
    
    private func setupNotification(for config: Item) {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = config.notificationTitle
        content.body = config.notificationText
        content.sound = .default
        
        let day = GregorianDay(JDN: config.day)
        
        var dateComponents = DateComponents()
        dateComponents.hour = Int(config.notificationTime) / 3600 / 1000
        dateComponents.minute = Int(config.notificationTime) % (3600 * 1000) / 60000
        dateComponents.year = day.year
        dateComponents.month = day.month.rawValue
        dateComponents.day = day.day
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(identifier: String(config.hashValue),
                                            content: content,
                                            trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("添加通知失败: \(error.localizedDescription)")
            }
        }
    }
}

extension NotificationManager {
    func registerBGTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            if let task = task as? BGProcessingTask {
                Task {
                    await self.handleUpdateNotifications(task: task)
                }
            }
        }
    }
    
    func cancelBGTasks() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskIdentifier)
    }
    
    func scheduleBGTasks() {
        let request = BGProcessingTaskRequest(identifier: taskIdentifier)
        request.requiresExternalPower = false
        request.requiresNetworkConnectivity = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
        }
        catch {
            print("Could not schedule database cleaning: \(error)")
        }
    }
    
    func handleUpdateNotifications(task: BGProcessingTask) async {
        task.expirationHandler = {
            // Do nothing
        }
        await updateNotifications()
        
        task.setTaskCompleted(success: true)
    }
}
