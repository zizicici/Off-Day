//
//  IntentMetadataTests.swift
//  UnitTests
//
//  Created by Codex on 2026/2/13.
//

import Foundation
import Testing
@testable import Off_Day

struct IntentMetadataTests {
    @Test func fetchErrorLocalizedResourcesShouldBeResolvableAndDistinct() {
        let overReach = String(localized: FetchError.overReach.localizedStringResource)
        let notFound = String(localized: FetchError.notFound.localizedStringResource)

        #expect(!overReach.isEmpty)
        #expect(!notFound.isEmpty)
        #expect(overReach != notFound)
    }

    @Test func dayMarkShouldExposeRawValuesAndDisplayRepresentations() {
        #expect(DayMark(rawValue: "off") == .off)
        #expect(DayMark(rawValue: "work") == .work)
        #expect(DayMark(rawValue: "blank") == .blank)

        let allCases: [DayMark] = [.off, .work, .blank]
        #expect(DayMark.caseDisplayRepresentations.count == allCases.count)
        #expect(allCases.allSatisfy { DayMark.caseDisplayRepresentations[$0] != nil })

        _ = DayMark.typeDisplayRepresentation
    }
}
