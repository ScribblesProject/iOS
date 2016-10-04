//
//  RemoteMemoPlayer.swift
//  TAMS
//
//  Created by Daniel Jackson on 10/3/16.
//  Copyright © 2016 Daniel Jackson. All rights reserved.
//

import UIKit
import AVFoundation

class MemoPlayer: NSObject {

    //Singleton
    static let shared = MemoPlayer()
    
    public enum MemoPlayerState : Int {
        case Unknown
        case Loading
        case Playing
        case Paused
        case Finished
        case Error
        
        func description()->String
        {
            switch self {
            case .Unknown:  return "Unknown"
            case .Loading:  return "Loading"
            case .Playing:  return "Playing"
            case .Paused:   return "Paused"
            case .Finished: return "Finished"
            case .Error:    return "Error"
            }
        }
    }
    public typealias PlayerProgressHandler = ((_ progress:Double, _ state:MemoPlayerState, _ error:Error?)->Void)
    
    let player = AVPlayer()
    var progressHandler:PlayerProgressHandler?
    var timeObserver:Any?
    var loading:Bool = false
    var playing:Bool {
        get { return (self.player.rate != 0.0 && self.player.error == nil)  }
    }
    
    var currentTime:Double {
        get {
            if self.player.currentItem?.status ?? .unknown == .readyToPlay {
                return CMTimeGetSeconds( self.player.currentTime() )
            }
            return Double.nan
        }
    }
    
    var duration:Double {
        get {
            if self.player.currentItem?.status ?? .unknown == .readyToPlay {
                return CMTimeGetSeconds( self.player.currentItem!.duration )
            }
            return Double.nan
        }
    }
    
    var progress:Double {
        get {
            let dur = self.duration
            let current = self.currentTime
            if current != Double.nan && dur != Double.nan && dur != 0.0 {
                return current / dur
            }
            return 0.0
        }
    }
    
    override init() {
        super.init()
        
    }

    func play(localUrl:URL, _ progressHandler:@escaping PlayerProgressHandler) {
        DispatchQueue.main.async { () -> Void in
            self.progressHandler = progressHandler
            self.setupPlayer(url: localUrl)
            self.resume()
            
        }
    }
    
    func play(remoteUrl:String, _ progressHandler:@escaping PlayerProgressHandler) {
        DispatchQueue.main.async { () -> Void in
            self.progressHandler = progressHandler
            let url = URL(string: remoteUrl)
            self.setupPlayer(url: url!)
            self.resume()
        }
    }
    
    func resume()
    {
        self.player.rate = 1.0;
        self.player.play()
    }
    
    func pause()
    {
        self.player.pause()
    }
    
    func stop()
    {
        self.player.pause()
        resetPlayer()
    }
    
    private func resetPlayer()
    {
        if let item = self.player.currentItem {
            self.loading = false
            self.player.pause()
            
            //Remove Time Observer
            if let observer = self.timeObserver {
                self.player.removeTimeObserver(observer)
                self.timeObserver = nil
            }
            
            //Remove Rate Observer
            self.player.removeObserver(self, forKeyPath: "rate")
            
            //Remove Finish Observer
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item)
            
            //Replace Current Item
            self.player.replaceCurrentItem(with: nil)
        }
    }
    
    private func setupPlayer(url:URL)
    {
        resetPlayer()

        let playerItem = AVPlayerItem( url: url )
        self.player.replaceCurrentItem(with: playerItem)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(finishedPlaying(notification:)),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: playerItem)
        self.player.addObserver(self, forKeyPath: "rate", options: NSKeyValueObservingOptions.new, context: nil)
        
        let time = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        self.timeObserver = self.player.addPeriodicTimeObserver(forInterval: time, queue: nil) { (_) in
            self.reportProgress(finished: false)
        }
        
        loading = true
        reportProgress(finished: false)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "rate"
        {
            if self.player.rate != 0.0 {
                self.loading = false
            }
            
            reportProgress(finished: false)
        }
    }
    
    func finishedPlaying(notification:NSNotification?)
    {
        resetPlayer()
        reportProgress(finished: true)
    }
    
    func progressChanged()
    {
        reportProgress(finished: false)
    }
    
    func state(isFinished:Bool)->MemoPlayerState
    {
        var state:MemoPlayerState = .Unknown
        if isFinished
        {
            state = .Finished
        }
        else if self.player.currentItem != nil
        {
            if self.playing {
                state = .Playing
            }
            else if self.player.error != nil {
                state = .Error
            }
            else if self.loading {
                state = .Loading
            }
            else {
                state = .Paused
            }
        }
        
        return state
    }
    
    func reportProgress(finished:Bool)
    {
        let state = self.state(isFinished: finished)
        var error:Error?
        if state == .Error {
            error = self.player.error
        }
        self.progressHandler?(self.progress, state, error)
    }
}
