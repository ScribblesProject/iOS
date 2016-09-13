//
//  VoiceMemoRecorder.swift
//  TAMS
//
//  Created by Daniel Jackson on 3/18/16.
//  Copyright © 2016 Daniel Jackson. All rights reserved.
//

import UIKit
import AVFoundation
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


private let _sharedInstance = VoiceMemoRecorder()

public typealias RecorderStartHandler = ((_ success:Bool)->Void)
public typealias PlayerProgressHandler = ((_ progress:Double, _ playing:Bool, _ finished:Bool)->Void)

open class VoiceMemoRecorder: NSObject, AVAudioPlayerDelegate {
    
    let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("voiceRecording.aac")
    var audioRecorder:AVAudioRecorder?
    var recording:Bool = false
    var audioPlayer:AVPlayer?
    var audioPlayerProgressTimer:Timer?
    var audioPlayerProgressHandler:PlayerProgressHandler?

    open class func sharedInstance()->VoiceMemoRecorder
    {
        return _sharedInstance
    }
    
    open func recordingExists()->Bool {
        return (self.fileURL as NSURL).checkResourceIsReachableAndReturnError(nil)
    }
    
    fileprivate func reset()
    {
        audioRecorder?.stop()
        audioRecorder = nil
        audioPlayer?.pause()
        audioPlayer = nil
        NotificationCenter.default.removeObserver(self)
        
        DispatchQueue.main.async { () -> Void in
            self.audioPlayerProgressTimer?.invalidate()
            self.audioPlayerProgressTimer = nil
        }
    }
    
    open func deleteRecording()
    {
        reset()
        
        if (self.fileURL as NSURL).checkResourceIsReachableAndReturnError(nil) {
            try! FileManager.default.removeItem(at: fileURL)
            print("Deleting Recording...")
        }
    }
    
    open func isRecording()->Bool
    {
        return recording
    }
    
    open func recordAudio(_ startHandler:@escaping RecorderStartHandler)
    {
        DispatchQueue.main.async { () -> Void in
            //init
            let audioSession:AVAudioSession = AVAudioSession.sharedInstance()
            
            self.deleteRecording()
            
            //ask for permission
            if (audioSession.responds(to: #selector(AVAudioSession.requestRecordPermission(_:)))) {
                AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool)-> Void in
                    if granted {
                        print("granted")
                        
                        //set category and activate recorder session
                        try! audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
                        try! audioSession.setActive(true)
                        
                        //create AnyObject of settings
                        let settings: [String : AnyObject] = [
                            AVFormatIDKey:Int(kAudioFormatMPEG4AAC) as AnyObject, //Int required in Swift2
                            AVSampleRateKey:11025.0 as AnyObject,
                            AVNumberOfChannelsKey:2 as AnyObject,
                            AVEncoderAudioQualityKey:AVAudioQuality.low.rawValue as AnyObject
                        ]
                        
                        //record
                        try! self.audioRecorder = AVAudioRecorder(url: self.fileURL, settings: settings)
                        self.audioRecorder?.record()
                        self.recording = true
                        startHandler(true)
                        
                    } else{
                        print("not granted")
                        startHandler(false)
                    }
                })
            }
        }
    }
    
    //Returns the audio file url
    open func stopRecorder()->URL
    {
        DispatchQueue.main.async { () -> Void in
            self.audioRecorder?.stop()
            self.recording = false
        }
        
        return fileURL
    }
    
    //Returns false if error
    fileprivate func initPlayer() {
        let audioSession:AVAudioSession = AVAudioSession.sharedInstance()
        try! audioSession.setCategory(AVAudioSessionCategoryPlayback)
        try! audioSession.setActive(true)
        self.audioPlayer = AVPlayer(playerItem: AVPlayerItem(asset: AVAsset(url: self.fileURL)))
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(VoiceMemoRecorder.itemDidFinishPlaying(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.audioPlayer!.currentItem)
    }
    
    open func playing()->Bool
    {
        return (self.audioPlayer?.rate > 0) ?? false
    }
    
    open func play(_ progressHandler:@escaping PlayerProgressHandler) {
        audioPlayerProgressHandler = progressHandler
        
        DispatchQueue.main.async { () -> Void in
            self.audioPlayerProgressTimer?.invalidate()
            self.audioPlayerProgressTimer = nil
            
            if self.audioPlayer == nil {
                //Player is reset when the recording has been deleted (new recording)
                self.initPlayer()
            }
            
            self.audioPlayer?.play()
            self.reportProgress(false)
            self.audioPlayerProgressTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(VoiceMemoRecorder.updatePlayerProgress), userInfo: nil, repeats: true)
        }
    }
    
    open func pause() {
        DispatchQueue.main.async { () -> Void in
            self.audioPlayer?.pause()
            self.audioPlayerProgressTimer?.invalidate()
            self.audioPlayerProgressTimer = nil
            self.reportProgress(false)
        }
    }
    
    open func updatePlayerProgress()
    {
        reportProgress(false)
    }
    
    fileprivate func reportProgress(_ finished:Bool)
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
        audioPlayerProgressHandler?(progress, playing, finished)
    }
    
    //MARK: Audio Player Delegate
    
    open func itemDidFinishPlaying(_ notification:Notification) {
        
        reportProgress(true)
        
        self.reset()
    }
}
