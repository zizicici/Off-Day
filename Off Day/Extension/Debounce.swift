//
//  Debounce.swift
//  Off Day
//
//  Created by zici on 14/12/24.
//

import Foundation

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}

final class Debounce<T> {
    private let block: @Sendable (T) async -> Void
    private let duration: Double
    private var task: Task<Void, Never>?
    
    init(
        duration: Double,
        block: @Sendable @escaping (T) async -> Void
    ) {
        self.duration = duration
        self.block = block
    }
    
    func emit(value: T) {
        self.task?.cancel()
        self.task = Task { [duration, block] in
            do {
                if #available(iOS 16.0, *) {
                    try await Task.sleep(for: .seconds(duration))
                } else {
                    try await Task.sleep(seconds: duration)
                }
                await block(value)
            } catch {}
        }
    }
}
