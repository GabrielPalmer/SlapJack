//
//  ViewController.swift
//  SlapJack
//
//  Created by Gabriel Blaine Palmer on 1/15/19.
//  Copyright © 2019 Gabriel Blaine Palmer. All rights reserved.
//

import UIKit
import Network
import CoreData

class ViewController: UIViewController {
    
    @IBOutlet weak var cardsLeftView: ViewDesign!
    @IBOutlet weak var cardsLeftLabel: UILabel!
    
    @IBOutlet weak var gameOverView: UIView!
    @IBOutlet weak var jacksAmountLabel: UILabel!
    @IBOutlet weak var cardsAmountLabel: UILabel!
    
    @IBOutlet weak var startGameButton: ButtonDesign!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var cardImageView: UIImageView!
    
    let monitor = NWPathMonitor()
    var connectedToNetwork = true
    
    var deck: Deck!
    var currentCardInfo: Dictionary<String, Any>? {
        didSet {
            updateCardImage()
        }
    }
    
    var timer: Timer?
    var pausedImage = UIImage(named: "cardBack") //used to hold current card image between pauses
    var paused: Bool? {
        //when set to nil, pause and hide
        didSet {
            if let paused = paused {
                pauseButton.isHidden = false
                if paused {
                    timer?.invalidate()
                    pauseButton.setBackgroundImage(UIImage(named: "play"), for: .normal)
                    pausedImage = cardImageView.image
                    cardImageView.image = UIImage(named: "cardBack")
                } else {
                    pauseButton.setBackgroundImage(UIImage(named: "pause"), for: .normal)
                    cardImageView.image = pausedImage
                    let myTimer = Timer(timeInterval: 1.0, target: self, selector: #selector(timerFired(sender:)), userInfo: nil, repeats: true)
                    timer = myTimer
                    RunLoop.current.add(myTimer, forMode: .common)
                }
            } else {
                timer?.invalidate()
                pauseButton.isHidden = true
            }
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        DeckController.shared.loadDeck { (savedDeck) in
            if let unwrappedDeck = savedDeck,
                let date = unwrappedDeck.lastAccessed,
                let id = unwrappedDeck.id {
                self.deck = unwrappedDeck
                
                print("Deck Info\nid: \(id)\ncards left: \(unwrappedDeck.cardsRemaining)\nlast accessed: \(date.formatToString(style: .long))")
                unwrappedDeck.lastAccessed = Date()
                
                //deck would have 0 cards if they played a game then quit before starting another
                //deck would have 52 cards if it was just created
                if unwrappedDeck.cardsRemaining == 0 || unwrappedDeck.cardsRemaining == 52 {
                    self.newGame()
                } else {
                    self.continueGame()
                }
            } else {
                //close app here
                fatalError("error with api")
            }
        }
        
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
        
        view.updateBackground()
        
    }
    
    //========================================
    // MARK: - Functions
    //========================================
    
    func newGame() {
        DeckController.shared.resetDeck(deck)
        cardImageView.isHidden = false
        cardsLeftView.isHidden = true
        cardsLeftLabel.text = "52"
        currentCardInfo = nil
        paused = nil
        startGameButton.isHidden = false
    }
    
    //should only be called once, when the app starts each time
    func continueGame() {
        cardsLeftLabel.text = String(deck.cardsRemaining)
        cardsLeftView.isHidden = false
        startGameButton.isHidden = true
        paused = true
    }
    
    func endGame() {
        cardsLeftView.isHidden = true
        pauseButton.isHidden = true
        cardImageView.isHidden = true
        
        let gameInfo = DeckController.shared.slappedCardsInfo(for: deck)
        
        jacksAmountLabel.text = "\(gameInfo["jacks"]!) out of 4"
        cardsAmountLabel.text = String(gameInfo["other"]!)
        
        gameOverView.isHidden = false
    }
    
    func drawCard() {
        
        DeckController.shared.drawCard(from: deck) { (card) in
            if let card = card {
                self.currentCardInfo = card
                DispatchQueue.main.async {
                    self.cardsLeftLabel.text = String(self.deck.cardsRemaining)
                }
            } else {
                fatalError("did not draw a card")
            }
        }
    }
    
    func updateCardImage() {
        //if currentCard is nil then you must be starting a new game so show card back
        
        if let card = currentCardInfo, let url = card["image"] as? String {
            DeckController.shared.imageForCard(imageURL: url, completion: { (image) in
                DispatchQueue.main.async {
                    self.cardImageView.image = image
                }
            })
        } else {
            cardImageView.image = UIImage(named: "cardBack")
        }
    }
    
    @objc func timerFired(sender: Timer) {
        if deck.cardsRemaining > 0 {
            drawCard()
        } else {
            timer?.invalidate()
            endGame()
        }
    }
    
    //========================================
    // MARK: - Device Motions
    //========================================

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if UIDevice.current.orientation.isPortrait || UIDevice.current.orientation.isLandscape {
            view.updateBackground(size: size)
        }
    }
    
    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        
        if let currentCard = currentCardInfo,
            let cardEntity = Card(dictionary: currentCard),
            let paused = paused, !paused {
            
            deck.addToSlappedCards(cardEntity)
            DeckController.shared.saveDeck()
            
            //immediatly advance to next card so
            //stops currentCard from being added twice
            timer?.fire()
        } else {
            print("slapped at invalid time")
        }
    }
    
    //========================================
    // MARK: - Actions
    //========================================
    
    @IBAction func startGameButtonTapped(_ sender: Any) {
        cardsLeftView.isHidden = false
        startGameButton.isHidden = true //animate
        paused = false
    }
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        gameOverView.isHidden = true
        newGame()
    }
    
    @IBAction func pauseButtonTapped(_ sender: Any) {
        guard let unwrappedPaused = paused else {
            print("unable to pause")
            return
            
        }
        paused = !unwrappedPaused
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
