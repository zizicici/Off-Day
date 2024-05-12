//
//  CheckDayIntent.swift
//  Off Day
//
//  Created by zici on 1/5/24.
//

import AppIntents
import ZCCalendar

struct CheckDayClashIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.clash.title"
    
    static var description: IntentDescription = IntentDescription("If the result is true, it is a Clash Day. Clash Day means that the public holiday template, base calendar, and user annotations (optional) for this day have different criteria for determining whether it is an Off Day.", categoryName: "Check Clash Day")
    
    @Parameter(title: "Date", description: "Date", kind: .date, requestValueDialog: IntentDialog("Which day?"))
    var date: Date
    
    @Parameter(title: "Including user annotaions", description: "Including user annotaions", default: false)
    var enableUserMark: Bool
    
    static var parameterSummary: some ParameterSummary {
        Summary("Is \(\.$date) a Clash Day?") {
            \.$enableUserMark
        }
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        var isOffDay = false
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        if let year = components.year, let month = components.month, let day = components.day, let month = Month(rawValue: month) {
            let target = GregorianDay(year: year, month: month, day: day)
            if PublicPlanManager.shared.isOverReach(at: target.julianDay) {
                throw FetchError.overReach
            }
            isOffDay = target.isClashDay(including: enableUserMark)
        }
        return .result(value: isOffDay)
    }

    static var openAppWhenRun: Bool = false
}

struct CheckTodayClashIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.clash.today.title"
    
    static var description: IntentDescription = IntentDescription("If the result is true, it is a Clash Day. Clash Day means that the public holiday template, base calendar, and user annotations (optional) for this day have different criteria for determining whether it is an Off Day.", categoryName: "Check Clash Day")
    
    @Parameter(title: "Including user annotaions", description: "Including user annotaions", default: false)
    var enableUserMark: Bool
    
    static var parameterSummary: some ParameterSummary {
        Summary("Is Today a Clash Day?") {
            \.$enableUserMark
        }
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        var isOffDay = false
        let components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        if let year = components.year, let month = components.month, let day = components.day, let month = Month(rawValue: month) {
            let target = GregorianDay(year: year, month: month, day: day)
            if PublicPlanManager.shared.isOverReach(at: target.julianDay) {
                throw FetchError.overReach
            }
            isOffDay = target.isClashDay(including: enableUserMark)
        }
        return .result(value: isOffDay)
    }

    static var openAppWhenRun: Bool = false
}

struct CheckTomorrowClashIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.clash.tomorrow.title"
    
    static var description: IntentDescription = IntentDescription("If the result is true, it is a Clash Day. Clash Day means that the public holiday template, base calendar, and user annotations (optional) for this day have different criteria for determining whether it is an Off Day.", categoryName: "Check Clash Day")
    
    @Parameter(title: "Including user annotaions", description: "Including user annotaions", default: false)
    var enableUserMark: Bool
    
    static var parameterSummary: some ParameterSummary {
        Summary("Is Tomorrow a Clash Day?") {
            \.$enableUserMark
        }
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        var isOffDay = false
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let components = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
        if let year = components.year, let month = components.month, let day = components.day, let month = Month(rawValue: month) {
            let target = GregorianDay(year: year, month: month, day: day)
            if PublicPlanManager.shared.isOverReach(at: target.julianDay) {
                throw FetchError.overReach
            }
            isOffDay = target.isClashDay(including: enableUserMark)
        }
        return .result(value: isOffDay)
    }

    static var openAppWhenRun: Bool = false
}

struct CheckOffsetDayClashIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.clash.offset.title"
    
    static var description: IntentDescription = IntentDescription("If the result is true, it is a Clash Day. Clash Day means that the public holiday template, base calendar, and user annotations (optional) for this day have different criteria for determining whether it is an Off Day.", categoryName: "Check Clash Day")
    
    @Parameter(title: "Day Count", default: 2)
    var dayCount: Int
    
    @Parameter(title: "Including user annotaions", description: "Including user annotaions", default: false)
    var enableUserMark: Bool
    
    static var parameterSummary: some ParameterSummary {
        Summary("Is it a Clash Day in \(\.$dayCount) day(s)?") {
            \.$enableUserMark
        }
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        var isOffDay = false
        let tomorrow = Calendar.current.date(byAdding: .day, value: dayCount, to: Date())!
        let components = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
        if let year = components.year, let month = components.month, let day = components.day, let month = Month(rawValue: month) {
            let target = GregorianDay(year: year, month: month, day: day)
            if PublicPlanManager.shared.isOverReach(at: target.julianDay) {
                throw FetchError.overReach
            }
            isOffDay = target.isClashDay(including: enableUserMark)
        }
        return .result(value: isOffDay)
    }

    static var openAppWhenRun: Bool = false
}

extension GregorianDay {
    fileprivate func isClashDay(including customMarkEnabled: Bool) -> Bool {
        let baseOffValue = BaseCalendarManager.shared.isOff(day: self)
        var publicOffValue: Bool? = nil
        if let publicDay = PublicPlanManager.shared.publicDay(at: julianDay) {
            publicOffValue = publicDay.type == .offDay
        }
        if customMarkEnabled {
            let customOffValue: Bool?
            if let customDay = CustomDayManager.shared.fetchCustomDay(by: julianDay) {
                customOffValue = customDay.dayType == .offDay
            } else {
                customOffValue = nil
            }
            if let publicOffValue = publicOffValue {
                if let customOffValue = customOffValue {
                    return !((baseOffValue == publicOffValue) && (customOffValue == baseOffValue))
                } else {
                    return publicOffValue != baseOffValue
                }
            } else {
                if let customOffValue = customOffValue {
                    return customOffValue != baseOffValue
                } else {
                    return false
                }
            }
        } else {
            if let publicOffValue = publicOffValue {
                return baseOffValue != publicOffValue
            } else {
                return false
            }
        }
    }
}
