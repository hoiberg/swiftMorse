//
//  MorseToneGenerator.swift
//  Morseboard
//
//  Created by Alex on 25-10-14.
//  Copyright (c) 2014 Balancing Rock. All rights reserved.
//
//  The AVAudioPlayer starts playing at the begin, and stops on deinit.
//  Starting and stopping is done by setting the volume to 1 or 0.
//  This way, the tonegenerator is more responsive and it prevents scratching sounds when it
//  starts too quickly again after stopping.
//
//  Go to http://onlinetonegenerator.com to generate a sound file you can use with this tone gererator.
//  By using a sound file, you skip all the low level audio stuff I don't really understand.


import UIKit
import AVFoundation


enum ToneFrequency: Int, Printable {
    case Low = 0
    case Middle = 1
    case High = 2
    case ExtraHigh = 3
    
    var description: String {
        get {
            switch self {
            case Low: return "Low"
            case Middle: return "Middle"
            case High: return "High"
            case ExtraHigh: return "Extra High"
            }
        }
    }
    
    var file: (name: String, type: String) {
        get {
            switch self {
            case Low: return ("600", "wav")
            case Middle: return ("720", "wav")
            case High: return ("900", "wav")
            case ExtraHigh: return ("1100", "wav")
            }
        }
    }
}

class ToneGenerator: NSObject, AVAudioPlayerDelegate {
    
    private var player: AVAudioPlayer
    private var isPlaying = false
    
    init(freq: ToneFrequency) {

        var error: NSError?
        var resourcePath: NSString? = NSBundle.mainBundle().pathForResource(freq.file.name, ofType: freq.file.type)
        println(resourcePath)
        var data: NSData? = NSData(contentsOfFile: resourcePath!)
        player = AVAudioPlayer(data: data, fileTypeHint: AVFileTypeWAVE, error: &error)
        
        super.init()

        if error != nil {
            println("Initiating AVAudioPlayer failed: \(error)")
            return
        }
        
        player.delegate = self
        player.volume = 0
        player.numberOfLoops = -1
        player.prepareToPlay()
        
        player.play()

    }
    
    deinit {
        
        player.stop()
        
    }
    
    /// Start playing tone
    func start() {
        
        if isPlaying == true { return }

        player.volume = 1.0
        isPlaying = true
        
    }
    
    /// Stop playing tone
    func stop() {
        
        if isPlaying == false { return }
        
        player.volume = 0
        isPlaying = false
        
    }

}
