//
//  ViewController.swift
//  Word Checker
//
//  Created by Jaime McCandless on 1/20/18.
//  Copyright © 2018 Jaime. All rights reserved.
//

import UIKit
import Alamofire

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
    
    let NO_NETWORK_ERROR_MESSAGE = "Definition requires internet connection"
    let NO_DEFINITION_ERROR_MESSAGE = "No definition found"
    let OXFORD_DICTIONARIES_TAGLINE = "Powered by Oxford Dictionaries"

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
        definitionLabel.text = "Definition"
        definitionPoweredBy.text = OXFORD_DICTIONARIES_TAGLINE
    }
    
    /// Look up and display word definition
    private func showDefinition(word: String) {
        // Only perform search if there's an internet connection
        if NetworkReachabilityManager()!.isReachable == true {
            definitionText.text = "Searching for definition..."

            lookupDefinitionWordsAPI(word: word, definitionFound: { wordDefinitionResult in
                
                // Handles case where API response returns after the word has already changed
                if word == self.currentWord {
                    self.showDefinitionLabel()
                    self.definitionText.text = self.formatDefinitionEntries(wordDefinitionEntries: wordDefinitionResult)
                }
            })
        }
        
        else {
            self.showDefinitionLabel()
            self.definitionText.text = NO_NETWORK_ERROR_MESSAGE
        }
    }
    
    /**
     Parses the word definition result from the Oxford Dictionaries into a formatted string, grouped by lexical entries, in the form:
     ```
     (<Part of speech>)
     1. <Definition>
     2. <Definition>
     
     (<Part of speech>)
     1. <Definition>
     ```
     
     - Parameters:
        - wordDefinitionResult: The first "result" entry for the word definition response
     
     - Returns: Formatted string definition
     */
    private func formatWordDefinition(wordDefinitionResult: [String: Any]) -> String {
        // TODO: Find a better way to parse JSON? There's gotta be a better way..
        if let lexicalEntries = wordDefinitionResult["lexicalEntries"] as? [[String: Any]] {
            var formattedLexicalEntries: [String] = []

            for lexicalEntry in lexicalEntries {
                let formattedLexicalEntry = formatLexicalEntry(lexicalEntry: lexicalEntry)
                
                if formattedLexicalEntry != nil {
                    formattedLexicalEntries.append(formattedLexicalEntry!)
                }
            }
            
            return formattedLexicalEntries.joined(separator: "\n\n")
        }
        
        return NO_DEFINITION_ERROR_MESSAGE
    }

    /**
     Parses a single lexical entry for a word into a formatted string including part of speech and list of definitions
     
     - Parameters:
        - lexicalEntry: A single lexical entry for a word
     
     - Returns: Formatted string definition
     */
    private func formatLexicalEntry(lexicalEntry: [String:Any]) -> String? {
        var formattedDefinition = ""
        
        let category = lexicalEntry["lexicalCategory"] as? String
        
        var lexicalEntryDefinitions: [String] = []
        
        if let entries = lexicalEntry["entries"] as? [[String: Any]] {
            for entry in entries {
                if let senses = entry["senses"] as? [[String: Any]] {
                    for sense in senses {
                        if let definitions = sense["definitions"] as? [String] {
                            for definition in definitions {
                                lexicalEntryDefinitions.append(definition)
                            }
                        }
                    }
                }
            }
        }
        
        // Only format an entry if there are actually definitions
        if lexicalEntryDefinitions.count > 0 {
            formattedDefinition += "(\(category!))"
            
            for (index, definition) in lexicalEntryDefinitions.enumerated() {
                formattedDefinition += "\n\(index + 1).  \(definition)"
            }
            
            return formattedDefinition
        }
        
        return nil
    }
    
    /**
     Looks up definition for a word in the Oxford Dictionaries
     
     - Parameters:
        - word: The word to look up
        - definitionFound: a callback which passes through the word definition found
     */
    private func lookupDefinition(word: String, definitionFound: @escaping ((_ wordDefinitionResult: [String: Any]) -> Void)) {
        let url = URL(string: "https://od-api.oxforddictionaries.com/api/v1/entries/en/\(word.lowercased())")!

        var request = URLRequest(url: url)
        request.setValue("d4a39582", forHTTPHeaderField: "app_id")
        request.setValue("bc30dd5e7a03fbe42093d7c7857c47bc", forHTTPHeaderField: "app_key")
        
        let configuration = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: configuration, delegate: nil, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            do {
                if let data = data,
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let results = json["results"] as? [[String: Any]] {
                    
                    let result = results[0] // I'm not sure what more than one results entry would mean anyway
                    definitionFound(result)
                }
            } catch {
                print("Error deserializing JSON: \(error)")
            }
        })
        
        task.resume()
    }
    
    //MARK: Words API
    
    /**
     For Words API
     Parses the word definition result from the Oxford Dictionaries into a formatted string, grouped by lexical entries, in the form:
     ```
     (<Part of speech>)
     1. <Definition>
     2. <Definition>
     
     (<Part of speech>)
     1. <Definition>
     ```
     
     - Parameters:
     - wordDefinitionResult: The first "result" entry for the word definition response
     
     - Returns: Formatted string definition
     */
    private func formatDefinitionEntries(wordDefinitionEntries: [[String: Any]]) -> String {
        var formattedDefinitions: [String] = []
        
        print("word definition entries: \(wordDefinitionEntries)")
        
        if wordDefinitionEntries.count == 0 {
            return NO_DEFINITION_ERROR_MESSAGE
        }

        for (index, entry) in wordDefinitionEntries.enumerated() {
            let formattedDefinition = formatDefinitionEntry(entry: entry)
            
            if formattedDefinition != nil {
                formattedDefinitions.append("\(index + 1). \(formattedDefinition!)")
            }
        }
            
        return formattedDefinitions.joined(separator: "\n")
    }

    /**
     For Words API

     Parses a single definition result for a word into a formatted string including part of speech and list of definitions
     
     - Parameters:
     - entry: A single definition entry for a word
     
     - Returns: Formatted string definition
     */
    private func formatDefinitionEntry(entry: [String: Any]) -> String? {
        let partOfSpeech = entry["partOfSpeech"] as? String
        let definition = entry["definition"] as? String
        
        // Only format an entry if there are actually definitions
        if definition != nil {
            return "(\(partOfSpeech!)). \(definition!)"
        }
        
        return nil
    }
    
    /**
     Looks up definition for a word in the Words API
     
     - Parameters:
     - word: The word to look up
     - definitionFound: a callback which passes through the word definition found
     */
    private func lookupDefinitionWordsAPI(word: String, definitionFound: @escaping ((_ wordDefinitionResult: [[String: Any]]) -> Void)) {
        let url = URL(string: "https://wordsapiv1.p.mashape.com/words/\(word.lowercased())")!
        
        var request = URLRequest(url: url)
        request.setValue("CNobznHBT4mshurXH1ATPdbNpmxAp1mFZ38jsnFy5Fmz7NssgR", forHTTPHeaderField: "X-Mashape-Key")
        request.setValue("wordsapiv1.p.mashape.com", forHTTPHeaderField: "X-Mashape-Host")
        
        let configuration = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: configuration, delegate: nil, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            do {
                if let data = data,
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let results = json["results"] as? [[String: Any]] {
                    
                    definitionFound(results)
                }
                else {
                    print("No result found")
                    definitionFound([])
                }
            } catch {
                print("Error deserializing JSON: \(error)")
                definitionFound([])
            }
        })
        
        task.resume()
    }
}

