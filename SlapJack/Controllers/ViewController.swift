//
//  ViewController.swift
//  SlapJack
//
//  Created by Gabriel Blaine Palmer on 1/15/19.
//  Copyright © 2019 Gabriel Blaine Palmer. All rights reserved.
//

import UIKit
import Network

class ViewController: UIViewController {
    
    @IBOutlet weak var cardsLeftView: ViewDesign!
    @IBOutlet weak var cardsLeftLabel: UILabel!
    
    @IBOutlet weak var gameOverView: UIView!
    @IBOutlet weak var jacksAmountLabel: UILabel!
    @IBOutlet weak var cardsAmountLabel: UILabel!
    @IBOutlet weak var missedAmountLabel: UILabel!
    
    @IBOutlet weak var cardImageView: UIImageView!
    
    let monitor = NWPathMonitor()
    var connectedToNetwork = true
    
    var timer: Timer?
    var deck: Deck?
    var currentCard: Card?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //called when connection changes
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                self.connectedToNetwork = true
            } else {
                self.connectedToNetwork = false
            }
        }
        let queue = DispatchQueue(label: "monitor")
        monitor.start(queue: queue)

        loadDeckForGame()
        if let date = deck?.lastAccessed {
            print(date.description)
        }
        view.updateBackground()
    }
    
    func loadDeckForGame() {
        
        DeckController.shared.getUnfinishedDeck { (incompleteDeck) in
            if let unwrappedDeck = incompleteDeck {
                guard let date = unwrappedDeck.lastAccessed else { fatalError("deck did not have a date") }
                
                //check if two weeks have passed and deck expired
                if date.timeIntervalSinceNow > 1209600.0 {
                    DeckController.shared.deleteDeck(unwrappedDeck)
                    DeckController.shared.createDeck(completion: { (newDeck) in
                        guard let newDeck = newDeck else { fatalError("could not connect to deckofcards API") }
                        self.deck = newDeck
                    })
                } else {
                    //successfully got saved deck
                    self.deck = unwrappedDeck
                }
            } else {
                //runs when app is started the very first time
                DeckController.shared.createDeck(completion: { (newDeck) in
                    guard let newDeck = newDeck else { fatalError("could not connect to deckofcards API") }
                    self.deck = newDeck
                })
            }
        }
        
        //info on deck when app loads
        if let deck = deck, let date = deck.lastAccessed {
            print("cards left: \(deck.cardsRemaining)\nlast accessed: \(date.formatToString(style: .long))")
            deck.lastAccessed = Date()
            cardsLeftLabel.text = String(deck.cardsRemaining)
        }
        
        //update currentCard to last card from previous game
        currentCard = DeckController.shared.lastSavedCard()
        updateCardImage()
    }
    
    func drawCard() {
        
        //temporary safety measure
        if let deck = deck, deck.cardsRemaining == 0 {
            print("out of cards")
            return
        }
        
        guard let deck = deck else { fatalError("handle error here") }
        
        DeckController.shared.drawCard(from: deck) { (card) in
            if let card = card {
                self.currentCard = card
                self.updateCardImage()
                DispatchQueue.main.async {
                    self.cardsLeftLabel.text = String(deck.cardsRemaining)
                }
            } else {
                fatalError("handle error here")
            }
        }
    }
    
    
    func updateCardImage() {
        //if currentCard is nil then you must be starting a new game so show card back
        
        if let card = currentCard, let url = card.imageURL {
            DeckController.shared.imageForCard(imageURL: url, completion: { (image) in
                DispatchQueue.main.async {
                    self.cardImageView.image = image
                }
            })
        } else {
            cardImageView.image = UIImage(named: "cardBack")
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if UIDevice.current.orientation.isPortrait || UIDevice.current.orientation.isLandscape {
            view.updateBackground(size: size)
        }
    }
    
    //========================================
    // MARK: - Actions
    //========================================
    
    @IBAction func startGameButtonTapped(_ sender: Any) {
        
        //reset deck when starting new game
        
        drawCard()
    }
    
}

//========================================
// MARK: - Extensions
//========================================

extension Date {
    func formatToString(style: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = style
        return formatter.string(from: self)
    }
}
