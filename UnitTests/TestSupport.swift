//
//  TestSupport.swift
//  UnitTests
//
//  Created by Codex on 2026/2/13.
//

import Foundation
@testable import Off_Day

enum TestFileHelper {
    static func writeTempFile(_ content: String, fileName: String = UUID().uuidString + ".json") throws -> URL {
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        guard let data = content.data(using: .utf8) else {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
        }
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }
}
