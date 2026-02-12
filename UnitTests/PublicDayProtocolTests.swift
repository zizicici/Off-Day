//
//  PublicDayProtocolTests.swift
//  UnitTests
//
//  Created by Codex on 2026/2/13.
//

import Testing
import ZCCalendar
@testable import Off_Day

struct PublicDayProtocolTests {
    @Test func isEqualShouldReturnTrueForSameConcreteTypeAndValue() {
        let day = GregorianDay(year: 2026, month: .jan, day: 1)
        let lhs = JSONPublicDay(name: "Holiday", date: day, type: .offDay)
        let rhs = JSONPublicDay(name: "Holiday", date: day, type: .offDay)
        
        #expect(lhs.isEqual(rhs))
    }
    
    @Test func isEqualShouldReturnFalseForDifferentConcreteType() {
        let day = GregorianDay(year: 2026, month: .jan, day: 1)
        let lhs = JSONPublicDay(name: "Holiday", date: day, type: .offDay)
        let rhs = CustomPublicDay(name: "Holiday", date: day, type: .offDay)
        
        #expect(!lhs.isEqual(rhs))
    }
    
    @Test func isEqualShouldReturnFalseWhenTargetIsNil() {
        let day = GregorianDay(year: 2026, month: .jan, day: 1)
        let lhs = JSONPublicDay(name: "Holiday", date: day, type: .offDay)
        
        #expect(!lhs.isEqual(nil))
    }
}
