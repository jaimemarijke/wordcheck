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

let PREFERRED_PARTS_OF_SPEECH_ORDER = ["noun", "verb"]


/// Implement groupBy, inspired by https://stackoverflow.com/questions/41564580/group-elements-of-an-array-by-some-property
extension Sequence {
    func groupBy<GroupingType: Hashable>(by key: (Iterator.Element) -> GroupingType) -> [GroupingType: [Iterator.Element]] {
        var groups: [GroupingType: [Iterator.Element]] = [:]
        
        forEach { element in
            let key = key(element)
            if case nil = groups[key]?.append(element) {
                groups[key] = [element]
            }
        }

        return groups
    }
}


/**
 Formats a list of DefinitionEntrys into definitions grouped by part of speech
 ```
 (<Part of speech>)
 1. <Definition>
 2. <Definition>
 
 (<Part of speech>)
 1. <Definition>
 ```
 
 - Parameters:
 - definitionEntries: A list of DefinitionEntrys
 
 - Returns: A string of formatted definitions, grouped by part of speech
 */
func formatDefinitions(definitionEntries: [DefinitionEntry]) -> String {
    if definitionEntries.count == 0 {
        return NO_DEFINITION_ERROR_MESSAGE
    }
    
    var formattedDefinitions: [String] = []
    
    // Group definitions by part of speech
    let definitionsGroupedByPartOfSpeech: [String: [DefinitionEntry]] = definitionEntries.groupBy { entry in entry.partOfSpeech ?? "" }
    
    // Start with most common parts of speech, in a preferred order
    for partOfSpeech in PREFERRED_PARTS_OF_SPEECH_ORDER {
        if let definitions = definitionsGroupedByPartOfSpeech[partOfSpeech] {
            formattedDefinitions += formatPartOfSpeechGroupedDefinitions(partOfSpeech: partOfSpeech, definitions: definitions)
        }
    }
    
    // Finish with the remaining, more esoteric parts of speech
    for (partOfSpeech, definitions) in definitionsGroupedByPartOfSpeech {
        if PREFERRED_PARTS_OF_SPEECH_ORDER.contains(partOfSpeech) { continue }

        formattedDefinitions += formatPartOfSpeechGroupedDefinitions(partOfSpeech: partOfSpeech, definitions: definitions)
    }
    
    return formattedDefinitions.joined(separator: "\n")
}


/// Format a set of definitions for a particular part of speech
private func formatPartOfSpeechGroupedDefinitions(partOfSpeech: String, definitions: [DefinitionEntry]) -> [String] {
    var formattedDefinitions: [String] = []

    formattedDefinitions.append("(\(partOfSpeech.capitalized))")
    
    // Enumerate a list of definitions
    for (index, entry) in definitions.enumerated() {
        formattedDefinitions.append("\(index + 1). \(entry.definition)")
    }
    
    formattedDefinitions.append("")
    
    return formattedDefinitions
}


/// Look up word definitions using one of the word definition APIs
func lookupDefinition(word: String, api: String = "wordnik", completion: @escaping ((_ definitionEntries: [DefinitionEntry]) -> Void)) {
    if api == "wordsapi" {
        return lookupDefinitionWordsAPI(word: word, completion: completion)
    }
        
    else if api == "oxford" {
        lookupDefinitionOxfordDictionaries(word: word, completion: completion)
    }
    
    else { // api == "wordnik"
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
        URL(string: "http://api.wordnik.com:80/v4/word.json/\(word.lowercased())/definitions?limit=20")!,
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
                result in DefinitionEntry(
                    word: word,
                    definition: result["text"] as! String,
                    partOfSpeech: standardizePartsOfSpeech(partOfSpeech: result["partOfSpeech"] as? String ?? "")
                )
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
                result in DefinitionEntry(
                    word: word,
                    definition: result["definition"] as! String,
                    partOfSpeech: result["partOfSpeech"] as? String
                )
            })
            
            completion(definitionEntries)
    }
}

func lookupDefinitionOxfordDictionaries(word: String, completion: @escaping ((_ definitionEntries: [DefinitionEntry]) -> Void)) {
    print("Querying Oxford Dictionaries for \(word) definition")
    
    let headers: HTTPHeaders = [
        "app_id": "d4a39582",
        "app_key": "bc30dd5e7a03fbe42093d7c7857c47bc",
        "Accept": "application/json"
    ]
    
    Alamofire.request(
        URL(string: "https://od-api.oxforddictionaries.com/api/v1/entries/en/\(word.lowercased())")!,
        method: .get,
        headers: headers)
        .validate()
        .responseJSON { (response) -> Void in
            guard response.result.isSuccess else {
                print("Error while fetching definitions: \(response.result.error ?? APIError.unknown)")
                completion([])
                return
            }
            
            guard let json = response.result.value as? [String: Any],
                let results = json["results"] as? [[String: Any]] else {
                    
                print("Malformed data received from Oxford Dictionaries service: \(response.result.error ?? APIError.unknown)")
                print("Response: \(response)")
                completion([])
                return
            }
            
            let result = results.isEmpty ? [:] : results[0]  // I'm not sure what more than one results entry would mean
            
            var definitionEntries: [DefinitionEntry] = []
            
            // Flatten nested entries down to a list of DefinitionEntry
            if let lexicalEntries = result["lexicalEntries"] as? [[String: Any]] {
                for lexicalEntry in lexicalEntries {
                    let partOfSpeech = lexicalEntry["lexicalCategory"] as? String ?? ""

                    if let entries = lexicalEntry["entries"] as? [[String: Any]] {
                        for entry in entries {
                            if let senses = entry["senses"] as? [[String: Any]] {
                                for sense in senses {
                                    if let definitions = sense["definitions"] as? [String] {
                                        for definition in definitions {
                                            definitionEntries.append(DefinitionEntry(word: word, definition: definition, partOfSpeech: partOfSpeech))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            completion(definitionEntries)
    }
}

private func standardizePartsOfSpeech(partOfSpeech: String) -> String {
    let standardized = [
        "verb-intransitive": "verb",
        "verb-transitive": "verb"
    ]
    
    return standardized[partOfSpeech] ?? partOfSpeech
}
