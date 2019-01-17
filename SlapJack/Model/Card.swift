//
//  Card.swift
//  SlapJack
//
//  Created by Gabriel Blaine Palmer on 1/16/19.
//  Copyright © 2019 Gabriel Blaine Palmer. All rights reserved.
//

import Foundation
import CoreData

extension Card {
    convenience init?(dictionary: Dictionary<String, Any>, context: NSManagedObjectContext = Stack.context) {
        
        guard let suit = dictionary["suit"] as? String,
            let value = dictionary["value"] as? String,
            let imageURL = dictionary["image"] as? String
            else { return nil }
        
        self.init(context: context)
        self.suit = suit
        self.value = value
        self.imageURL = imageURL
        self.wasSlapped = false
    }
    
}
