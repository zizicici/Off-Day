//
//  SubscriptionManager.swift
//  Off Day
//
//  Created by zici on 8/3/26.
//

import Foundation
import os
import BackgroundTasks
import CryptoKit
import UserNotifications
import ZCCalendar
import UIKit

final class SubscriptionManager {
    static let shared = SubscriptionManager()

    private let taskIdentifier = "com.zizicici.zzz.subscription"

    private var currentRefreshTask: Task<Void, Never>?
    private var isShowingPendingAlerts = false

    private enum SubscriptionError: LocalizedError {
        case invalidURL(String)
        case invalidHTTPResponse(Int)

        var errorDescription: String? {
            switch self {
            case .invalidURL(let raw):
                return "Invalid URL: \(raw)"
            case .invalidHTTPResponse(let code):
                return "HTTP error: \(code)"
            }
        }
    }

    private var pendingDirectory: URL? {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents?.appendingPathComponent("subscription_pending")
    }

    // MARK: - Subscribe

    func isURLAlreadySubscribed(_ urlString: String) -> Bool {
        guard let plans = try? AppDatabase.shared.fetchAllSubscribedPlans() else { return false }
        return plans.contains { $0.sourceURL == urlString }
    }

    func subscribe(from urlString: String) async throws -> Bool {
        let urlInput: [String: AnyEncodable] = ["url": AnyEncodable(urlString)]

        func logFailure(planName: String? = nil, error: Error? = nil) {
            AppLogger.shared.logSubscription(
                event: .subscribe,
                planId: nil,
                planName: planName,
                success: false,
                extraInput: urlInput,
                error: error
            )
        }

        guard let url = URL(string: urlString), url.scheme == "https" else {
            Logger.subscription.error("Invalid URL: \(urlString)")
            logFailure(error: SubscriptionError.invalidURL(urlString))
            return false
        }

        let jsonPlan: JSONPublicPlan
        do {
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                throw SubscriptionError.invalidHTTPResponse(httpResponse.statusCode)
            }
            jsonPlan = try JSONDecoder().decode(JSONPublicPlan.self, from: data)
        } catch {
            logFailure(error: error)
            throw error
        }

        let plan = CustomPublicPlan(
            name: jsonPlan.name,
            start: jsonPlan.start,
            end: jsonPlan.end,
            sourceURL: urlString,
            lastRefreshTime: Int64(Date().timeIntervalSince1970),
            note: jsonPlan.note
        )

        let days = jsonPlan.days.map { CustomPublicDay(name: $0.name, date: $0.date, type: $0.type) }

        guard let savedPlan = try AppDatabase.shared.savePlanWithDays(plan: plan, days: days) else {
            Logger.subscription.error("Failed to save subscribed plan")
            logFailure(planName: jsonPlan.name)
            return false
        }

