//
//  UtilityExtensionTests.swift
//  UnitTests
//
//  Created by Codex on 2026/2/13.
//

import Foundation
import Testing
@testable import Off_Day

private actor DebounceRecorder {
    private var values: [Int] = []
    
    func append(_ value: Int) {
        values.append(value)
    }
    
    func snapshot() -> [Int] {
        return values
    }
}

struct UtilityExtensionTests {
    @Test func blankStringChecksShouldMatchCurrentBehavior() {
        #expect("   \n\t".isBlank)
        #expect(!" a ".isBlank)
        
        let nilString: String? = nil
        let whitespaceString: String? = "   "
        let textString: String? = "abc"
        
        #expect(nilString.isBlank)
        #expect(whitespaceString.isBlank)
        #expect(!textString.isBlank)
    }
    
    @Test func commentLengthValidationShouldRespect200Limit() {
        let maxAllowed = String(repeating: "a", count: 200)
        let tooLong = String(repeating: "a", count: 201)
        
        #expect(maxAllowed.isValidComment())
        #expect(!tooLong.isValidComment())
    }
    
    @Test func dateNanoSecondRoundTripShouldPreserveStoredValue() {
        let storedValue: Int64 = 1_735_689_123_456
        let date = Date(nanoSecondSince1970: storedValue)
        
        #expect(date.nanoSecondSince1970 == storedValue)
    }
    
    @Test func debounceShouldEmitOnlyLatestValueWhenEventsAreFrequent() async throws {
        let recorder = DebounceRecorder()
        let debounce = Debounce<Int>(duration: 0.05) { value in
            await recorder.append(value)
        }
        
        debounce.emit(value: 1)
        debounce.emit(value: 2)
        debounce.emit(value: 3)
        
        try await Task.sleep(for: .milliseconds(150))
        
        let values = await recorder.snapshot()
        #expect(values == [3])
    }
}
