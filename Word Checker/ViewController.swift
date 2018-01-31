//
//  ViewController.swift
//  Word Checker
//
//  Created by Jaime McCandless on 1/20/18.
//  Copyright © 2018 Jaime. All rights reserved.
//

import UIKit
import Alamofire

let NO_NETWORK_ERROR_MESSAGE = "Definition requires internet connection"
let NO_DEFINITION_ERROR_MESSAGE = "No definition found"
let OXFORD_DICTIONARIES_TAGLINE = "Powered by Oxford Dictionaries"

class ViewController: UIViewController, UISearchBarDelegate {
    //MARK: Properties

    @IBOutlet weak var searchText: UISearchBar!
    @IBOutlet weak var searchDisplayText: UILabel!
    @IBOutlet weak var decisionText: UILabel!
    @IBOutlet weak var isText: UILabel!
    @IBOutlet weak var definitionText: UITextView!
    @IBOutlet weak var definitionLabel: UITextView!
    @IBOutlet weak var definitionPoweredBy: UITextView!    
    @IBOutlet weak var dumbBirdImage: UIImageView!
    
    var allowedWords: Set<String> = []
    var currentWord: String = ""
    
    let wordListName = "enable"

    //MARK: Colors

    let flatRed = UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: 1)
    let flatGreen = UIColor(red: 39/255, green: 174/255, blue: 96/255, alpha: 1)
    
    //MARK: Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchText.delegate = self

        allowedWords = loadWordList(fileName: wordListName)
    
        // Let bird image be tappable to open "About" dialog
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        dumbBirdImage.isUserInteractionEnabled = true
        dumbBirdImage.addGestureRecognizer(tapGestureRecognizer)
    }
    
    /// Handle tap on dumb bird image to launch "About" dialog
    @objc func imageTapped()
    {
        let aboutMessage = UIAlertController(title: "About", message: "This app is dedicated to my grandmother, Marijke Robbins, who immigrated to the United States from Holland as a teenager. She learned to play Scrabble to help improve her English vocabulary, and playing the game became a favorite pasttime of our whole family. True to her original goal of growing vocabulary, our house rules specify that we are allowed to look up words in the dictionary so long as we can provide the definition on command. \n\n This app uses the \(wordListName.uppercased()) word list.", preferredStyle: .alert)
        aboutMessage.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(aboutMessage, animated: true, completion: nil)
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
        currentWord = searchText
        checkWordAndUpdateDisplay(word: searchText)
    }
    
    //MARK: Helper functions

    private func checkWordAndUpdateDisplay(word: String) {
        resetResultDisplay()
        searchDisplayText.text = word
        
        if word == "" {
            return
        }

        else if (allowedWords.contains(word.lowercased())) {
            markGood()
            showDefinition(word: word)
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
        definitionPoweredBy.text = ""
        definitionText.text = ""
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
        definitionPoweredBy.text = "Powered by WordNik"
    }
    
    /// Look up and display word definition
    private func showDefinition(word: String) {
        // Only perform search if there's an internet connection
        if NetworkReachabilityManager()!.isReachable == true {
            definitionText.text = "Searching for definition..."

            lookupDefinition(word: word, api: "wordnik", completion: { definitionEntries in
                // Don't show definition if API response returns after the word has already changed
                if word == self.currentWord {
                    self.showDefinitionLabel()
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

