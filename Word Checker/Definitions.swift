//
//  WordsAPI.swift
//  Word Checker
//
//  Created by Jaime McCandless on 1/30/18.
//  Copyright © 2018 Jaime. All rights reserved.
//

import Foundation

/**
 For Words API
 Parses the word definition result from the Oxford Dictionaries into a formatted string, grouped by lexical entries, in the form:
 ```
 1. (<Part of speech>). <Definition>
 2. (<Part of speech>). <Definition>
 ```
 
 - Parameters:
 - wordDefinitionEntries: The first "result" entry for the word definition response
 
 - Returns: Formatted string definition
 */
func formatDefinitionEntries(wordDefinitionEntries: [[String: Any]]) -> String {
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
func formatDefinitionEntry(entry: [String: Any]) -> String? {
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
func lookupDefinitionWordsAPI(word: String, definitionFound: @escaping ((_ wordDefinitionResult: [[String: Any]]) -> Void)) {
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
func formatWordDefinition(wordDefinitionResult: [String: Any]) -> String {
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
func formatLexicalEntry(lexicalEntry: [String:Any]) -> String? {
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
func lookupDefinition(word: String, definitionFound: @escaping ((_ wordDefinitionResult: [String: Any]) -> Void)) {
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
