//
//  AppLogger.swift
//  Off Day
//
//  Created by zici on 20/4/26.
//

import Foundation
import MoreKit

struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init<T: Encodable>(_ wrapped: T) {
        _encode = { try wrapped.encode(to: $0) }
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

struct SubscriptionLogOutput: Codable {
    let added: [Entry]
    let removed: [Entry]
    let modified: [Entry]
    let metadataChanges: [String]?
    let hasChanges: Bool

    struct Entry: Codable {
        let date: String
        let name: String
        let oldType: DayType?
        let newType: DayType?

        init(_ change: DayChange) {
            self.date = change.date.formatString() ?? ""
            self.name = change.name
            self.oldType = change.oldType
            self.newType = change.newType
        }
    }
}

final class AppLogger {
    static let shared = AppLogger()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private let writeQueue = DispatchQueue(label: "com.zizicici.common.appLog.write", qos: .utility)

    private let stateLock = NSLock()
    private var lastAppliedRetention: LogRetentionType = LogRetentionType.getValue()

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applyRetentionFromSettings),
            name: .SettingsUpdate,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func applyRetentionFromSettings() {
        let retention = LogRetentionType.getValue()
        stateLock.lock()
        let changed = retention != lastAppliedRetention
        lastAppliedRetention = retention
        stateLock.unlock()
        guard changed else { return }
        guard retention != .disabled else { return }
        writeQueue.async {
            AppDatabase.shared.trimAppLogs(to: retention)
        }
    }

    // MARK: - Intent wrapper

    @discardableResult
    func run<T: Encodable>(
        intent name: String,
        params: [String: AnyEncodable],
        operation: () async throws -> T
    ) async throws -> T {
        try await run(intent: name, params: params, operation: operation, toOutput: { AnyEncodable($0) })
    }

    @discardableResult
    func run<T, U: Encodable>(
        intent name: String,
        params: [String: AnyEncodable],
        operation: () async throws -> T,
        toOutput: (T) -> U?
    ) async throws -> T {
        guard LogRetentionType.getValue() != .disabled else {
            return try await operation()
        }
        do {
            let result = try await operation()
            record(
                category: .intent,
                subtype: name,
                planId: nil,
                success: true,
                input: encode(params),
                output: toOutput(result).flatMap { encode($0) },
                errorMessage: nil
            )
            return result
        } catch {
            record(
                category: .intent,
                subtype: name,
                planId: nil,
                success: false,
                input: encode(params),
                output: nil,
                errorMessage: String(describing: error)
            )
            throw error
        }
    }

    // MARK: - Subscription

    enum SubscriptionEvent: String {
        case subscribe
        case refresh
        case accept
        case reject
        case pause
        case resume

        var localizationKey: String.LocalizationValue {
            switch self {
            case .subscribe: return "log.subscription.subscribe"
            case .refresh:   return "log.subscription.refresh"
            case .accept:    return "log.subscription.accept"
            case .reject:    return "log.subscription.reject"
            case .pause:     return "log.subscription.pause"
            case .resume:    return "log.subscription.resume"
            }
        }
    }

    enum SubscriptionTrigger: String {
        case launch
        case background
        case manual
        case intent

        var localizationKey: String.LocalizationValue {
            switch self {
            case .launch:     return "log.subscription.trigger.launch"
            case .background: return "log.subscription.trigger.background"
            case .manual:     return "log.subscription.trigger.manual"
            case .intent:     return "log.subscription.trigger.intent"
            }
        }
    }

    func logSubscription(
        event: SubscriptionEvent,
        planId: Int64?,
        planName: String?,
        success: Bool,
        trigger: SubscriptionTrigger? = nil,
        extraInput: [String: AnyEncodable] = [:],
        diff: SubscriptionDiff? = nil,
        metadataChanges: [String]? = nil,
        error: Error? = nil
    ) {
        guard LogRetentionType.getValue() != .disabled else { return }
        var input: [String: AnyEncodable] = extraInput
        if let planName = planName {
            input["planName"] = AnyEncodable(planName)
        }
        if let planId = planId {
            input["planId"] = AnyEncodable(planId)
        }
        if let trigger = trigger {
            input["trigger"] = AnyEncodable(trigger.rawValue)
        }

        let sanitizedMetadata = metadataChanges?.filter { !$0.isEmpty }

        let output: String? = {
            if let diff = diff {
                return encode(SubscriptionLogOutput(
                    added: diff.addedDays.map(SubscriptionLogOutput.Entry.init),
                    removed: diff.removedDays.map(SubscriptionLogOutput.Entry.init),
                    modified: diff.modifiedDays.map(SubscriptionLogOutput.Entry.init),
                    metadataChanges: sanitizedMetadata?.isEmpty == false ? sanitizedMetadata : nil,
                    hasChanges: diff.hasChanges || (sanitizedMetadata?.isEmpty == false)
                ))
            }
            return nil
        }()

        record(
            category: .subscription,
            subtype: event.rawValue,
            planId: planId,
            success: success,
            input: input.isEmpty ? nil : encode(input),
            output: output,
            errorMessage: error.map { String(describing: $0) }
        )
    }

    // MARK: - Core record

    private func record(
        category: AppLogCategory,
        subtype: String,
        planId: Int64?,
        success: Bool,
        input: String?,
        output: String?,
        errorMessage: String?
    ) {
        let log = AppLog(
            category: category,
            subtype: subtype,
            planId: planId,
            success: success,
            inputJSON: input,
            outputJSON: output,
            errorMessage: errorMessage
        )
        writeQueue.async {
            AppDatabase.shared.add(appLog: log)
        }
    }

    // MARK: - Encoding helpers

    private func encode<T: Encodable>(_ value: T) -> String? {
        do {
            let data = try encoder.encode(value)
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
}
