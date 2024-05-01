//
//  EventManager.swift
//  Off Day
//
//  Created by zici on 2023/12/22.
//

import Foundation
import GRDB

struct EventManager {
    static let shared: EventManager = EventManager()
    
    func fetch(completion: (([Event]) -> ())? ) {
        AppDatabase.shared.reader?.asyncRead{ dbResult in
            do {
                let db = try dbResult.get()
                let events = try Event.fetchAll(db)
                DispatchQueue.main.async {
                    completion?(events)
                }
            }
            catch {
                print(error)
            }
        }
    }
    
    func add(event: Event) {
        // Check is there a same event before save
        guard event.id == nil else {
            return
        }
        _ = AppDatabase.shared.add(event: event)
    }
    
    func update(event: Event) {
        guard event.id != nil else {
            return
        }
        _ = AppDatabase.shared.update(event: event)
    }
    
    func delete(event: Event) {
        guard event.id != nil else {
            return
        }
        _ = AppDatabase.shared.delete(event: event)
    }
}
