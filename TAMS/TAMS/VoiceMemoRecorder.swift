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

open class VoiceMemoRecorder: NSObject, AVAudioPlayerDelegate {
    
    let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("voiceRecording.aac")
    var audioRecorder:AVAudioRecorder?
    var recording:Bool = false

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
        NotificationCenter.default.removeObserver(self)
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
}
