//
//  DayDetailIntentEntityTests.swift
//  UnitTests
//
//  Created by Codex on 2026/2/13.
//

import Foundation
import Testing
import ZCCalendar
@testable import Off_Day

struct DayDetailIntentEntityTests {
    @Test func dayDetailEntityHashAndEqualityShouldOnlyDependOnId() throws {
        let day = GregorianDay(year: 2026, month: .jan, day: 1)
        let date = try #require(day.generateDate(secondsFromGMT: Calendar.current.timeZone.secondsFromGMT()))

        let lhs = DayDetailEntity(
            id: day.julianDay,
            date: date,
            finalOffDay: true,
            userOffDay: nil,
            publicOffDay: true,
            baseOffDay: false,
            publicDayName: "Holiday",
            userComment: "A"
        )
        let sameIdDifferentContent = DayDetailEntity(
            id: day.julianDay,
            date: date.addingTimeInterval(86_400),
            finalOffDay: false,
            userOffDay: false,
            publicOffDay: nil,
            baseOffDay: true,
            publicDayName: nil,
            userComment: nil
        )
        let differentId = DayDetailEntity(
            id: day.julianDay + 1,
            date: date,
            finalOffDay: true,
            userOffDay: nil,
            publicOffDay: nil,
            baseOffDay: true,
            publicDayName: nil,
            userComment: nil
        )

        #expect(lhs == sameIdDifferentContent)
        #expect(lhs != differentId)

        let set: Set<DayDetailEntity> = [lhs, sameIdDifferentContent, differentId]
        #expect(set.count == 2)

        _ = lhs.displayRepresentation
    }

    @Test func dayIntentQueryShouldReturnEmptyCollections() async throws {
        let query = DayIntentQuery()

        let entities = try await query.entities(for: [12345, 67890])
        let suggested = try await query.suggestedEntities()

        #expect(entities.isEmpty)
        #expect(suggested.isEmpty)
    }
}
