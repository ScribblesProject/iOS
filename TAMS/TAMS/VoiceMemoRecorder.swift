//
//  VoiceMemoRecorder.swift
//  TAMS
//
//  Created by Daniel Jackson on 3/18/16.
//  Copyright © 2016 Daniel Jackson. All rights reserved.
//

import UIKit
import AVFoundation

private let _sharedInstance = VoiceMemoRecorder()

public typealias RecorderStartHandler = ((success:Bool)->Void)
public typealias PlayerProgressHandler = ((progress:Double, playing:Bool, finished:Bool)->Void)

public class VoiceMemoRecorder: NSObject, AVAudioPlayerDelegate {
    
    let fileURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("voiceRecording.aac")
    var audioRecorder:AVAudioRecorder?
    var recording:Bool = false
    var audioPlayer:AVPlayer?
    var audioPlayerProgressTimer:NSTimer?
    var audioPlayerProgressHandler:PlayerProgressHandler?

    public class func sharedInstance()->VoiceMemoRecorder
    {
        return _sharedInstance
    }
    
    public func recordingExists()->Bool {
        return self.fileURL.checkResourceIsReachableAndReturnError(nil)
    }
    
    private func reset()
    {
        audioRecorder?.stop()
        audioRecorder = nil
        audioPlayer?.pause()
        audioPlayer = nil
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.audioPlayerProgressTimer?.invalidate()
            self.audioPlayerProgressTimer = nil
        }
    }
    
    public func deleteRecording()
    {
        reset()
        
        if self.fileURL.checkResourceIsReachableAndReturnError(nil) {
            try! NSFileManager.defaultManager().removeItemAtURL(fileURL)
            print("Deleting Recording...")
        }
    }
    
    public func isRecording()->Bool
    {
        return recording
    }
    
    public func recordAudio(startHandler:RecorderStartHandler)
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            //init
            let audioSession:AVAudioSession = AVAudioSession.sharedInstance()
            
            self.deleteRecording()
            
            //ask for permission
            if (audioSession.respondsToSelector("requestRecordPermission:")) {
                AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool)-> Void in
                    if granted {
                        print("granted")
                        
                        //set category and activate recorder session
                        try! audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
                        try! audioSession.setActive(true)
                        
                        //create AnyObject of settings
                        let settings: [String : AnyObject] = [
                            AVFormatIDKey:Int(kAudioFormatMPEG4AAC), //Int required in Swift2
                            AVSampleRateKey:11025.0,
                            AVNumberOfChannelsKey:2,
                            AVEncoderAudioQualityKey:AVAudioQuality.Low.rawValue
                        ]
                        
                        //record
                        try! self.audioRecorder = AVAudioRecorder(URL: self.fileURL, settings: settings)
                        self.audioRecorder?.record()
                        self.recording = true
                        startHandler(success: true)
                        
                    } else{
                        print("not granted")
                        startHandler(success: false)
                    }
                })
            }
        }
    }
    
    //Returns the audio file url
    public func stopRecorder()->NSURL
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.audioRecorder?.stop()
            self.recording = false
        }
        
        return fileURL
    }
    
    //Returns false if error
    private func initPlayer() {
        let audioSession:AVAudioSession = AVAudioSession.sharedInstance()
        try! audioSession.setCategory(AVAudioSessionCategoryPlayback)
        try! audioSession.setActive(true)
        self.audioPlayer = AVPlayer(playerItem: AVPlayerItem(asset: AVAsset(URL: self.fileURL)))
        NSNotificationCenter.defaultCenter().removeObserver(self)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "itemDidFinishPlaying:", name: AVPlayerItemDidPlayToEndTimeNotification, object: self.audioPlayer!.currentItem)
    }
    
    public func playing()->Bool
    {
        return (self.audioPlayer?.rate > 0) ?? false
    }
    
    public func play(progressHandler:PlayerProgressHandler) {
        audioPlayerProgressHandler = progressHandler
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.audioPlayerProgressTimer?.invalidate()
            self.audioPlayerProgressTimer = nil
            
            if self.audioPlayer == nil {
                //Player is reset when the recording has been deleted (new recording)
                self.initPlayer()
            }
            
            self.audioPlayer?.play()
            self.reportProgress(false)
            self.audioPlayerProgressTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "updatePlayerProgress", userInfo: nil, repeats: true)
        }
    }
    
    public func pause() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.audioPlayer?.pause()
            self.audioPlayerProgressTimer?.invalidate()
            self.audioPlayerProgressTimer = nil
            self.reportProgress(false)
        }
    }
    
    public func updatePlayerProgress()
    {
        reportProgress(false)
    }
    
    private func reportProgress(finished:Bool)
    {
        var progress = 0.0
        if finished {
            progress = 1.0
        }
        else {
            let currentTime = Double(self.audioPlayer?.currentTime().seconds ?? 0.0)
            let totalTime = Double(self.audioPlayer?.currentItem?.duration.seconds ?? 0.0)
            if totalTime != 0 {
                progress = currentTime / totalTime
            }
            print("CurrentTime: \(currentTime) Total:\(totalTime) progress:\(progress) finished:\(finished)")
        }
        let playing = self.playing()
        audioPlayerProgressHandler?(progress: progress, playing: playing, finished: finished)
    }
    
    //MARK: Audio Player Delegate
    
    public func itemDidFinishPlaying(notification:NSNotification) {
        
        reportProgress(true)
        
        self.reset()
    }
}
