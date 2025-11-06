//
//  UpdateDayCommentIntent.swift
//  Off Day
//
//  Created by Ci Zi on 2025/5/24.
//

import Foundation
import AppIntents
import ZCCalendar

struct GetDayCommentIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.comment.get.title"
    
    static var description: IntentDescription = IntentDescription("intent.comment.get.description", categoryName: "intent.comment.category")
    
    @Parameter(title: "Date", description: "Date", kind: .date, requestValueDialog: IntentDialog("Which day?"))
    var date: Date
    
    static var parameterSummary: some ParameterSummary {
        Summary("intent.comment.get\(\.$date)")
    }
    
    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String?> {
        var result: String?
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        if let year = components.year, let month = components.month, let day = components.day, let month = Month(rawValue: month) {
            let target = GregorianDay(year: year, month: month, day: day)
            let comment = CustomDayManager.shared.fetchCustomComment(by: target.julianDay)
            result = comment?.content
        }
        return .result(value: result)
    }

    static var openAppWhenRun: Bool = false
}

struct UpdateDayCommentIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.comment.update.title"
    
    static var description: IntentDescription = IntentDescription("intent.comment.update.description", categoryName: "intent.comment.category")
    
    @Parameter(title: "Date", description: "Date", kind: .date, requestValueDialog: IntentDialog("Which day?"))
    var date: Date
    
    @Parameter(title: "intent.comment.content")
    var content: String
    
    static var parameterSummary: some ParameterSummary {
        Summary("intent.comment.update\(\.$date)\(\.$content)")
    }
    
    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        var result = false
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        if let year = components.year, let month = components.month, let day = components.day, let month = Month(rawValue: month) {
            let target = GregorianDay(year: year, month: month, day: day)
            if var comment = CustomDayManager.shared.fetchCustomComment(by: target.julianDay) {
                if content.count == 0 {
                    result = CustomDayManager.shared.delete(customComment: comment)
                } else {
                    comment.content = content
                    result = CustomDayManager.shared.update(customComment: comment)
                }
            } else {
                if content.count == 0 {
                    // Do nothing
                    result = true
                } else {
                    result = CustomDayManager.shared.add(customComment: CustomComment(dayIndex: Int64(target.julianDay), content: content))
                }
            }
        }
        return .result(value: result)
    }

    static var openAppWhenRun: Bool = false
}

struct DeleteDayCommentIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.comment.delete.title"
    
    static var description: IntentDescription = IntentDescription("intent.comment.delete.description", categoryName: "intent.comment.category")
    
    @Parameter(title: "Date", description: "Date", kind: .date, requestValueDialog: IntentDialog("Which day?"))
    var date: Date
    
    static var parameterSummary: some ParameterSummary {
        Summary("intent.comment.delete\(\.$date)")
    }
    
    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        var result = false
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        if let year = components.year, let month = components.month, let day = components.day, let month = Month(rawValue: month) {
            let target = GregorianDay(year: year, month: month, day: day)
            if let comment = CustomDayManager.shared.fetchCustomComment(by: target.julianDay) {
                result = CustomDayManager.shared.delete(customComment: comment)
            } else {
                result = true
            }
        }
        return .result(value: result)
    }

    static var openAppWhenRun: Bool = false
}
