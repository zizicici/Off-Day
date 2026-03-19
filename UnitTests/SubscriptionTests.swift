//
//  SubscriptionTests.swift
//  UnitTests
//
//  Created by Claude on 2026/3/18.
//

import Foundation
import Testing
import ZCCalendar
@testable import Off_Day

struct SubscriptionDiffTests {
    // MARK: - hasChanges

    @Test func emptyDiffShouldHaveNoChanges() {
        let diff = SubscriptionDiff(
            planId: 1,
            planName: "Test",
            addedDays: [],
            removedDays: [],
            modifiedDays: []
        )
        #expect(!diff.hasChanges)
    }

    @Test func diffWithAddedDaysShouldHaveChanges() {
        let diff = SubscriptionDiff(
            planId: 1,
            planName: "Test",
            addedDays: [DayChange(date: GregorianDay(year: 2026, month: .jan, day: 1), name: "New Year", oldType: nil, newType: .offDay)],
            removedDays: [],
            modifiedDays: []
        )
        #expect(diff.hasChanges)
    }

    @Test func diffWithRemovedDaysShouldHaveChanges() {
        let diff = SubscriptionDiff(
            planId: 1,
            planName: "Test",
            addedDays: [],
            removedDays: [DayChange(date: GregorianDay(year: 2026, month: .jan, day: 1), name: "Removed", oldType: .offDay, newType: nil)],
            modifiedDays: []
        )
        #expect(diff.hasChanges)
    }

    @Test func diffWithModifiedDaysShouldHaveChanges() {
        let diff = SubscriptionDiff(
            planId: 1,
            planName: "Test",
            addedDays: [],
            removedDays: [],
            modifiedDays: [DayChange(date: GregorianDay(year: 2026, month: .jan, day: 1), name: "Holiday", oldType: .offDay, newType: .workDay)]
        )
        #expect(diff.hasChanges)
    }

    // MARK: - Codable round-trip

    @Test func subscriptionDiffShouldRoundTripThroughJSON() throws {
        let diff = SubscriptionDiff(
            planId: 42,
            planName: "Round Trip",
            addedDays: [DayChange(date: GregorianDay(year: 2026, month: .mar, day: 1), name: "Added", oldType: nil, newType: .offDay)],
            removedDays: [DayChange(date: GregorianDay(year: 2026, month: .jun, day: 1), name: "Removed", oldType: .workDay, newType: nil)],
            modifiedDays: [DayChange(date: GregorianDay(year: 2026, month: .oct, day: 1), name: "Modified", oldType: .offDay, newType: .workDay)]
        )

        let data = try JSONEncoder().encode(diff)
        let decoded = try JSONDecoder().decode(SubscriptionDiff.self, from: data)

        #expect(decoded.planId == 42)
        #expect(decoded.planName == "Round Trip")
        #expect(decoded.addedDays.count == 1)
        #expect(decoded.removedDays.count == 1)
        #expect(decoded.modifiedDays.count == 1)
        #expect(decoded.hasChanges)
    }

    @Test func dayChangeShouldRoundTripThroughJSON() throws {
        let change = DayChange(
            date: GregorianDay(year: 2026, month: .may, day: 5),
            name: "Children's Day",
            oldType: nil,
            newType: .offDay
        )

        let data = try JSONEncoder().encode(change)
        let decoded = try JSONDecoder().decode(DayChange.self, from: data)

        #expect(decoded.name == "Children's Day")
        #expect(decoded.date == GregorianDay(year: 2026, month: .may, day: 5))
        #expect(decoded.oldType == nil)
        #expect(decoded.newType == .offDay)
    }

    @Test func removedDayChangeShouldRoundTripWithNilNewType() throws {
        let change = DayChange(
            date: GregorianDay(year: 2026, month: .jan, day: 1),
            name: "Removed Holiday",
            oldType: .offDay,
            newType: nil
        )

        let data = try JSONEncoder().encode(change)
        let decoded = try JSONDecoder().decode(DayChange.self, from: data)

        #expect(decoded.oldType == .offDay)
        #expect(decoded.newType == nil)
    }
}

