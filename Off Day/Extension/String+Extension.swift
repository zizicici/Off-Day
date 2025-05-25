//
//  String+Extension.swift
//  Off Day
//
//  Created by Ci Zi on 28/4/25.
//

import Foundation

extension String {
    static func assembleDetail(for dayType: DayType, publicDayName: String?, baseCalendarDayType: DayType, publicDayType: DayType?, customDayType: DayType?, customComment: String?) -> Self {
        return String(format: (String(localized: "dayDetail.%@%@%@%@%@%@")), dayType.title, publicDayName != nil ? "[\(publicDayName!)]" : "", baseCalendarDayType.title, (publicDayType?.title ?? String(localized: "dayDetail.noInformation")), (customDayType?.title ?? String(localized: "dayDetail.noInformation")), (customComment != nil ? String(format: String(localized: "comment.%@"), customComment!) : String(localized: "comment.empty")))
    }
}
