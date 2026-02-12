//
//  IntentPerformTests.swift
//  UnitTests
//
//  Created by Codex on 2026/2/13.
//

import Foundation
import Testing
import ZCCalendar
@testable import Off_Day

private enum IntentTestHelper {
    @MainActor
    static func selectUSPublicPlan() {
        PublicPlanManager.shared.select(plan: .app(AppPublicPlan(file: .us)))
    }

    static func date(for day: GregorianDay) -> Date? {
        return day.generateDate(secondsFromGMT: Calendar.current.timeZone.secondsFromGMT())
    }

    @MainActor
    static func clearCustomData(for julianDay: Int) {
        if let customDay = CustomDayManager.shared.fetchCustomDay(by: julianDay) {
            CustomDayManager.shared.delete(customDay: customDay)
        }
        if let customComment = CustomDayManager.shared.fetchCustomComment(by: julianDay) {
            _ = CustomDayManager.shared.delete(customComment: customComment)
        }
    }

    @MainActor
    static func didThrowOverReach(_ operation: () async throws -> Void) async -> Bool {
        do {
            try await operation()
            return false
        } catch let error as FetchError {
            if case .overReach = error {
                return true
            }
            return false
        } catch {
            return false
        }
    }
}

struct IntentPerformTests {
    @Test @MainActor func checkDayIntentShouldThrowOverReachForDateBeyondSelectedPlan() async throws {
        IntentTestHelper.selectUSPublicPlan()

        var intent = CheckDayIntent()
        intent.date = try #require(IntentTestHelper.date(for: GregorianDay(year: 2200, month: .jan, day: 1)))

        let didThrowOverReach = await IntentTestHelper.didThrowOverReach {
            _ = try await intent.perform()
        }
        #expect(didThrowOverReach)
    }

    @Test @MainActor func checkDayClashIntentShouldThrowOverReachForDateBeyondSelectedPlan() async throws {
        IntentTestHelper.selectUSPublicPlan()

        var intent = CheckDayClashIntent()
        intent.date = try #require(IntentTestHelper.date(for: GregorianDay(year: 2200, month: .jan, day: 1)))
        intent.enableUserMark = false

        let didThrowOverReach = await IntentTestHelper.didThrowOverReach {
            _ = try await intent.perform()
        }
        #expect(didThrowOverReach)
    }

    @Test @MainActor func dayDetailIntentShouldThrowOverReachForDateBeyondSelectedPlan() async throws {
        IntentTestHelper.selectUSPublicPlan()

        var intent = DayDetailIntent()
        intent.date = try #require(IntentTestHelper.date(for: GregorianDay(year: 2200, month: .jan, day: 1)))

        let didThrowOverReach = await IntentTestHelper.didThrowOverReach {
            _ = try await intent.perform()
        }
        #expect(didThrowOverReach)
    }

    @Test @MainActor func checkOffsetIntentsShouldThrowOverReachForVeryLargeOffset() async {
        IntentTestHelper.selectUSPublicPlan()

        var offIntent = CheckOffsetDayOffIntent()
        offIntent.dayCount = 100_000

        let offIntentOverReach = await IntentTestHelper.didThrowOverReach {
            _ = try await offIntent.perform()
        }
        #expect(offIntentOverReach)

        var clashIntent = CheckOffsetDayClashIntent()
        clashIntent.dayCount = 100_000
        clashIntent.enableUserMark = true

        let clashIntentOverReach = await IntentTestHelper.didThrowOverReach {
            _ = try await clashIntent.perform()
        }
        #expect(clashIntentOverReach)
    }

    @Test @MainActor func dayCommentIntentsShouldCreateAndDeleteCommentInDatabase() async throws {
        let day = GregorianDay(year: 2032, month: .jan, day: 11)
        let dayIndex = day.julianDay
        let date = try #require(IntentTestHelper.date(for: day))

        IntentTestHelper.clearCustomData(for: dayIndex)
        defer {
            IntentTestHelper.clearCustomData(for: dayIndex)
        }

        var updateIntent = UpdateDayCommentIntent()
        updateIntent.date = date
        updateIntent.content = "Intent comment test"

        _ = try await updateIntent.perform()
        #expect(CustomDayManager.shared.fetchCustomComment(by: dayIndex)?.content == "Intent comment test")

        var getIntent = GetDayCommentIntent()
        getIntent.date = date
        _ = try await getIntent.perform()
        #expect(CustomDayManager.shared.fetchCustomComment(by: dayIndex)?.content == "Intent comment test")

        var deleteIntent = DeleteDayCommentIntent()
        deleteIntent.date = date
        _ = try await deleteIntent.perform()

        #expect(CustomDayManager.shared.fetchCustomComment(by: dayIndex) == nil)
    }

    @Test @MainActor func updateDayMarkIntentShouldWriteAndClearCustomDay() async throws {
        let day = GregorianDay(year: 2032, month: .jan, day: 12)
        let dayIndex = day.julianDay
        let date = try #require(IntentTestHelper.date(for: day))

        IntentTestHelper.clearCustomData(for: dayIndex)
        defer {
            IntentTestHelper.clearCustomData(for: dayIndex)
        }

        var intent = UpdateDayMarkIntent()
        intent.date = date
        intent.mark = .off
        _ = try await intent.perform()
        #expect(CustomDayManager.shared.fetchCustomDay(by: dayIndex)?.dayType == .offDay)

        intent.mark = .work
        _ = try await intent.perform()
        #expect(CustomDayManager.shared.fetchCustomDay(by: dayIndex)?.dayType == .workDay)

        intent.mark = .blank
        _ = try await intent.perform()
        #expect(CustomDayManager.shared.fetchCustomDay(by: dayIndex) == nil)
    }
}