struct PendingSubscriptionUpdateTests {
    @Test func pendingUpdateShouldRoundTripThroughJSON() throws {
        let start = GregorianDay(year: 2026, month: .jan, day: 1)
        let end = GregorianDay(year: 2026, month: .dec, day: 31)
        let jsonPlan = JSONPublicPlan(
            name: "Test Plan",
            days: [JSONPublicDay(name: "New Year", date: start, type: .offDay)],
            start: start,
            end: end,
            note: "A note"
        )
        let diff = SubscriptionDiff(
            planId: 10,
            planName: "Test Plan",
            addedDays: [DayChange(date: start, name: "New Year", oldType: nil, newType: .offDay)],
            removedDays: [],
            modifiedDays: []
        )
        let update = PendingSubscriptionUpdate(
            planId: 10,
            planName: "Test Plan",
            fetchTime: 1710000000,
            jsonPlan: jsonPlan,
            diff: diff
        )

        let data = try JSONEncoder().encode(update)
        let decoded = try JSONDecoder().decode(PendingSubscriptionUpdate.self, from: data)

        #expect(decoded.planId == 10)
        #expect(decoded.planName == "Test Plan")
        #expect(decoded.fetchTime == 1710000000)
        #expect(decoded.jsonPlan.name == "Test Plan")
        #expect(decoded.jsonPlan.days.count == 1)
        #expect(decoded.jsonPlan.note == "A note")
        #expect(decoded.diff.hasChanges)
    }

    @Test func pendingUpdateWithNilNoteShouldRoundTrip() throws {
        let start = GregorianDay(year: 2026, month: .jan, day: 1)
        let end = GregorianDay(year: 2026, month: .dec, day: 31)
        let jsonPlan = JSONPublicPlan(
            name: "No Note Plan",
            days: [JSONPublicDay(name: "Day", date: start, type: .offDay)],
            start: start,
            end: end,
            note: nil
        )
        let update = PendingSubscriptionUpdate(
            planId: 20,
            planName: "No Note Plan",
            fetchTime: 1710000000,
            jsonPlan: jsonPlan,
            diff: SubscriptionDiff(planId: 20, planName: "No Note Plan", addedDays: [], removedDays: [], modifiedDays: [])
        )

        let data = try JSONEncoder().encode(update)
        let decoded = try JSONDecoder().decode(PendingSubscriptionUpdate.self, from: data)

        #expect(decoded.jsonPlan.note == nil)
        #expect(!decoded.diff.hasChanges)
    }

    @Test func pendingUpdateShouldPreserveAllDaysInJsonPlan() throws {
        let start = GregorianDay(year: 2026, month: .jan, day: 1)
        let end = GregorianDay(year: 2026, month: .dec, day: 31)
        let days = [
            JSONPublicDay(name: "New Year", date: GregorianDay(year: 2026, month: .jan, day: 1), type: .offDay),
            JSONPublicDay(name: "Labour Day", date: GregorianDay(year: 2026, month: .may, day: 1), type: .offDay),
            JSONPublicDay(name: "National Day", date: GregorianDay(year: 2026, month: .oct, day: 1), type: .offDay),
            JSONPublicDay(name: "Shift", date: GregorianDay(year: 2026, month: .oct, day: 11), type: .workDay),
        ]
        let jsonPlan = JSONPublicPlan(name: "Full Plan", days: days, start: start, end: end)
        let update = PendingSubscriptionUpdate(
            planId: 30,
            planName: "Full Plan",
            fetchTime: 1710000000,
            jsonPlan: jsonPlan,
            diff: SubscriptionDiff(planId: 30, planName: "Full Plan", addedDays: [], removedDays: [], modifiedDays: [])
        )

        let data = try JSONEncoder().encode(update)
        let decoded = try JSONDecoder().decode(PendingSubscriptionUpdate.self, from: data)

        #expect(decoded.jsonPlan.days.count == 4)
        #expect(decoded.jsonPlan.days[0].name == "New Year")
        #expect(decoded.jsonPlan.days[3].type == .workDay)
    }
}

