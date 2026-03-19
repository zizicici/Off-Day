//
//  Logger+Extension.swift
//  Off Day
//
//  Created by zici on 8/3/26.
//

import Foundation
import os

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.zizicici.zzz"

    static let database = Logger(subsystem: subsystem, category: "Database")
    static let backup = Logger(subsystem: subsystem, category: "Backup")
    static let notification = Logger(subsystem: subsystem, category: "Notification")
    static let publicPlan = Logger(subsystem: subsystem, category: "PublicPlan")
    static let baseCalendar = Logger(subsystem: subsystem, category: "BaseCalendar")
    static let customDay = Logger(subsystem: subsystem, category: "CustomDay")
    static let theme = Logger(subsystem: subsystem, category: "Theme")
    static let chineseCalendar = Logger(subsystem: subsystem, category: "ChineseCalendar")
    static let subscription = Logger(subsystem: subsystem, category: "Subscription")
}
