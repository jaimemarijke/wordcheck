//
//  ViewController.swift
//  Word Checker
//
//  Created by Jaime McCandless on 1/20/18.
//  Copyright © 2018 Jaime. All rights reserved.
//

import UIKit
import StoreKit
import Alamofire
import SafariServices

let NO_NETWORK_ERROR_MESSAGE = "Definitions require internet connection"
let NO_DEFINITION_ERROR_MESSAGE = "No definitions found"
let WORD_LIST_NAME = "twl2014"


class ViewController: UIViewController, UISearchBarDelegate {
    //MARK: Properties

    @IBOutlet weak var searchText: UISearchBar!
    @IBOutlet weak var searchDisplayText: UILabel!
    @IBOutlet weak var decisionText: UILabel!
    @IBOutlet weak var isText: UILabel!
    @IBOutlet weak var definitionText: UITextView!
    @IBOutlet weak var definitionLabel: UITextView!
    @IBOutlet weak var poweredBy: UIImageView!
    @IBOutlet weak var dumbBirdImage: UIImageView!
    @IBOutlet weak var purchaseDefinitionsButton: UIButton!
    
    var allowedWords: Set<String> = []
    var currentWord: String = ""
    
    // List of in-app purchased products
    var products = [SKProduct]()

    //MARK: Colors

    let flatRed = UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: 1)
    let flatGreen = UIColor(red: 39/255, green: 174/255, blue: 96/255, alpha: 1)

    //MARK: Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchText.delegate = self
        
        resetResultDisplay()

        allowedWords = loadWordList(fileName: WORD_LIST_NAME)
    
        // Let bird image be tappable to open "About" dialog
        let birdTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(birdImageTapped))
        dumbBirdImage.isUserInteractionEnabled = true
        dumbBirdImage.addGestureRecognizer(birdTapGestureRecognizer)
        
        // Let "Powered by WordNik" be tappable to open word definition
        let poweredByTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(wordNikImageTapped))
        poweredBy.isUserInteractionEnabled = true
        poweredBy.addGestureRecognizer(poweredByTapGestureRecognizer)
        
        // Look up available in-app purchase products
        WordCheckProducts.store.requestProducts{success, products in
            if success {
                self.products = products!
            }
        }
        
        // Add a notification listener so that view can update when in-app purchase is complete
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ViewController.handlePurchaseNotification(_:)),
            name: NSNotification.Name(rawValue: IAPHelper.IAPHelperPurchaseNotification),
            object: nil
        )
        
        purchaseDefinitionsButton.layer.borderWidth = 1
        purchaseDefinitionsButton.layer.borderColor = flatGreen.cgColor
        purchaseDefinitionsButton.layer.cornerRadius = 5
    }
    
    @objc func handlePurchaseNotification(_ notification: Notification) {
        print("Purchase succeeded!")
        showDefinition(word: self.currentWord)
        
        // TODO: Handle failure cases, like unable to connect to iTunes
    }
    
    @IBAction func purchaseDefinitionsButton(_ sender: UIButton) {
        WordCheckProducts.store.buyProduct(self.products[0])
        
        purchaseDefinitionsButton.isHidden = true
        showDefinitionLabel()
        definitionText.text = "Purchasing definitions..."
    }
    
    /// Handle tap on dumb bird image to launch "About" dialog
    @objc func birdImageTapped()
    {
        let aboutMessage = UIAlertController(title: "About", message: "This app is dedicated to my grandmother, M. Robbins, who immigrated to the United States from Holland as a teenager. She learned to play Scrabble to help improve her English vocabulary, and playing the game became a favorite pastime of our whole family. True to her original goal of growing vocabulary, our house rules specify that we are allowed to look up words in the dictionary so long as we can provide the definition on command. \n\n This app uses the \(WORD_LIST_NAME.uppercased()) word list.", preferredStyle: .alert)
        aboutMessage.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(aboutMessage, animated: true, completion: nil)
    }

    /// Handle tap on "Powered by WordNik" logo to open word definition in Safari
    @objc func wordNikImageTapped()
    {
        openUrlInSafari(urlString: "http://www.wordnik.com/words/\(currentWord)")
    }
    
    func openUrlInSafari(urlString: String) {
        let svc = SFSafariViewController(url: URL(string: urlString)!)
        present(svc, animated: true, completion: nil)
    }
    
    // Hide keyboard if user taps anywhere
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

    // Hide keyboard
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    // Hide keyboard when "Done" is clicked
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    // Perform search on every charater typed
    func searchBar(_: UISearchBar, textDidChange searchText: String) {
        currentWord = searchText.lowercased()
        checkWordAndUpdateDisplay(word: currentWord)
    }
    
    //MARK: Helper functions

    private func checkWordAndUpdateDisplay(word: String) {
        resetResultDisplay()
        searchDisplayText.text = word.uppercased()
        
        if word == "" {
            return
        }

        else if (allowedWords.contains(word.lowercased())) {
            markGood()

            if WordCheckProducts.store.isProductPurchased(WordCheckProducts.Definitions){
                print("User has purchased definitions")
                showDefinition(word: word)
            } else if (self.products.count > 0) {
                print("User has not purchased definitions, show purchase button")
                purchaseDefinitionsButton.isHidden = false
            } else {
                print("User has not purchased definitions, and can't connect to iTunes store or something else has gone wrong :(")
            }
        }

        else {
            markBad()
        }
    }
    
    /// Resets all display text to blank
    private func resetResultDisplay() {
        isText.text = ""
        decisionText.text = ""

        definitionLabel.text = ""
        poweredBy.isHidden = true
        definitionText.text = ""
        purchaseDefinitionsButton.isHidden = true
    }
    
    
    /// Indicate a given word is "GOOD"
    private func markGood() {
        isText.text = "is"
        decisionText.text = "GOOD!"
        decisionText.textColor = flatGreen
    }
    
    /// Indicate a given word is "BAD"
    private func markBad() {
        isText.text = "is"
        decisionText.text = "BAD :("
        decisionText.textColor = flatRed
    }
    
    /// Show the "Definition" and "Oxford Dictionaries" labels
    private func showDefinitionLabel() {
        definitionLabel.text = "Definitions"
        poweredBy.isHidden = false
    }
    
    /// Look up and display word definition
    private func showDefinition(word: String) {
        // Only perform search if there's an internet connection
        if NetworkReachabilityManager()!.isReachable == true {
            self.showDefinitionLabel()
            definitionText.text = "Searching for definition..."

            lookupDefinition(word: word, api: "wordnik", completion: { definitionEntries in
                // Don't show definition if API response returns after the word has already changed
                if word == self.currentWord {
                    self.definitionText.text = formatDefinitions(definitionEntries: definitionEntries)
                }
            })
        }
        
        else {
            self.showDefinitionLabel()
            self.definitionText.text = NO_NETWORK_ERROR_MESSAGE
        }
    }
}