struct ComputeDiffTests {
    private let manager = SubscriptionManager.shared

    // MARK: - No changes

    @Test func identicalDaysShouldProduceNoDiff() {
        let day = GregorianDay(year: 2026, month: .jan, day: 1)
        let currentDays = [CustomPublicDay(name: "New Year", date: day, type: .offDay)]
        let newDays = [JSONPublicDay(name: "New Year", date: day, type: .offDay)]

        let diff = manager.computeDiff(planId: 1, planName: "Test", currentDays: currentDays, newDays: newDays)

        #expect(!diff.hasChanges)
        #expect(diff.addedDays.isEmpty)
        #expect(diff.removedDays.isEmpty)
        #expect(diff.modifiedDays.isEmpty)
    }

    // MARK: - Added days

    @Test func newDayNotInCurrentShouldBeAdded() {
        let day1 = GregorianDay(year: 2026, month: .jan, day: 1)
        let day2 = GregorianDay(year: 2026, month: .may, day: 1)
        let currentDays = [CustomPublicDay(name: "New Year", date: day1, type: .offDay)]
        let newDays = [
            JSONPublicDay(name: "New Year", date: day1, type: .offDay),
            JSONPublicDay(name: "Labour Day", date: day2, type: .offDay),
        ]

        let diff = manager.computeDiff(planId: 1, planName: "Test", currentDays: currentDays, newDays: newDays)

        #expect(diff.addedDays.count == 1)
        #expect(diff.addedDays.first?.name == "Labour Day")
        #expect(diff.addedDays.first?.newType == .offDay)
        #expect(diff.addedDays.first?.oldType == nil)
        #expect(diff.removedDays.isEmpty)
        #expect(diff.modifiedDays.isEmpty)
    }

    // MARK: - Removed days

    @Test func dayNotInNewShouldBeRemoved() {
        let day1 = GregorianDay(year: 2026, month: .jan, day: 1)
        let day2 = GregorianDay(year: 2026, month: .may, day: 1)
        let currentDays = [
            CustomPublicDay(name: "New Year", date: day1, type: .offDay),
            CustomPublicDay(name: "Labour Day", date: day2, type: .offDay),
        ]
        let newDays = [JSONPublicDay(name: "New Year", date: day1, type: .offDay)]

        let diff = manager.computeDiff(planId: 1, planName: "Test", currentDays: currentDays, newDays: newDays)

        #expect(diff.addedDays.isEmpty)
        #expect(diff.removedDays.count == 1)
        #expect(diff.removedDays.first?.name == "Labour Day")
        #expect(diff.removedDays.first?.oldType == .offDay)
        #expect(diff.removedDays.first?.newType == nil)
        #expect(diff.modifiedDays.isEmpty)
    }

    // MARK: - Modified days

    @Test func typeChangeShouldBeModified() {
        let day = GregorianDay(year: 2026, month: .jan, day: 2)
        let currentDays = [CustomPublicDay(name: "Shift", date: day, type: .workDay)]
        let newDays = [JSONPublicDay(name: "Shift", date: day, type: .offDay)]

        let diff = manager.computeDiff(planId: 1, planName: "Test", currentDays: currentDays, newDays: newDays)

        #expect(diff.addedDays.isEmpty)
        #expect(diff.removedDays.isEmpty)
        #expect(diff.modifiedDays.count == 1)
        #expect(diff.modifiedDays.first?.oldType == .workDay)
        #expect(diff.modifiedDays.first?.newType == .offDay)
    }

