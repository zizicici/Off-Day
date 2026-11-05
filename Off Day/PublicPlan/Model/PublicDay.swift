//
//  PublicDay.swift
//  Off Day
//
//  Created by zici on 11/5/24.
//

import Foundation
import ZCCalendar

protocol PublicDay: Hashable {
    var name: String { get set }
    var localizedNames: [String: String]? { get set }
    var date: GregorianDay { get set }
    var type: DayType { get set }
}

extension PublicDay {
    /// `name` remains the fallback for legacy templates and missing translations.
    func localizedName(language: String?) -> String {
        guard let language else { return name }
        let localizedNames = localizedNames ?? [:]
        let orderedNames = localizedNames.sorted { $0.key < $1.key }
        for identifier in PublicPlanLanguage.fallbacks(for: language) {
            if let value = localizedNames[identifier], !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return value
            }
            let canonical = PublicPlanLanguage.identifier(identifier)
            if let match = orderedNames.first(where: {
                PublicPlanLanguage.identifier($0.key) == canonical &&
                !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }) {
                return match.value
            }
        }
        return name
    }

    func isEqual(_ otherDay: (any PublicDay)?) -> Bool {
        guard let otherDay, Swift.type(of: self) == Swift.type(of: otherDay) else {
            return false
        }
        return AnyHashable(self) == AnyHashable(otherDay)
    }
}
