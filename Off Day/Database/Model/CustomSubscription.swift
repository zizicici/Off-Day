//
//  CustomSubscription.swift
//  Off Day
//
//  Created by Ci Zi on 2025/5/27.
//

import Foundation
import GRDB
import ZCCalendar

struct CustomSubscription: Identifiable, Hashable {
    var id: Int64?
    
    var creationTime: Int64?
    var modificationTime: Int64?
    
    var url: String
}

extension CustomSubscription: Codable {
    enum Columns: String, ColumnExpression {
        case id
        case url

        static let creationTime = Column(CodingKeys.creationTime)
        static let modificationTime = Column(CodingKeys.modificationTime)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, creationTime = "creation_time", modificationTime = "modification_time", url
    }
}

extension CustomSubscription: TableRecord {
    static var databaseTableName: String = "custom_subscription"
}

extension CustomSubscription: FetchableRecord {
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

extension CustomSubscription: TimestampedRecord {
    
}

extension CustomSubscription {
    static let fetchResults = hasMany(CustomSubscriptionFetchResult.self).forKey("fetchResults")
    
    var fetchResults: QueryInterfaceRequest<CustomSubscriptionFetchResult> {
        request(for: CustomSubscription.fetchResults)
    }
}

struct CustomSubscriptionFetchResult: Identifiable, Hashable {
    var id: Int64?
    
    var creationTime: Int64?
    var modificationTime: Int64?
    
    var isSuccess: Bool
    
    var errorCode: String?
    var errorMessage: String?
    
    var start: GregorianDay?
    var end: GregorianDay?
    
    var sum: Int?
    var addCount: Int?
    var deleteCount: Int?
    var updateCount: Int?
    
    var subscriptionId: Int64
}

extension CustomSubscriptionFetchResult: Codable {
    enum Columns: String, ColumnExpression {
        case id
        
        static let creationTime = Column(CodingKeys.creationTime)
        static let modificationTime = Column(CodingKeys.modificationTime)
        static let isSuccess = Column(CodingKeys.isSuccess)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, creationTime = "creation_time", modificationTime = "modification_time", isSuccess = "is_success", errorCode = "error_code", errorMessage = "error_message", start, end, sum, addCount = "add_count", deleteCount = "delete_count", updateCount = "update_count", subscriptionId = "subscription_id"
    }
}

extension CustomSubscriptionFetchResult: TableRecord {
    static var databaseTableName: String = "custom_subscription_fetch_result"
}

extension CustomSubscriptionFetchResult: FetchableRecord {
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

extension CustomSubscriptionFetchResult: TimestampedRecord {
    
}