    @Test func nameChangeShouldBeModified() {
        let day = GregorianDay(year: 2026, month: .jan, day: 1)
        let currentDays = [CustomPublicDay(name: "Old Name", date: day, type: .offDay)]
        let newDays = [JSONPublicDay(name: "New Name", date: day, type: .offDay)]

        let diff = manager.computeDiff(planId: 1, planName: "Test", currentDays: currentDays, newDays: newDays)

        #expect(diff.modifiedDays.count == 1)
        #expect(diff.modifiedDays.first?.name == "New Name")
    }

    // MARK: - Mixed changes

    @Test func mixedChangesShouldAllBeDetected() {
        let day1 = GregorianDay(year: 2026, month: .jan, day: 1)
        let day2 = GregorianDay(year: 2026, month: .feb, day: 14)
        let day3 = GregorianDay(year: 2026, month: .oct, day: 1)
        let day4 = GregorianDay(year: 2026, month: .dec, day: 25)

        let currentDays = [
            CustomPublicDay(name: "New Year", date: day1, type: .offDay),
            CustomPublicDay(name: "Valentine", date: day2, type: .offDay),
            CustomPublicDay(name: "National Day", date: day3, type: .offDay),
        ]
        let newDays = [
            JSONPublicDay(name: "New Year", date: day1, type: .offDay),      // unchanged
            JSONPublicDay(name: "Valentine", date: day2, type: .workDay),    // modified (type)
            JSONPublicDay(name: "Christmas", date: day4, type: .offDay),     // added
            // day3 removed
        ]

        let diff = manager.computeDiff(planId: 1, planName: "Test", currentDays: currentDays, newDays: newDays)

        #expect(diff.addedDays.count == 1)
        #expect(diff.removedDays.count == 1)
        #expect(diff.modifiedDays.count == 1)
        #expect(diff.hasChanges)
    }

    // MARK: - Simultaneous changes

    @Test func bothNameAndTypeChangeShouldProduceSingleModifiedEntry() {
        let day = GregorianDay(year: 2026, month: .jan, day: 1)
        let currentDays = [CustomPublicDay(name: "Old Name", date: day, type: .offDay)]
        let newDays = [JSONPublicDay(name: "New Name", date: day, type: .workDay)]

        let diff = manager.computeDiff(planId: 1, planName: "Test", currentDays: currentDays, newDays: newDays)

        #expect(diff.modifiedDays.count == 1)
        #expect(diff.modifiedDays.first?.name == "New Name")
        #expect(diff.modifiedDays.first?.oldType == .offDay)
        #expect(diff.modifiedDays.first?.newType == .workDay)
        #expect(diff.addedDays.isEmpty)
        #expect(diff.removedDays.isEmpty)
    }

    // MARK: - Complete replacement

    @Test func completeReplacementShouldShowAllRemovedAndAllAdded() {
        let day1 = GregorianDay(year: 2026, month: .jan, day: 1)
        let day2 = GregorianDay(year: 2026, month: .feb, day: 1)
        let day3 = GregorianDay(year: 2026, month: .jul, day: 1)
        let day4 = GregorianDay(year: 2026, month: .aug, day: 1)

        let currentDays = [
            CustomPublicDay(name: "A", date: day1, type: .offDay),
            CustomPublicDay(name: "B", date: day2, type: .offDay),
        ]
        let newDays = [
            JSONPublicDay(name: "C", date: day3, type: .offDay),
            JSONPublicDay(name: "D", date: day4, type: .workDay),
        ]

        let diff = manager.computeDiff(planId: 1, planName: "Test", currentDays: currentDays, newDays: newDays)

        #expect(diff.removedDays.count == 2)
        #expect(diff.addedDays.count == 2)
        #expect(diff.modifiedDays.isEmpty)
    }

    // MARK: - Metadata passthrough

    @Test func diffShouldCarryPlanIdAndPlanName() {
        let diff = manager.computeDiff(planId: 42, planName: "My Plan", currentDays: [], newDays: [])

        #expect(diff.planId == 42)
        #expect(diff.planName == "My Plan")
    }

