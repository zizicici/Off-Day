//
//  NextDayIntent.swift
//  Off Day
//
//  Created by zici on 25/9/24.
//

import AppIntents
import ZCCalendar

struct NextOffDayDetailIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.nextOffDayDetail.intent.title"
    
    static var description: IntentDescription = IntentDescription("intent.nextOffDayDetail.intent.description", categoryName: "intent.dayDetail.intent.category")
    
    @Parameter(title: "Date", description: "Date", kind: .date, requestValueDialog: IntentDialog("From which day onward?"))
    var date: Date
    
    static var parameterSummary: some ParameterSummary {
        Summary("Next Off Day Detail after \(\.$date)")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<DayDetailEntity> {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        if let year = components.year, let month = components.month, let day = components.day, let month = Month(rawValue: month) {
            let dayIndex = GregorianDay(year: year, month: month, day: day).julianDay
            
            var resultDay: GregorianDay? = nil
            if let firstCustomOffDay = CustomDayManager.shared.fetchCustomDay(after: dayIndex, dayType: .offDay) {
                // Find First Custom Off Day
                resultDay = GregorianDay(JDN: Int(firstCustomOffDay.dayIndex))
            } else if let firstPublicOffDay = PublicPlanManager.shared.fetchPublicDay(after: dayIndex, dayType: .offDay) {
                // Find First Public Off Day
                resultDay = firstPublicOffDay.date
            } else if let firstBaseOffDay = BaseCalendarManager.shared.fetchBaseDay(after: dayIndex, dayType: .offDay) {
                // Find First Base Off Day
                resultDay = firstBaseOffDay
            } else {
                resultDay = nil
            }
            
            if let resultDay = resultDay, let detail = resultDay.getDayDetail() {
                return .result(value: detail)
            } else {
                throw FetchError.notFound
            }
        } else {
            throw FetchError.notFound
        }
    }

    static var openAppWhenRun: Bool = false
}

struct NextWorkDayDetailIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.nextWorkDayDetail.intent.title"
    
    static var description: IntentDescription = IntentDescription("intent.nextWorkDayDetail.intent.description", categoryName: "intent.dayDetail.intent.category")
    
    @Parameter(title: "Date", description: "Date", kind: .date, requestValueDialog: IntentDialog("From which day onward?"))
    var date: Date
    
    static var parameterSummary: some ParameterSummary {
        Summary("Next Work Day Detail after \(\.$date)")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<DayDetailEntity> {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        if let year = components.year, let month = components.month, let day = components.day, let month = Month(rawValue: month) {
            let dayIndex = GregorianDay(year: year, month: month, day: day).julianDay
            
            var resultDay: GregorianDay? = nil
            if let firstCustomOffDay = CustomDayManager.shared.fetchCustomDay(after: dayIndex, dayType: .workDay) {
                // Find First Custom Off Day
                resultDay = GregorianDay(JDN: Int(firstCustomOffDay.dayIndex))
            } else if let firstPublicOffDay = PublicPlanManager.shared.fetchPublicDay(after: dayIndex, dayType: .workDay) {
                // Find First Public Off Day
                resultDay = firstPublicOffDay.date
            } else if let firstBaseOffDay = BaseCalendarManager.shared.fetchBaseDay(after: dayIndex, dayType: .workDay) {
                // Find First Base Off Day
                resultDay = firstBaseOffDay
            } else {
                resultDay = nil
            }
            
            if let resultDay = resultDay, let detail = resultDay.getDayDetail() {
                return .result(value: detail)
            } else {
                throw FetchError.notFound
            }
        } else {
            throw FetchError.notFound
        }
    }

    static var openAppWhenRun: Bool = false
}
