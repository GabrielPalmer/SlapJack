//
//  Deck.swift
//  SlapJack
//
//  Created by Gabriel Blaine Palmer on 1/16/19.
//  Copyright © 2019 Gabriel Blaine Palmer. All rights reserved.
//

import Foundation
import CoreData

extension Deck {
    convenience init?(dictionary: Dictionary<String, Any>, context: NSManagedObjectContext = Stack.context) {
        
        guard let id = dictionary["deck_id"] as? String,
            let remaining = dictionary["remaining"] as? Int16
            else { return nil }
        
        self.init(context: context)
        self.id = id
        self.cardsRemaining = remaining
        self.dateCreated = Date()
    }
}
