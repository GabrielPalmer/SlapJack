//
//  Stack.swift
//  SlapJack
//
//  Created by Gabriel Blaine Palmer on 1/15/19.
//  Copyright © 2019 Gabriel Blaine Palmer. All rights reserved.
//

import Foundation
import CoreData

enum Stack {
    static let container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "SlapJack")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            print(storeDescription) //to find SQlite file
            if let error = error {
                fatalError("unresolved error \(error)")
            }
        })
        
        return container
    }()
    
    static var context: NSManagedObjectContext {
        return container.viewContext
    }
}

//how to delete all entities from context

//    do {
//    let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Person.fetchRequest()
//    let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
//    try context.execute(deleteRequest)
//    } catch {
//    print("fail")
//    }
