//
//  SubscribeManager.swift
//  Off Day
//
//  Created by Ci Zi on 2025/5/26.
//

import Foundation
import BackgroundTasks

class SubscribeManager {
    static let shared = SubscribeManager()
    
    let taskIdentifier = "com.zizicici.zzz.subscribe"
    
    func registerBGTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            if let task = task as? BGProcessingTask {
                //
            }
        }
    }
    
    func cancelBGTasks() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskIdentifier)
    }
    
    func scheduleBGTasks() {
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
}
