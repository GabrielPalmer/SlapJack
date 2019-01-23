//
//  DeckController.swift
//  SlapJack
//
//  Created by Gabriel Blaine Palmer on 1/16/19.
//  Copyright © 2019 Gabriel Blaine Palmer. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class DeckController {
    static let shared = DeckController()
    
    // kqp0keeem4bz
    fileprivate let baseURL = "https://deckofcardsapi.com/api/deck/"
    
    /*
     additions to baseURL
     
    "new/" for a new deck
    "<deck_id>/shuffle/" to shuffle deck
    "<deck_id>/draw/?count=1" to draw a card
    */
    
    func loadDeck(completion: @escaping (Deck?) -> Void) {
        var deck: Deck?
        let request: NSFetchRequest<Deck> = Deck.fetchRequest()
        
        let networkGroup = DispatchGroup()
        networkGroup.enter()
        
        do {
            var savedDecks = try Stack.context.fetch(request)
            
            if savedDecks.isEmpty {
                
                createDeck { (newDeck) in
                    deck = newDeck
                    networkGroup.leave()
                }
                
            } else if savedDecks.count > 1 {
                
                deck = savedDecks.removeFirst()
                print("Deleted unexpected decks in core data")
                for d in savedDecks {
                    deleteDeck(d)
                }
                
                saveDeck()
                networkGroup.leave()
                
            } else {
                //saved deck loaded successfully
                deck = savedDecks.first
                networkGroup.leave()
            }
            
        } catch {
            print("saved game could not be loaded")
            
            do {
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Deck.fetchRequest()
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                try Stack.context.execute(deleteRequest)
            } catch {
                fatalError("failed to delete saved deck")
            }
            
            createDeck { (newDeck) in
                deck = newDeck
                networkGroup.leave()
            }
        }
        
        //deck now holds the correct value
        
        networkGroup.wait()
        
        if let unwrappedDeck = deck {
            guard let date = unwrappedDeck.lastAccessed else { fatalError("deck did not have a date") }
            
            //check if two weeks have passed and deck expired
            if date.timeIntervalSinceNow > 1209600.0 {
                deleteDeck(unwrappedDeck)
                createDeck(completion: { (newDeck) in
                    if let newDeck = newDeck {
                        completion(newDeck)
                        return
                    } else {
                        completion(nil)
                        return
                    }
                })
            } else {
                completion(unwrappedDeck)
                return
            }
        } else {
            completion(nil)
            return
        }
        
    }
    
    
    //call when deck doesn't exist when app first runs or deck expired
    func createDeck(completion: @escaping (Deck?) -> Void) {
        
        let url = URL(string: baseURL + "new/")!
        
        NetworkController.performNetworkRequest(url: url) { (data, error) in
            
            if error != nil {
                print(error.debugDescription)
                completion(nil)
                return
            }
            
            if let data = data  {
                do {
                    let jsonObjects = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                    if let dictionary = jsonObjects as? Dictionary<String, Any>,
                        let deck = Deck(dictionary: dictionary),
                        let id = deck.id {
                        
                        self.resetDeck(deck)
                        
                        print("new deck created with id: \(id)")
                        completion(deck)
                        return
                    }
                } catch {
                    print("failed to decode new deck from json")
                    completion(nil)
                    return
                }
            }
            
            print("failed to create new deck from data")
            completion(nil)
            return
            
        }
    }
    
    
    func resetDeck(_ deck: Deck, completion: @escaping () -> Void) {
        
        do {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Card.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try Stack.context.execute(deleteRequest)
        } catch {
            fatalError("failed to clear cards from deck")
        }
        
        guard let id = deck.id else { fatalError("deck did not have an id") }
        let url = URL(string: baseURL + "\(id)/shuffle/")!
        
        NetworkController.performNetworkRequest(url: url) { (_, error) in
            DispatchQueue.main.async {
                if error != nil {
                    print("there was an error shuffling the deck")
                } else {
                    deck.cardsRemaining = 52
                }
                
                self.saveDeck()
            }
        }
    }
    
    
    func drawCard(from deck: Deck, completion: @escaping (Dictionary<String, Any>?) -> Void) {
        
        guard let id = deck.id else { fatalError("deck did not have an id") }
        let url = URL(string: baseURL + "\(id)/draw/?count=1")!
        
        NetworkController.performNetworkRequest(url: url) { (data, error) in
            if error != nil {
                print("card could not be drawn")
                print(error.debugDescription)
                completion(nil)
                return
            }
            
            if let data = data {
                do {
                    let jsonObjects = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                    if let topDictionary = jsonObjects as? Dictionary<String, Any>,
                        let cardsLeft = topDictionary["remaining"] as? Int16,
                        let cardsDictionary = topDictionary["cards"] as? [Dictionary<String, Any>] {
                        
                        DispatchQueue.main.async {
                            deck.cardsRemaining = cardsLeft
                        }
                        
                        completion(cardsDictionary.first)
                        return
                    }
                } catch {
                    print("failed to decode card dictionary from json")
                    completion(nil)
                    return
                }
            }
            
            print("no data returned")
            completion(nil)
            return
            
        }
    }
    
    
    func imageForCard(imageURL: String, completion: @escaping (UIImage) -> Void) {
        NetworkController.performNetworkRequest(url: URL(string: imageURL)!) { (data, error) in
            if let data = data, let image = UIImage(data: data) {
                completion(image)
            } else {
                completion(UIImage(named: "defaultCard")!)
            }
        }
    }
    
    
    func slappedCardsInfo(for deck: Deck) -> Dictionary<String, Int> {
        
        var info: Dictionary<String, Int> = ["jacks" : 0, "other" : 0]
        
        guard let cards = deck.slappedCards?.allObjects as? [Card], cards.count > 0 else {
            return info
        }
        
        for card in cards {
            if card.value == "JACK" {
                info["jacks"]! += 1
            } else {
                info["other"]! += 1
            }
        }
        
        return info
    }
    
    @discardableResult
    func saveDeck() -> Bool {
        do {
            try Stack.context.save()
            return true
        } catch {
            print("failed to save deck")
            print(error)
            return false
        }
    }
    
    
    //called when deleting an expired deck or unexpected decks from load
    fileprivate func deleteDeck(_ deck: Deck) {
        Stack.context.delete(deck)
        saveDeck()
    }
}
