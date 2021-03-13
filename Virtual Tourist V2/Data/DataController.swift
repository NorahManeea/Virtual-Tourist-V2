//
//  DataController.swift
//  Virtual Tourist V2
//
//  Created by Norah Almaneea on 13/03/2021.
//

import Foundation
import CoreData

class DataController {
    
    static let shared = DataController()
    
    let persistentContainer = NSPersistentContainer(name: "VirtualTourist")
    
    var viewContext:NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func load(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores {storeDescription, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            completion?()
        }
    }
    
    func save() throws {
        if viewContext.hasChanges {
            try viewContext.save()
        }
    }
}
