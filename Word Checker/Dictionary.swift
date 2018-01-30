//
//  Dictionary.swift
//  Word Checker
//
//  Created by Jaime McCandless on 1/30/18.
//  Copyright © 2018 Jaime. All rights reserved.
//

import Foundation

/**
 Loads a word list to use to determine if a word is GOOD or BAD.
 
 - Parameters:
 - fileName: The filename of the word list. Options: ["sowpods", "twl2014", "enable"]
 */
func loadWordList(fileName: String) -> Set<String> {
    var contents: String
    var wordList: Set<String> = []
    
    if let filepath = Bundle.main.path(forResource: fileName, ofType: "txt") {
        do {
            contents = try String(contentsOfFile: filepath, encoding: String.Encoding.utf8)
        } catch {
            print("Error loading '\(fileName).txt'")
            contents = ""
        }
    }
    else {
        print("'\(fileName).txt' file not found!")
        contents = ""
    }
    
    wordList = Set(contents.components(separatedBy: "\n"))
    wordList.remove("")
    print("Using \(fileName.uppercased()) dictionary: \(wordList.count) allowed words")
    
    return wordList
}
