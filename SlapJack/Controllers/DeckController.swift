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
    
    fileprivate let test_deck_id = "smt6qibmy08o"
    fileprivate let baseURL = "https://deckofcardsapi.com/api/deck/"
    
    /*
     additions to baseURL
     
    "new/" for a new deck
    "<deck_id>/shuffle/" to shuffle deck
    "<deck_id>/draw/?count=1" to draw a card
    */
    
    func getUnfinishedDeck(completion: @escaping (Deck?) -> Void) {
        let request: NSFetchRequest<Deck> = Deck.fetchRequest()
        do {
            var savedDecks = try Stack.context.fetch(request)
            
            if savedDecks.isEmpty {
                
                createDeck { (deck) in
                    completion(deck)
                }
                
            } else if savedDecks.count > 1 {
                
                let deck = savedDecks.removeFirst()
                print("Deleted unexpected decks in core data")
                for d in savedDecks {
                    Stack.context.delete(d)
                }
                
                saveDeck()
                completion(deck)
                return
                
            } else {
                completion(savedDecks.first)
                return
            }
            
            
            
        } catch {
            print("saved game could not be loaded")
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
                        
                        self.saveDeck()
                        self.shuffleDeck(deck)
                        
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
    
    //call when starting a new game
    func resetDeck(deck: Deck) {
        
        do {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Card.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try Stack.context.execute(deleteRequest)
        } catch {
            fatalError("failed to clear cards from deck")
        }
        
        shuffleDeck(deck)
        deck.cardsRemaining = 52
        saveDeck()
    }
    
    func drawCard(from deck: Deck, completion: @escaping (Card?) -> Void) {
        
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
                        let cardsDictionary = topDictionary["cards"] as? [Dictionary<String, Any>],
                        let card = cardsDictionary.first {
                        
                        deck.cardsRemaining = cardsLeft
                        completion(Card(dictionary: card))
                        self.saveDeck()
                        return
                    }
                } catch {
                    print("failed to decode card dictionary from json")
                    completion(nil)
                    return
                }
            }
            
            print("failed to decode card dictionary from data")
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
    
    func lastSavedCard() -> Card? {
        let fetchRequest: NSFetchRequest<Card> = Card.fetchRequest()
        do {
            let savedCards = try Stack.context.fetch(fetchRequest)
            return savedCards.last
        } catch {
            return nil
        }
    }
    
    func shuffleDeck(_ deck: Deck) {
        guard let id = deck.id else { fatalError("deck did not have an id") }
        let url = URL(string: baseURL + "\(id)/shuffle/")!
        
        NetworkController.performNetworkRequest(url: url) { (_, error) in
            if error != nil {
                print("there was an error shuffling the deck")
            } else {
                deck.cardsRemaining = 52
            }
            
            self.saveDeck()
        }
    }
    
    func saveDeck() {
        do {
            try Stack.context.save()
        } catch {
            print("failed to save deck")
        }
    }
    
    func deleteDeck(_ deck: Deck) {
        Stack.context.delete(deck)
        saveDeck()
    }
}