    // MARK: - Many days

    @Test func largeDaySetShouldDiffCorrectly() {
        let baseJDN = GregorianDay(year: 2026, month: .jan, day: 1).julianDay
        var currentDays: [CustomPublicDay] = []
        var newDays: [JSONPublicDay] = []

        // 365 days in current (offset 0..364), 365 in new (offset 1..365)
        // → day at offset 0 removed, day at offset 365 added, 364 overlap with matching names
        for i in 0..<365 {
            let date = GregorianDay(JDN: baseJDN + i)
            currentDays.append(CustomPublicDay(name: "Day\(i)", date: date, type: .offDay))
        }
        for i in 1...365 {
            let date = GregorianDay(JDN: baseJDN + i)
            newDays.append(JSONPublicDay(name: "Day\(i)", date: date, type: .offDay))
        }

        let diff = manager.computeDiff(planId: 1, planName: "Big", currentDays: currentDays, newDays: newDays)

        #expect(diff.removedDays.count == 1)
        #expect(diff.addedDays.count == 1)
        // Overlapping days (offset 1..364): current has "Day1".."Day364", new also has "Day1".."Day364"
        #expect(diff.modifiedDays.isEmpty)
    }

    // MARK: - Empty inputs

    @Test func emptyCurrentAndNewShouldProduceNoDiff() {
        let diff = manager.computeDiff(planId: 1, planName: "Test", currentDays: [], newDays: [])

        #expect(!diff.hasChanges)
    }

    @Test func emptyCurrentWithNewDaysShouldBeAllAdded() {
        let day = GregorianDay(year: 2026, month: .jan, day: 1)
        let newDays = [JSONPublicDay(name: "New Year", date: day, type: .offDay)]

        let diff = manager.computeDiff(planId: 1, planName: "Test", currentDays: [], newDays: newDays)

        #expect(diff.addedDays.count == 1)
        #expect(diff.removedDays.isEmpty)
    }

    @Test func emptyNewWithCurrentDaysShouldBeAllRemoved() {
        let day = GregorianDay(year: 2026, month: .jan, day: 1)
        let currentDays = [CustomPublicDay(name: "New Year", date: day, type: .offDay)]

        let diff = manager.computeDiff(planId: 1, planName: "Test", currentDays: currentDays, newDays: [])

        #expect(diff.addedDays.isEmpty)
        #expect(diff.removedDays.count == 1)
    }
}

struct PendingFileManagementTests {
    private let manager = SubscriptionManager.shared

    private func makePendingUpdate(planId: Int64, planName: String = "Test Plan") -> PendingSubscriptionUpdate {
        let start = GregorianDay(year: 2026, month: .jan, day: 1)
        let end = GregorianDay(year: 2026, month: .dec, day: 31)
        return PendingSubscriptionUpdate(
            planId: planId,
            planName: planName,
            fetchTime: Int64(Date().timeIntervalSince1970),
            jsonPlan: JSONPublicPlan(
                name: planName,
                days: [JSONPublicDay(name: "Day", date: start, type: .offDay)],
                start: start,
                end: end
            ),
            diff: SubscriptionDiff(
                planId: planId,
                planName: planName,
                addedDays: [DayChange(date: start, name: "Day", oldType: nil, newType: .offDay)],
                removedDays: [],
                modifiedDays: []
            )
        )
    }

    @Test func saveThenLoadPendingUpdateShouldRoundTrip() {
        let update = makePendingUpdate(planId: 99990001)
        manager.savePendingUpdate(update)

        let loaded = manager.loadAllPendingUpdates()
        let found = loaded.first(where: { $0.planId == 99990001 })
        #expect(found != nil)
        #expect(found?.planName == "Test Plan")

        // cleanup
        manager.removePendingUpdate(for: 99990001)
    }

