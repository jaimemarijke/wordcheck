//
//  WordsAPI.swift
//  Word Checker
//
//  Created by Jaime McCandless on 1/30/18.
//  Copyright © 2018 Jaime. All rights reserved.
//

import Foundation
import Alamofire

class DefinitionEntry {
    var word, definition: String
    var partOfSpeech: String?
    
    init(word: String, definition: String, partOfSpeech: String? = nil) {
        self.word = word
        self.definition = definition
        self.partOfSpeech = partOfSpeech
    }
}

func formatDefinitions(definitionEntries: [DefinitionEntry]) -> String {
    if definitionEntries.count == 0 {
        return NO_DEFINITION_ERROR_MESSAGE
    }
    
    var formattedDefinitions: [String] = []
    
    // Enumerate a list of definitions, formatted with part of speech
    for (index, entry) in definitionEntries.enumerated() {
        formattedDefinitions.append("\(index + 1). (\(entry.partOfSpeech!)). \(entry.definition)")
    }
    
    return formattedDefinitions.joined(separator: "\n")
}

func lookupDefinition(word: String, api: String = "wordnik", completion: @escaping ((_ definitionEntries: [DefinitionEntry]) -> Void)) {
    if api == "wordsapi" {
        return lookupDefinitionWordsAPI(word: word, completion: completion)
    }
    
    else {
        return lookupDefinitionWordNik(word: word, completion: completion)
    }
}

enum APIError: Error {
    case unknown
}


func lookupDefinitionWordNik(word: String, completion: @escaping ((_ definitionEntries: [DefinitionEntry]) -> Void)) {
    print("Querying WordNik for \(word) definition")
    
    let headers: HTTPHeaders = [
        "api_key": "be130b7e0da73d978500700212f0c86fd1ebb7668b8a99a1e",
    ]
    
    Alamofire.request(
        URL(string: "http://api.wordnik.com:80/v4/word.json/\(word.lowercased())/definitions?limit=10")!,
        method: .get,
        headers: headers)
        .validate()
        .responseJSON { (response) -> Void in
            guard response.result.isSuccess else {
                print("Error while fetching definitions: \(response.result.error ?? APIError.unknown)")
                completion([])
                return
            }
            
            guard let json = response.result.value as? [[String: Any]] else {
                print("Malformed data received from WordNik service: \(response.result.error ?? APIError.unknown)")
                completion([])
                return
            }
            
            let definitionEntries = json.map({
                result in DefinitionEntry(word: word, definition: result["text"] as! String, partOfSpeech: result["partOfSpeech"] as? String)
            })
            
            completion(definitionEntries)
    }
}

func lookupDefinitionWordsAPI(word: String, completion: @escaping ((_ definitionEntries: [DefinitionEntry]) -> Void)) {
    print("Querying Words API for \(word) definition")
    
    let headers: HTTPHeaders = [
        "X-Mashape-Key": "CNobznHBT4mshurXH1ATPdbNpmxAp1mFZ38jsnFy5Fmz7NssgR",
        "X-Mashape-Host": "wordsapiv1.p.mashape.com"
    ]
    
    Alamofire.request(
        URL(string: "https://wordsapiv1.p.mashape.com/words/\(word.lowercased())")!,
        method: .get,
        headers: headers)
        .validate()
        .responseJSON { (response) -> Void in
            guard response.result.isSuccess else {
                print("Error while fetching definitions: \(response.result.error ?? APIError.unknown)")
                completion([])
                return
            }
            
            guard let json = response.result.value as? [String: Any] else {
                print("Malformed data received from Words API service: \(response.result.error ?? APIError.unknown)")
                print("Response: \(response)")
                completion([])
                return
            }
            
            guard let results = json["results"] as? [[String: Any]] else {
                print("No definitions found. Response: \(response)")
                completion([])
                return
            }
            
            let definitionEntries = results.map({
                result in DefinitionEntry(word: word, definition: result["definition"] as! String, partOfSpeech: result["partOfSpeech"] as? String)
            })
            
            completion(definitionEntries)
    }
}


//////////////////
//////////////////


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
 - completion: a callback which passes through the word definition found
 */
func lookupDefinitionOxfordDictionaries(word: String, completion: @escaping ((_ wordDefinitionResult: [String: Any]) -> Void)) {
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
                completion(result)
            }
        } catch {
            print("Error deserializing JSON: \(error)")
        }
    })
    
    task.resume()
}
