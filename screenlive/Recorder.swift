//
//  Recorder.swift
//  screenlive
//
//  Created by nick.shi on 16/3/4.
//  Copyright © 2016年 nick.shi. All rights reserved.
//

import Foundation
import AVFoundation


class Recorder : NSObject, AVCaptureFileOutputRecordingDelegate {
    private var mSession : AVCaptureSession?
    private var mMovieFileOutput : AVCaptureMovieFileOutput?
    private var mTimer : NSTimer?
    
    
    func screenRecording(desPath : NSURL){
        mSession = AVCaptureSession()
        
        mSession!.sessionPreset = AVCaptureSessionPresetMedium
        
        let displayId : CGDirectDisplayID = CGMainDisplayID()
        
        let input = AVCaptureScreenInput(displayID: displayId)
        
        if input == nil {
            return
        }
        
        if mSession!.canAddInput(input!) {
            mSession!.addInput(input!)
        }
        
        mMovieFileOutput = AVCaptureMovieFileOutput()
        if mSession!.canAddOutput(mMovieFileOutput!) {
            mSession!.addOutput(mMovieFileOutput!)
        }
        
        mSession?.startRunning()
        
        if NSFileManager.defaultManager().fileExistsAtPath(desPath.path!) {
            
            
            do
            {
                 try NSFileManager.defaultManager().removeItemAtPath(desPath.path!)
                
            }
            catch{
                
            
            }
        }
        
        mMovieFileOutput?.startRecordingToOutputFileURL(desPath, recordingDelegate: self)
        
        mTimer = NSTimer(timeInterval: 5, target: self, selector: Selector("finishRecord:"), userInfo: nil, repeats: false)
    }
    
    func finishRecord(timer: NSTimer){
        mMovieFileOutput?.stopRecording()
        mTimer = nil
    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        mSession?.stopRunning()
    }
}
