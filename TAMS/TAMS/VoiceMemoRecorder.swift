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
    
    let fileURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("voiceRecording.caf")
    var audioRecorder:AVAudioRecorder?
    var recording:Bool = false
    var audioPlayer:AVAudioPlayer?
    var audioPlayerProgressTimer:NSTimer?
    var audioPlayerProgressHandler:PlayerProgressHandler?

    public class func sharedInstance()->VoiceMemoRecorder
    {
        return _sharedInstance
    }
    
    public func recordingExists()->Bool {
        return self.fileURL.checkResourceIsReachableAndReturnError(nil)
    }
    
    public func deleteRecording()
    {
        audioRecorder?.stop()
        audioRecorder = nil
        audioPlayer?.stop()
        audioPlayer = nil
        
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
                            AVFormatIDKey:Int(kAudioFormatAppleIMA4), //Int required in Swift2
                            AVSampleRateKey:44100.0,
                            AVNumberOfChannelsKey:2,
                            AVEncoderBitRateKey:12800,
                            AVLinearPCMBitDepthKey:16,
                            AVEncoderAudioQualityKey:AVAudioQuality.Max.rawValue
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
        self.audioPlayer = try! AVAudioPlayer(contentsOfURL: fileURL)
    }
    
    public func playing()->Bool
    {
        return self.audioPlayer?.playing ?? false
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
            
            self.audioPlayer?.prepareToPlay()
            self.audioPlayer?.play()
            self.audioPlayer?.delegate = self
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
            let currentTime = Double(self.audioPlayer?.currentTime ?? NSTimeInterval(0.0))
            let totalTime = Double(self.audioPlayer?.duration ?? NSTimeInterval(0.0))
            if totalTime != 0 {
                progress = currentTime / totalTime
            }
        }
//        print("CurrentTime: \(currentTime) Total:\(totalTime) progress:\(progress) finished:\(finished)")
        let playing = (self.audioPlayer?.playing ?? false)
        audioPlayerProgressHandler?(progress: progress, playing: playing, finished: finished)
    }
    
    //MARK: Audio Player Delegate
    
    public func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.audioPlayerProgressTimer?.invalidate()
            self.audioPlayerProgressTimer = nil
        }
        reportProgress(true)
    }
}