    @Test func removePendingUpdateShouldDeleteFile() {
        let update = makePendingUpdate(planId: 99990002)
        manager.savePendingUpdate(update)
        manager.removePendingUpdate(for: 99990002)

        let loaded = manager.loadAllPendingUpdates()
        let found = loaded.first(where: { $0.planId == 99990002 })
        #expect(found == nil)
    }

    @Test func savingMultiplePendingUpdatesShouldAllLoad() {
        let update1 = makePendingUpdate(planId: 99990003, planName: "Plan A")
        let update2 = makePendingUpdate(planId: 99990004, planName: "Plan B")
        manager.savePendingUpdate(update1)
        manager.savePendingUpdate(update2)

        let loaded = manager.loadAllPendingUpdates()
        let foundA = loaded.first(where: { $0.planId == 99990003 })
        let foundB = loaded.first(where: { $0.planId == 99990004 })
        #expect(foundA != nil)
        #expect(foundB != nil)

        // cleanup
        manager.removePendingUpdate(for: 99990003)
        manager.removePendingUpdate(for: 99990004)
    }

    @Test func removeNonExistentPendingUpdateShouldNotCrash() {
        // Should not throw or crash
        manager.removePendingUpdate(for: 99999999)
    }

    @Test func savingSamePlanIdShouldOverwritePreviousUpdate() {
        let update1 = makePendingUpdate(planId: 99990005, planName: "Original")
        let update2 = makePendingUpdate(planId: 99990005, planName: "Overwritten")
        manager.savePendingUpdate(update1)
        manager.savePendingUpdate(update2)

        let loaded = manager.loadAllPendingUpdates()
        let found = loaded.filter { $0.planId == 99990005 }
        #expect(found.count == 1)
        #expect(found.first?.planName == "Overwritten")

        // cleanup
        manager.removePendingUpdate(for: 99990005)
    }
}

struct UpdateFingerprintTests {
    private let manager = SubscriptionManager.shared

    private func makeJsonPlan(name: String = "Plan", note: String? = nil) -> JSONPublicPlan {
        let start = GregorianDay(year: 2026, month: .jan, day: 1)
        let end = GregorianDay(year: 2026, month: .dec, day: 31)
        return JSONPublicPlan(
            name: name,
            days: [JSONPublicDay(name: "New Year", date: start, type: .offDay)],
            start: start,
            end: end,
            note: note
        )
    }

    // MARK: - Determinism

    @Test func samePlanShouldProduceSameFingerprint() {
        let plan = makeJsonPlan()
        let fp1 = manager.updateFingerprint(jsonPlan: plan)
        let fp2 = manager.updateFingerprint(jsonPlan: plan)
        #expect(fp1 == fp2)
        #expect(!fp1.isEmpty)
    }

    // MARK: - Metadata sensitivity

    @Test func differentNameShouldProduceDifferentFingerprint() {
        let fp1 = manager.updateFingerprint(jsonPlan: makeJsonPlan(name: "Plan A"))
        let fp2 = manager.updateFingerprint(jsonPlan: makeJsonPlan(name: "Plan B"))
        #expect(fp1 != fp2)
    }

    @Test func differentNoteShouldProduceDifferentFingerprint() {
        let fp1 = manager.updateFingerprint(jsonPlan: makeJsonPlan(note: nil))
        let fp2 = manager.updateFingerprint(jsonPlan: makeJsonPlan(note: "Some note"))
        #expect(fp1 != fp2)
    }

    @Test func differentEndDateShouldProduceDifferentFingerprint() {
        let start = GregorianDay(year: 2026, month: .jan, day: 1)
        let plan1 = JSONPublicPlan(name: "P", days: [], start: start, end: GregorianDay(year: 2026, month: .dec, day: 31))
        let plan2 = JSONPublicPlan(name: "P", days: [], start: start, end: GregorianDay(year: 2027, month: .dec, day: 31))
        let fp1 = manager.updateFingerprint(jsonPlan: plan1)
        let fp2 = manager.updateFingerprint(jsonPlan: plan2)
        #expect(fp1 != fp2)
    }

