//
//  MorseController.swift
//  Morseboard
//
//  Created by Alex on 03-02-15.
//  Copyright (c) 2015 Balancing Rock. All rights reserved.
//  MIT License applies
//
//
//  Features: 
//  - Supports single button as well as dual button (one for . and one for -) applications
//  - Morse beep sounds with adjustable frequency (Low, Middle, High, Extra High, and you can supply your own if you want)
//  - Configurable WPM, Sound enable, Sound frequency, Auto space enable, error symbol
//
//  Ideas for future updates:
//  - Iambic paddle support
//  - Option to use the ticking sound of a morse key instead of beeps
//
//  Hope this saves someone time :)
//

import UIKit

enum MorseSignal: String, Printable {
    case Short = "."
    case Long = "-"
    
    var description: String {
        get { return self.rawValue }
    }
}

protocol MorseControllerDelegate {
    func insertCharacter(var charToInsert: String)
}

private let _morseDictionary = [".-": "a",
                                "-...": "b",
                                "-.-.": "c",
                                "-..": "d",
                                ".": "e",
                                "..-.": "f",
                                "--.": "g",
                                "....": "h",
                                "..": "i",
                                ".---": "j",
                                "-.-": "k",
                                ".-..": "l",
                                "--": "m",
                                "-.": "n",
                                "---": "o",
                                ".--.": "p",
                                "--.-": "q",
                                ".-.": "r",
                                "...": "s",
                                "-": "t",
                                "..-": "u",
                                "...-": "v",
                                ".--": "w",
                                "-..-": "x",
                                "-.--": "y",
                                "--..": "z",
                                ".-.-": "ä",
                                "---.": "ö",
                                "..--": "ü",
                                "...--..": "ß",
                                "----": "CH",
                                ".----": "1",
                                "..---": "2",
                                "...--": "3",
                                "....-": "4",
                                ".....": "5",
                                "-....": "6",
                                "--...": "7",
                                "---..": "8",
                                "----.": "9",
                                "-----": "0",
                                "..--..": "?",
                                "..--.": "!",
                                ".--.-.": "@",
                                ".-.-.-": ".",
                                "--..--": ",",
                                "-...-": "=",
                                ".-.-.": "+"]

class MorseController: NSObject {

//MARK: - Class vars
    
    /// morse dictionary with dots and dashes being the keys and characters the values (singleton)
    class var morseDictionary: [String: String] {
        get { return _morseDictionary }
    }
    

//MARK: - Instance vars
    
    /// Delegate the insertCharacter function will be called upon
    var delegate: MorseControllerDelegate?
    
    /// Speed (words per minute)
    var wpm: Int = 10
    
    /// Whether a beep sound should be played
    var sounds: Bool = true
    
    /// Frequency of the beep sounds. Note: cannot be changed after initialization
    let soundFreq: ToneFrequency = .Middle
    
    /// Whether automaticly a space should be inserted after 7 time units
    var autoSpace: Bool = false
    
    /// The symbol that will be given if a nonextistend morse character has been generated
    var errorSymbol: String = "😕"
    
    /// Minimum duration of a morse sound, to prevent short dots to be unplayed/unheard
    private let minSoundDuration = 0.5
    
    /// One time unit
    private var timeUnit: Double {
        get { return Double(1.2) / Double(self.wpm) }
    }
    
    /// Whether a space may be inserted
    /// not if A) there hasn't a character been inserted yet or B) if a space has been inserted
    private var mayInsertSpace = false
    

    // rest is self-explainatory
    private lazy var toneGen: ToneGenerator = ToneGenerator(freq: self.soundFreq)
    private var isBeingPressed: Bool = false
    private var lastBeginTime: NSDate?
    private var lastEndTime: NSDate?
    var morseToPresent: [String] = []

    
//MARK: - Functions
    
    override init() {
        
        super.init()
        
        // start update loop
        NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: "updateMorse", userInfo: nil, repeats: true)

    }
    
    init(delegate: MorseControllerDelegate, wpm: Int, sounds: Bool, soundFreq: ToneFrequency, autoSpace: Bool, errorSymbol: String) {
        
        self.delegate = delegate
        self.wpm = wpm
        self.sounds = sounds
        self.soundFreq = soundFreq
        self.autoSpace = autoSpace
        self.errorSymbol = errorSymbol

        super.init()
        
        // start update loop
        NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: "updateMorse", userInfo: nil, repeats: true)

    }
    
    /// Updates every 0.01 seconds to check whether
    /// a) A character should be inserted
    /// b) A space should be inserted (only if autoSpace is true)
    func updateMorse() {
        
        // check if it is needed to update
        if isBeingPressed == true || lastEndTime == nil { return }
        
        // is the time since previous tap long enough
        let timeSinceTap = NSDate().timeIntervalSinceDate(lastEndTime!)
        if timeSinceTap < timeUnit * 3 { return }
        
        // if there is some morse to insert
        if morseToPresent.count != 0 {
        
            // get the character to insert
            let charToInsert = characterForMorse(morseToPresent)
            morseToPresent = []
        
            // call the delegate method
            delegate?.insertCharacter(charToInsert)
            
            // a space may be inserted from now on
            mayInsertSpace = true
            
            return
        
        }
            
        // maybe we have to insert a space
        if autoSpace && mayInsertSpace && timeSinceTap > timeUnit * 7 {
            
            // call the delegate method to insert a space
            delegate?.insertCharacter(" ")
            
            // no second spaces
            mayInsertSpace = false
            
        }
        
    }
    
    /// To be used by the delegate to notify that a tap as begun
    func beginMorse() {
        
        isBeingPressed = true
        lastBeginTime = NSDate()
        
        if sounds {
            
            toneGen.start()

        }
        
    }
    
    /// To be used by the delegate to notify that the tap has ended
    func endMorse() {
        
        isBeingPressed = false
        lastEndTime = NSDate()
        
        if sounds {
            
            // stop sounds, only if the minimum sound duration
            // has been exceeded to prevent too short blip's
            
            if lastEndTime!.timeIntervalSinceDate(lastBeginTime!) >= minSoundDuration {
                
                // alright, stop the sound gen
                toneGen.stop()
                
            } else {
                
                // shedule timer to stop the sound gen at the lastBeginTime + minSoundDuration
                let targetTime = lastBeginTime!.dateByAddingTimeInterval(minSoundDuration)
                NSTimer.scheduledTimerWithTimeInterval(lastEndTime!.timeIntervalSinceDate(targetTime), target: toneGen, selector: Selector("stop"), userInfo: nil, repeats: false)
                
            }
            
        }
        
        // add . or -
        let timePressed = lastEndTime!.timeIntervalSinceDate(lastBeginTime!)
        if timePressed >= timeUnit * Double(3) {
            morseToPresent += ["-"]
        } else {
            morseToPresent += ["."]
        }
        
    }
    
    /// To be used by the delegate to manually insert a . or -
    func manuallyInsertMorse(morse: MorseSignal) {
        
        if isBeingPressed { return }
        
        lastBeginTime = NSDate()
        lastEndTime = NSDate()
        
        morseToPresent.append(morse.description)
        
    }
    
    /// Returns the human readable character for the given morse sequence (or the error symbol if it is not valid morse)
    func characterForMorse(theArray:[String]) -> String {
        
        // join the objects
        let theString = "".join(theArray)
        
        // get the character
        let returnString = MorseController.morseDictionary[theString]
        
        // return errorsymbol if neccesary
        if returnString == nil || returnString?.isEmpty == true { return errorSymbol }
        
        return returnString!
        
    }

}
