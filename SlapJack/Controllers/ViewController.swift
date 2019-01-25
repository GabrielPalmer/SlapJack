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
        view.updateBackground()
        
        DeckController.shared.loadDeck { (savedDeck) in
            if let unwrappedDeck = savedDeck,
                let date = unwrappedDeck.lastAccessed,
                let id = unwrappedDeck.id,
                self.connectedToNetwork {
                
                self.deck = unwrappedDeck
                
                print("Deck Info\nid: \(id)\ncards left: \(unwrappedDeck.cardsRemaining)\nlast accessed: \(date.formatToString(style: .long))")
                
                if unwrappedDeck.cardsRemaining == 0 || unwrappedDeck.cardsRemaining == 52 {
                    self.newGame()
                } else {
                    self.continueGame()
                }
            } else {
                let alertController = UIAlertController(
                    title: "Unable to connect to the required API\nTry again later with a better network connection",
                    message: nil,
                    preferredStyle: .alert)
                
                alertController.addAction(UIAlertAction(
                    title: "OK",
                    style: .default,
                    handler: { (_) in
                        fatalError("no internet connection")
                }))
            }
        }
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        //called when connection changes
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                self.connectedToNetwork = true
            } else {
                self.connectedToNetwork = false
                if self.paused == false {
                    self.paused = true
                }
            }
        }
        let queue = DispatchQueue(label: "monitor")
        monitor.start(queue: queue)
    }
    
    //========================================
    // MARK: - Functions
    //========================================
    
    func newGame() {
        self.startGameButton.isHidden = false
        self.cardImageView.isHidden = false
        cardsLeftView.isHidden = true
        cardsLeftLabel.text = "52"
        currentCardInfo = nil
        paused = nil
    }
    
    //should only be called once, when the app starts each time
    func continueGame() {
        cardsLeftLabel.text = String(deck.cardsRemaining)
        cardsLeftView.isHidden = false
        startGameButton.isHidden = true
        paused = true
    }
    
    func endGame() {
        let gameInfo = DeckController.shared.slappedCardsInfo(for: deck)
        
        //updated date here to ensure you actually used the api
        //reset the deck here in case they exit from the game over view
        deck.lastAccessed = Date()
        DeckController.shared.resetDeck(deck) {
            //self.gameOverView.isHidden = false
            self.showGameOverView(true)
        }
        
        cardsLeftView.isHidden = true
        pauseButton.isHidden = true
        cardImageView.isHidden = true
        
        jacksAmountLabel.text = "\(gameInfo["jacks"]!) out of 4"
        cardsAmountLabel.text = String(gameInfo["other"]!)
        
    }
    
    func drawCard() {
        
        //deck.cardsRemaing is updated in the deck controller
        DeckController.shared.drawCard(from: deck) { (card) in
            if let card = card {
                self.currentCardInfo = card
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
                    self.cardsLeftLabel.text = String(self.deck.cardsRemaining)
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
    
    @objc func appMovedToBackground() {
        if paused == false {
            paused = true
        }
    }
    
    func showNetworkFailure() {
        let alertController = UIAlertController(
            title: "No network connection detected\nTry again later",
            message: nil,
            preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(
            title: "OK",
            style: .default,
            handler: nil))
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
            let paused = paused,
            let wasSlapped = currentCard["wasSlapped"] as? Bool,
            !paused, !wasSlapped {
            
            let _ = Card(dictionary: currentCard)
            self.currentCardInfo!["wasSlapped"] = true
            
            DeckController.shared.saveDeck()
            
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
        showGameOverView(false)
        //gameOverView.isHidden = true
        newGame()
    }
    
    @IBAction func pauseButtonTapped(_ sender: Any) {
        guard let unwrappedPaused = paused else {
            print("unable to pause")
            return
        }
        
        if paused == false, !connectedToNetwork {
            showNetworkFailure()
            return
        }
        
        UIView.animate(withDuration: 0.15, animations: {
            self.pauseButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { (_) in
            self.pauseButton.transform = .identity
        }
        
        paused = !unwrappedPaused
    }
    
    @IBAction func cardImageViewTapped(_ sender: Any) {
        //timer?.fire()
    }
    
    //========================================
    // MARK: - Animations
    //========================================
    
    func showGameOverView(_ show: Bool) {
        DispatchQueue.main.async {
            
            if show {
                self.gameOverView.alpha = 0
                self.gameOverView.isHidden = false
                UIView.animate(withDuration: 2.0) {
                    self.gameOverView.alpha = 1
                }
            } else {
                self.gameOverView.alpha = 1
                UIView.animate(withDuration: 2.0, animations: {
                    self.gameOverView.alpha = 0
                }, completion: { (_) in
                    self.gameOverView.isHidden = true
                })
            }
            
        }
    }
    
    func showStartGameButton(_ show: Bool) {
        DispatchQueue.main.async {
            self.startGameButton.isHidden = false
            if show {
                
                UIView.animate(withDuration: 1.5, animations: {
                    self.startGameButton.transform = .identity
                })
            } else {
                UIView.animate(withDuration: 1.5, animations: {
                    self.startGameButton.transform = CGAffineTransform(translationX: 0, y: -120)
                })
            }
            
        }
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
