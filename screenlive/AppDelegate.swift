//
//  AppDelegate.swift
//  screenlive
//
//  Created by nick.shi on 16/2/27.
//  Copyright © 2016年 nick.shi. All rights reserved.
//

import Cocoa


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate,ScreenRecordDelegate {
    
    var curSecond:Int = 0
    var screenShot:ScreenShot?
    var recordScreen:ScreenRecord?
    var statusItem: NSStatusItem?;
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        
        statusItem =  NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)
        statusItem!.button?.image = NSImage(named: "player_record_start")
        statusItem!.highlightMode = true
        statusItem!.action = #selector(AppDelegate.recordStatusItemSelected)
        statusItem!.target = self
        statusItem!.title = ""
        
        recordScreen = ScreenRecord()
        recordScreen?.recordDelegate = self
    }
    
    
    func recordStatusItemSelected(){
        if recordScreen?.recording == true {
            recordScreen?.endRecord()
            statusItem!.title = ""
        }
        else
        {
            recordScreen?.beginRecord()
        }
    }
    
    func screenRecordBegin() {
        statusItem!.button?.image = NSImage(named: "player_record_stop")
    }
    
    func screenRecordEnd() {
        statusItem!.button?.image = NSImage(named: "player_record_start")
    }
    
    func screenRecordTimeDuration(duration: Int) {
        statusItem!.title = formatTime(duration)
    }
    
    func formatTime(second:Int) ->String{
        let sec = second % 60
        let min = (second / 60) % 60
        let hr = second / 3600
        
        return String(format: "%.2d:%.2d:%.2d", arguments: [hr,min,sec])
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    
    @IBAction func captureMenuItemSelect(sender: NSMenuItem){

        
        recordScreen?.beginRecord()
    }
    
    @IBAction func captureEndMenuItemSelect(sender: NSMenuItem)
    {

        recordScreen?.endRecord()
    }

    
    func saveImage(imageRef: CGImageRef, path: String) {
        let url:CFURLRef = NSURL(fileURLWithPath: path)
        
        let destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, nil)
        
        CGImageDestinationAddImage(destination!, imageRef, nil);
        
        
        if CGImageDestinationFinalize(destination!) {
            print("image saved successfully")
        }
    }
    
    @IBAction func parse(sender: NSMenuItem){
        
        screenShot = ScreenShot(indexFilePath: "/Users/nick/Desktop/clip/indexData.data", dataFilePath: "/Users/nick/Desktop/clip/imagesData.data")
        
        let app = NSApplication.sharedApplication()
        
        let window: NSWindow = app.windows[0]
        
        let viewController = window.contentViewController as! ViewController
        
        viewController.screenPlayer.loadScreenShot(screenShot!)
        
        NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(AppDelegate.Play), userInfo: self, repeats: true)

    }

    
    func Play(){

        
        let app = NSApplication.sharedApplication()
        
        let window: NSWindow = app.windows[0]
        
        let viewController = window.contentViewController as! ViewController
        
        viewController.screenPlayer.play(curSecond)
        
        curSecond += 1;
        
        curSecond = max(0, min(curSecond, (screenShot?.seconds.count)!-1))
        
    }


}