        await MainActor.run {
            PublicPlanManager.shared.select(plan: .custom(savedPlan))
        }
        Logger.subscription.info("Subscribed to plan: \(jsonPlan.name)")
        AppLogger.shared.logSubscription(
            event: .subscribe,
            planId: savedPlan.id,
            planName: jsonPlan.name,
            success: true,
            extraInput: [
                "url": AnyEncodable(urlString),
                "dayCount": AnyEncodable(jsonPlan.days.count)
            ]
        )
        return true
    }

    // MARK: - Refresh

    func refresh(plan: CustomPublicPlan, trigger: AppLogger.SubscriptionTrigger, ignorePause: Bool = false, clearRejected: Bool = false) async throws -> Bool {
        if !ignorePause {
            guard plan.isPaused != true else {
                Logger.subscription.info("Plan \(plan.name) is paused, skipping refresh")
                return false
            }
        }
        guard let sourceURL = plan.sourceURL, let url = URL(string: sourceURL) else {
            return false
        }
        guard let planId = plan.id else {
            return false
        }

        if clearRejected {
            clearRejectedFingerprint(for: planId)
        }

        do {
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                throw SubscriptionError.invalidHTTPResponse(httpResponse.statusCode)
            }
            let jsonPlan = try JSONDecoder().decode(JSONPublicPlan.self, from: data)

            let currentDays = try AppDatabase.shared.fetchCustomPublicDays(for: planId)
            let diff = computeDiff(planId: planId, planName: plan.name, currentDays: currentDays, newDays: jsonPlan.days)

            var changedMetadataFields: [String] = []
            if plan.name != jsonPlan.name { changedMetadataFields.append("name") }
            if plan.start != jsonPlan.start { changedMetadataFields.append("start") }
            if plan.end != jsonPlan.end { changedMetadataFields.append("end") }
            if plan.note != jsonPlan.note { changedMetadataFields.append("note") }
            let metadataChanged = !changedMetadataFields.isEmpty

            if diff.hasChanges || metadataChanged {
                let fingerprint = updateFingerprint(jsonPlan: jsonPlan)
                if loadRejectedFingerprint(for: planId) == fingerprint {
                    try AppDatabase.shared.updateRefreshTime(for: planId)
                    Logger.subscription.info("Skipping update - same changes previously rejected: \(jsonPlan.name)")
                    logRefreshSuccess(planId: planId, planName: plan.name, trigger: trigger, diff: diff, metadataChanges: changedMetadataFields, skipped: "previouslyRejected")
                    return true
                }
                clearRejectedFingerprint(for: planId)
                let pending = PendingSubscriptionUpdate(
                    planId: planId,
                    planName: plan.name,
                    fetchTime: Int64(Date().timeIntervalSince1970),
                    jsonPlan: jsonPlan,
                    diff: diff
                )
                savePendingUpdate(pending)
                sendUpdateNotification(diff: diff)
                Logger.subscription.info("Pending update saved for plan: \(jsonPlan.name)")
                logRefreshSuccess(planId: planId, planName: plan.name, trigger: trigger, diff: diff, metadataChanges: changedMetadataFields)
            } else {
                try AppDatabase.shared.updateRefreshTime(for: planId)
                Logger.subscription.info("No changes for plan: \(jsonPlan.name), updated timestamp")
                logRefreshSuccess(planId: planId, planName: plan.name, trigger: trigger, diff: diff)
            }
            return true
        } catch {
            AppLogger.shared.logSubscription(
                event: .refresh,
                planId: planId,
                planName: plan.name,
                success: false,
                trigger: trigger,
                error: error
            )
            throw error
        }
    }

    private func logRefreshSuccess(
        planId: Int64,
        planName: String,
        trigger: AppLogger.SubscriptionTrigger,
        diff: SubscriptionDiff,
        metadataChanges: [String]? = nil,
        skipped: String? = nil
    ) {
        let extraInput: [String: AnyEncodable] = skipped.map { ["skipped": AnyEncodable($0)] } ?? [:]
        AppLogger.shared.logSubscription(
            event: .refresh,
            planId: planId,
            planName: planName,
            success: true,
            trigger: trigger,
            extraInput: extraInput,
            diff: diff,
            metadataChanges: metadataChanges
        )
    }

    @discardableResult
    func refreshAll(trigger: AppLogger.SubscriptionTrigger, includePaused: Bool = false) async -> Bool {
        do {
            let plans = try AppDatabase.shared.fetchAllSubscribedPlans()
            let results = await withTaskGroup(of: Bool.self, returning: [Bool].self) { group in
                for plan in plans {
                    if !includePaused, plan.isPaused == true { continue }
                    group.addTask {
                        do {
                            return try await self.refresh(plan: plan, trigger: trigger, ignorePause: includePaused)
                        } catch {
                            Logger.subscription.error("Failed to refresh plan \(plan.name): \(error.localizedDescription)")
                            return false
                        }
                    }
                }
                var collected: [Bool] = []
                for await result in group {
                    collected.append(result)
                }
                return collected
            }
            return results.isEmpty || !results.contains(false)
        } catch {
            Logger.subscription.error("Failed to fetch subscribed plans: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Diff

    func computeDiff(planId: Int64, planName: String, currentDays: [CustomPublicDay], newDays: [JSONPublicDay]) -> SubscriptionDiff {
        var currentDict: [Int: CustomPublicDay] = [:]
        for day in currentDays {
            currentDict[day.date.julianDay] = day
        }

        var newDict: [Int: JSONPublicDay] = [:]
        for day in newDays {
            newDict[day.date.julianDay] = day
        }

        var added: [DayChange] = []
        var removed: [DayChange] = []
        var modified: [DayChange] = []

        for (julianDay, newDay) in newDict {
            if let oldDay = currentDict[julianDay] {
                if oldDay.type != newDay.type || oldDay.name != newDay.name {
                    modified.append(DayChange(date: newDay.date, name: newDay.name, oldType: oldDay.type, newType: newDay.type))
                }
            } else {
                added.append(DayChange(date: newDay.date, name: newDay.name, oldType: nil, newType: newDay.type))
            }
        }

        for (julianDay, oldDay) in currentDict {
            if newDict[julianDay] == nil {
                removed.append(DayChange(date: oldDay.date, name: oldDay.name, oldType: oldDay.type, newType: nil))
            }
        }

        return SubscriptionDiff(
            planId: planId,
            planName: planName,
            addedDays: added,
            removedDays: removed,
            modifiedDays: modified
        )
    }

    // MARK: - Rejected Update Fingerprint

    func updateFingerprint(jsonPlan: JSONPublicPlan) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        guard let data = try? encoder.encode(jsonPlan) else { return UUID().uuidString }
        return SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
    }

    private func rejectedFingerprintKey(for planId: Int64) -> String {
        "subscription.rejected.\(planId)"
    }

    private func saveRejectedFingerprint(_ fingerprint: String, for planId: Int64) {
        UserDefaults.standard.set(fingerprint, forKey: rejectedFingerprintKey(for: planId))
    }

    private func loadRejectedFingerprint(for planId: Int64) -> String? {
        UserDefaults.standard.string(forKey: rejectedFingerprintKey(for: planId))
    }

    private func clearRejectedFingerprint(for planId: Int64) {
        UserDefaults.standard.removeObject(forKey: rejectedFingerprintKey(for: planId))
    }

    // MARK: - Pending File Management

    func savePendingUpdate(_ update: PendingSubscriptionUpdate) {
        guard let directory = pendingDirectory else { return }
        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        let fileURL = directory.appendingPathComponent("\(update.planId).json")
        do {
            let data = try JSONEncoder().encode(update)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            Logger.subscription.error("Failed to save pending update: \(error.localizedDescription)")
        }
    }

    func loadAllPendingUpdates() -> [PendingSubscriptionUpdate] {
        guard let directory = pendingDirectory else { return [] }
        guard FileManager.default.fileExists(atPath: directory.path) else { return [] }
        do {
            let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            return files.compactMap { fileURL -> PendingSubscriptionUpdate? in
                guard fileURL.pathExtension == "json" else { return nil }
                guard let data = try? Data(contentsOf: fileURL) else { return nil }
                return try? JSONDecoder().decode(PendingSubscriptionUpdate.self, from: data)
            }
        } catch {
            Logger.subscription.error("Failed to load pending updates: \(error.localizedDescription)")
            return []
        }
    }

    func removePendingUpdate(for planId: Int64) {
        guard let directory = pendingDirectory else { return }
        let fileURL = directory.appendingPathComponent("\(planId).json")
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            Logger.subscription.error("Failed to remove pending update for plan \(planId): \(error.localizedDescription)")
        }
    }

    func cleanupForDeletedPlan(_ planId: Int64) {
        removePendingUpdate(for: planId)
        clearRejectedFingerprint(for: planId)
    }

    // MARK: - User Actions

    func acceptUpdate(for planId: Int64) -> Bool {
        let updates = loadAllPendingUpdates()
        guard let update = updates.first(where: { $0.planId == planId }) else { return false }

        do {
            let days = update.jsonPlan.days.map { CustomPublicDay(name: $0.name, date: $0.date, type: $0.type) }
            try AppDatabase.shared.replacePlanDaysAndUpdate(planId: planId, fields: { plan in
                plan.name = update.jsonPlan.name
                plan.start = update.jsonPlan.start
                plan.end = update.jsonPlan.end
                plan.note = update.jsonPlan.note
                plan.lastRefreshTime = Int64(Date().timeIntervalSince1970)
            }, days: days)

            removePendingUpdate(for: planId)
            clearRejectedFingerprint(for: planId)
            Logger.subscription.info("Accepted update for plan: \(update.planName)")
            AppLogger.shared.logSubscription(
                event: .accept,
                planId: planId,
                planName: update.planName,
                success: true,
                diff: update.diff
            )
            return true
        } catch {
            Logger.subscription.error("Failed to accept update: \(error.localizedDescription)")
            AppLogger.shared.logSubscription(
                event: .accept,
                planId: planId,
                planName: update.planName,
                success: false,
                diff: update.diff,
                error: error
            )
            return false
        }
    }

    func rejectUpdate(for planId: Int64) {
        let rejectedUpdate = loadAllPendingUpdates().first(where: { $0.planId == planId })
        if let update = rejectedUpdate {
            saveRejectedFingerprint(updateFingerprint(jsonPlan: update.jsonPlan), for: planId)
        }
        removePendingUpdate(for: planId)
        Logger.subscription.info("Rejected update for plan ID: \(planId)")
        if let update = rejectedUpdate {
            AppLogger.shared.logSubscription(
                event: .reject,
                planId: planId,
                planName: update.planName,
                success: true,
                diff: update.diff
            )
        }
    }

    func pauseSubscription(for planId: Int64) {
        setPaused(true, for: planId)
    }

    func resumeSubscription(for planId: Int64) {
        setPaused(false, for: planId)
    }

    private func setPaused(_ paused: Bool, for planId: Int64) {
        let event: AppLogger.SubscriptionEvent = paused ? .pause : .resume
        let verb = paused ? "pause" : "resume"
        do {
            let plans = try AppDatabase.shared.fetchAllSubscribedPlans()
            guard var plan = plans.first(where: { $0.id == planId }) else { return }
            plan.isPaused = paused
            guard AppDatabase.shared.update(publicPlan: plan) else {
                Logger.subscription.error("Failed to \(verb) subscription: DB update returned false for \(plan.name)")
                AppLogger.shared.logSubscription(
                    event: event,
                    planId: planId,
                    planName: plan.name,
                    success: false
                )
                return
            }
            if paused {
                removePendingUpdate(for: planId)
            } else {
                clearRejectedFingerprint(for: planId)
            }
            Logger.subscription.info("\(paused ? "Paused" : "Resumed") subscription for plan: \(plan.name)")
            AppLogger.shared.logSubscription(
                event: event,
                planId: planId,
                planName: plan.name,
                success: true
            )
        } catch {
            Logger.subscription.error("Failed to \(verb) subscription: \(error.localizedDescription)")
            AppLogger.shared.logSubscription(
                event: event,
                planId: planId,
                planName: nil,
                success: false,
                error: error
            )
        }
    }

    // MARK: - Pending Update Alert

    @MainActor
    func presentPendingUpdateAlertIfNeeded() {
        guard !isShowingPendingAlerts else { return }
        let pendingUpdates = loadAllPendingUpdates()
        guard !pendingUpdates.isEmpty else { return }
        isShowingPendingAlerts = true
        presentNextAlert(from: pendingUpdates, index: 0)
    }

    @MainActor
    func presentPendingUpdateAlert(for planId: Int64) {
        guard !isShowingPendingAlerts else { return }
        let updates = loadAllPendingUpdates().filter { $0.planId == planId }
        guard !updates.isEmpty else { return }
        isShowingPendingAlerts = true
        presentNextAlert(from: updates, index: 0)
    }

    @MainActor
    private func presentNextAlert(from updates: [PendingSubscriptionUpdate], index: Int) {
        guard index < updates.count else {
            isShowingPendingAlerts = false
            return
        }
        let update = updates[index]

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            isShowingPendingAlerts = false
            return
        }

        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        let title = String(format: String(localized: "subscription.update.alert.title"), update.planName)
        let message = String(localized: "subscription.update.alert.message")

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: String(localized: "subscription.update.alert.preview"), style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.presentPreview(for: update, from: updates, index: index, on: topVC)
        })

        alert.addAction(UIAlertAction(title: String(localized: "subscription.update.alert.cancel"), style: .cancel) { [weak self] _ in
            self?.isShowingPendingAlerts = false
        })

        topVC.present(alert, animated: true)
    }

    @MainActor
    private func presentPreview(for update: PendingSubscriptionUpdate, from updates: [PendingSubscriptionUpdate], index: Int, on presenter: UIViewController) {
        let planInfo = PublicPlanInfo(
            plan: .custom(CustomPublicPlan(
                name: update.jsonPlan.name,
                start: update.jsonPlan.start,
                end: update.jsonPlan.end,
                note: update.jsonPlan.note
            )),
            days: Dictionary(
                grouping: update.jsonPlan.days,
                by: { $0.date.julianDay }
            ).compactMapValues { $0.first }
        )
        let previewVC = PublicPlanDetailViewController(publicPlan: planInfo, allowEditing: false)
        previewVC.mode = .subscriptionPreview
        previewVC.changeEntries = buildChangeEntries(for: update)
        previewVC.onAccept = { [weak self] in
            guard let self = self else { return }
            _ = self.acceptUpdate(for: update.planId)
            self.presentNextAlert(from: updates, index: index + 1)
        }
        previewVC.onDecline = { [weak self] action in
            guard let self = self else { return }
            switch action {
            case .skip:
                self.rejectUpdate(for: update.planId)
            case .pause:
                self.pauseSubscription(for: update.planId)
            }
            self.presentNextAlert(from: updates, index: index + 1)
        }
        let nav = NavigationController(rootViewController: previewVC)
        nav.isModalInPresentation = true
        presenter.present(nav, animated: true)
    }

    private func buildChangeEntries(for update: PendingSubscriptionUpdate) -> [PublicPlanDetailViewController.ChangeEntry] {
        typealias Entry = PublicPlanDetailViewController.ChangeEntry
        var entries: [Entry] = []

        // Metadata changes
        let currentPlan = try? AppDatabase.shared.fetchAllSubscribedPlans().first(where: { $0.id == update.planId })
        if let old = currentPlan {
            if old.name != update.jsonPlan.name {
                entries.append(Entry(
                    icon: "pencil",
                    text: String(format: String(localized: "subscription.preview.change.name"), old.name, update.jsonPlan.name),
                    color: AppColor.text
                ))
            }
            if old.start != update.jsonPlan.start {
                entries.append(Entry(
                    icon: "pencil",
                    text: String(format: String(localized: "subscription.preview.change.start"), old.start.formatString() ?? "", update.jsonPlan.start.formatString() ?? ""),
                    color: AppColor.text
                ))
            }
            if old.end != update.jsonPlan.end {
                entries.append(Entry(
                    icon: "pencil",
                    text: String(format: String(localized: "subscription.preview.change.end"), old.end.formatString() ?? "", update.jsonPlan.end.formatString() ?? ""),
                    color: AppColor.text
                ))
            }
            if old.note != update.jsonPlan.note {
                entries.append(Entry(
                    icon: "pencil",
                    text: String(localized: "subscription.preview.change.note"),
                    color: AppColor.text
                ))
            }
        }

        // Day changes
        for day in update.diff.addedDays.sorted(by: { $0.date.julianDay < $1.date.julianDay }) {
            entries.append(Entry(
                icon: "plus.circle",
                text: "\(day.name) (\(day.date.completeFormatString() ?? ""))",
                color: .systemGreen
            ))
        }
        for day in update.diff.removedDays.sorted(by: { $0.date.julianDay < $1.date.julianDay }) {
            entries.append(Entry(
                icon: "minus.circle",
                text: "\(day.name) (\(day.date.completeFormatString() ?? ""))",
                color: .systemRed
            ))
        }
        for day in update.diff.modifiedDays.sorted(by: { $0.date.julianDay < $1.date.julianDay }) {
            entries.append(Entry(
                icon: "arrow.triangle.2.circlepath",
                text: "\(day.name) (\(day.date.completeFormatString() ?? ""))",
                color: .systemOrange
            ))
        }

        return entries
    }

    // MARK: - Local Notification

    func sendUpdateNotification(diff: SubscriptionDiff) {
        let content = UNMutableNotificationContent()
        content.title = String(format: String(localized: "subscription.update.notification.title"), diff.planName)
        content.body = String(localized: "subscription.update.notification.body")
        content.sound = .default

        let request = UNNotificationRequest(identifier: "subscription.update.\(diff.planId)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.subscription.error("Failed to send update notification: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Background Tasks

    func registerBGTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { [weak self] task in
            if let task = task as? BGProcessingTask {
                self?.handleRefreshTask(task: task)
            }
        }
    }

    func scheduleBGTasks() {
        let request = BGProcessingTaskRequest(identifier: taskIdentifier)
        request.requiresExternalPower = false
        request.requiresNetworkConnectivity = true

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            Logger.subscription.error("Could not schedule subscription refresh task: \(error.localizedDescription)")
        }
    }

    func cancelBGTasks() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskIdentifier)
    }

    private func handleRefreshTask(task: BGProcessingTask) {
        scheduleBGTasks()
        let completed = OSAllocatedUnfairLock(initialState: false)
        currentRefreshTask = Task {
            let success = await refreshAll(trigger: .background)
            if completed.withLock({ let old = $0; $0 = true; return !old }) {
                task.setTaskCompleted(success: success)
            }
        }
        task.expirationHandler = { [weak self] in
            self?.currentRefreshTask?.cancel()
            if completed.withLock({ let old = $0; $0 = true; return !old }) {
                task.setTaskCompleted(success: false)
            }
        }
    }
}
