//
//  Date+Extension.swift
//  Off Day
//
//  Created by zici on 2023/12/22.
//

import Foundation

extension Date {
    var nanoSecondSince1970: Int64 {
        return Int64(timeIntervalSince1970 * 1000.0)
    }
    
    init(nanoSecondSince1970: Int64) {
        self.init(timeIntervalSince1970: Double(nanoSecondSince1970) / 1000.0)
    }
}
