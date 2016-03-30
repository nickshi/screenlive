//
//  AppDelegate.swift
//  screenlive
//
//  Created by nick.shi on 16/2/27.
//  Copyright © 2016年 nick.shi. All rights reserved.
//

import Cocoa


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var curSecond:Int = 0
    var screenShot:ScreenShot?
    var recordScreen:ScreenRecord?
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        
        let statusItem =  NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)
        statusItem.button?.image = NSImage(named: "player_record_start.png")
//        statusItem.highlightMode = true
//        statusItem.action = #selector(AppDelegate.recordStatusItemSelected)
//        statusItem.target = self
    }
    
    
    func recordStatusItemSelected(){
        
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    
    @IBAction func captureMenuItemSelect(sender: NSMenuItem){

        recordScreen = ScreenRecord()
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
        
        NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: #selector(AppDelegate.Play), userInfo: self, repeats: true)

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



