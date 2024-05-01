//
//  TwoSourceOption.swift
//  Off Day
//
//  Created by zici on 2024/1/3.
//

import Foundation

protocol SettingsOption: Hashable, Equatable {
    func getName() -> String
    static func getHeader() -> String?
    static func getFooter() -> String?
    static func getTitle() -> String
    static func getOptions() -> [Self]
    static var current: Self { get set}
}

extension SettingsOption {
    static func getHeader() -> String? {
        return nil
    }
    
    static func getFooter() -> String? {
        return nil
    }
}

extension SettingsOption {
    static func == (lhs: Self, rhs: Self) -> Bool {
        if type(of: lhs) != type(of: rhs) {
            return false
        } else {
            return lhs.getName() == rhs.getName()
        }
    }
}

enum TwoSourceOption<T>: Hashable where T: SettingsOption {
    case userDefault
    case per(T)
    
    static func title() -> String {
        return T.getTitle()
    }
    
    func name() -> String {
        switch self {
        case .userDefault:
            return String(format: (String(localized: "settings.default.%@")), T.current.getName())
        case .per(let t):
            return t.getName()
        }
    }
    
    func option() -> T {
        switch self {
        case .userDefault:
            return T.current
        case .per(let t):
            return t
        }
    }
}