    @Test func differentDaysShouldProduceDifferentFingerprint() {
        let start = GregorianDay(year: 2026, month: .jan, day: 1)
        let end = GregorianDay(year: 2026, month: .dec, day: 31)
        let plan1 = JSONPublicPlan(
            name: "P", days: [JSONPublicDay(name: "A", date: start, type: .offDay)], start: start, end: end)
        let plan2 = JSONPublicPlan(
            name: "P", days: [JSONPublicDay(name: "B", date: start, type: .offDay)], start: start, end: end)
        let fp1 = manager.updateFingerprint(jsonPlan: plan1)
        let fp2 = manager.updateFingerprint(jsonPlan: plan2)
        #expect(fp1 != fp2)
    }
}

struct RejectUpdateFlowTests {
    private let manager = SubscriptionManager.shared

    /// Simulate: save a pending update → reject it → verify same remote content is recognized as rejected
    @Test func rejectedMetadataOnlyUpdateShouldBeRecognizedOnNextRefresh() {
        let planId: Int64 = 99990010
        let start = GregorianDay(year: 2026, month: .jan, day: 1)
        let end = GregorianDay(year: 2026, month: .dec, day: 31)
        let jsonPlan = JSONPublicPlan(
            name: "Updated Name",
            days: [JSONPublicDay(name: "New Year", date: start, type: .offDay)],
            start: start,
            end: end,
            note: "New note"
        )
        let diff = SubscriptionDiff(planId: planId, planName: "Old Name", addedDays: [], removedDays: [], modifiedDays: [])
        let update = PendingSubscriptionUpdate(planId: planId, planName: "Old Name", fetchTime: 0, jsonPlan: jsonPlan, diff: diff)

        // save & reject
        manager.savePendingUpdate(update)
        manager.rejectUpdate(for: planId)

        // simulate next refresh: compute fingerprint for same remote content
        let fingerprint = manager.updateFingerprint(jsonPlan: jsonPlan)
        let rejectedKey = "subscription.rejected.\(planId)"
        let stored = UserDefaults.standard.string(forKey: rejectedKey)

        #expect(stored == fingerprint, "Rejected fingerprint should match same remote content")

        // cleanup
        UserDefaults.standard.removeObject(forKey: rejectedKey)
    }

    /// If remote changes after rejection, fingerprint should NOT match
    @Test func rejectedUpdateShouldNotBlockDifferentRemoteContent() {
        let planId: Int64 = 99990011
        let start = GregorianDay(year: 2026, month: .jan, day: 1)
        let end = GregorianDay(year: 2026, month: .dec, day: 31)
        let jsonPlanV1 = JSONPublicPlan(
            name: "V1 Name",
            days: [JSONPublicDay(name: "New Year", date: start, type: .offDay)],
            start: start,
            end: end
        )
        let diff = SubscriptionDiff(planId: planId, planName: "V1 Name", addedDays: [], removedDays: [], modifiedDays: [])
        let update = PendingSubscriptionUpdate(planId: planId, planName: "V1 Name", fetchTime: 0, jsonPlan: jsonPlanV1, diff: diff)

        // reject V1
        manager.savePendingUpdate(update)
        manager.rejectUpdate(for: planId)

        // remote publishes V2 with different end date
        let jsonPlanV2 = JSONPublicPlan(
            name: "V1 Name",
            days: [JSONPublicDay(name: "New Year", date: start, type: .offDay)],
            start: start,
            end: GregorianDay(year: 2027, month: .dec, day: 31)
        )
        let fingerprintV2 = manager.updateFingerprint(jsonPlan: jsonPlanV2)
        let rejectedKey = "subscription.rejected.\(planId)"
        let stored = UserDefaults.standard.string(forKey: rejectedKey)

        #expect(stored != fingerprintV2, "Different remote content should not match rejected fingerprint")

        // cleanup
        UserDefaults.standard.removeObject(forKey: rejectedKey)
    }
}
