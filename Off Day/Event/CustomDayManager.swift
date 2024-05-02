//
//  CustomDayManager.swift
//  Off Day
//
//  Created by zici on 2023/12/22.
//

import Foundation
import GRDB

struct CustomDayManager {
    static let shared: CustomDayManager = CustomDayManager()
    
    func fetch(completion: (([CustomDay]) -> ())? ) {
        AppDatabase.shared.reader?.asyncRead{ dbResult in
            do {
                let db = try dbResult.get()
                let customDayss = try CustomDay.fetchAll(db)
                DispatchQueue.main.async {
                    completion?(customDayss)
                }
            }
            catch {
                print(error)
            }
        }
    }
    
    func add(customDay: CustomDay) {
        // Check is there a same CustomDay before save
        guard customDay.id == nil else {
            return
        }
        _ = AppDatabase.shared.add(customDay: customDay)
    }
    
    func update(customDay: CustomDay) {
        guard customDay.id != nil else {
            return
        }
        _ = AppDatabase.shared.update(customDay: customDay)
    }
    
    func delete(customDay: CustomDay) {
        guard customDay.id != nil else {
            return
        }
        _ = AppDatabase.shared.delete(customDay: customDay)
    }
}
