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
    var timer: Timer?
    var deck: Deck?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //called when connection changes
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {

            } else {

            }
        }
        let queue = DispatchQueue(label: "monitor")
        monitor.start(queue: queue)


        
        
        //loadGame()
        view.updateBackground()
    }
    
    func loadDeckForGame() {
        
        DeckController.shared.getUnfinishedDeck { (incompleteDeck) in
            if let unwrappedDeck = incompleteDeck {
                guard let date = unwrappedDeck.dateCreated else { fatalError("deck did not have a date") }
                
                //check if two weeks have passed
                if date.timeIntervalSinceNow > 1209600.0 {
                    DeckController.shared.deleteDeck(unwrappedDeck)
                    DeckController.shared.createDeck(completion: { (newDeck) in
                        guard let newDeck = newDeck else { fatalError("could not connect to deckofcards API") }
                        self.deck = newDeck
                    })
                }
            } else {
                DeckController.shared.createDeck(completion: { (newDeck) in
                    guard let newDeck = newDeck else { fatalError("could not connect to deckofcards API") }
                    self.deck = newDeck
                })
            }
        }
        
        //deck now holds the correct value
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if UIDevice.current.orientation.isPortrait || UIDevice.current.orientation.isLandscape {
            view.updateBackground(size: size)
        }
    }
}

