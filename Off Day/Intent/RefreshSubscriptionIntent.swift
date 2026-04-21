//
//  RefreshSubscriptionIntent.swift
//  Off Day
//
//  Created by zici on 18/3/26.
//

import AppIntents

struct RefreshSubscriptionIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.subscription.refresh.title"

    static var description: IntentDescription = IntentDescription(
        "intent.subscription.refresh.description",
        categoryName: "intent.subscription.refresh.category"
    )

    @Parameter(title: "intent.subscription.refresh.includePaused.title", description: "intent.subscription.refresh.includePaused.description", default: false)
    var includePaused: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("intent.subscription.refresh.summary") {
            \.$includePaused
        }
    }

    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let value = try await AppLogger.shared.run(
            intent: Self.titleLogKey,
            params: ["includePaused": AnyEncodable(includePaused)]
        ) { () throws -> Bool in
            await SubscriptionManager.shared.refreshAll(trigger: .intent, includePaused: includePaused)
        }
        return .result(value: value)
    }

    static var openAppWhenRun: Bool = false
}
