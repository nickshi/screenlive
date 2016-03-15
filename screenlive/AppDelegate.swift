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
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    
    
    func captureScreen()-> Void{
        
        let savePanel: NSSavePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["png"]
        if savePanel.runModal() == NSFileHandlingPanelOKButton{
            
            print("NSFileHandlingPanelOKButton")
            
            let image:CGImageRef? = CGDisplayCreateImage(CGMainDisplayID())
            
            
            
            if let savedImage = image {
                
                let app = NSApplication.sharedApplication()
                
                let window: NSWindow = app.windows[0]
                
                let viewController = window.contentViewController as! ViewController
                
                let nImage = NSImage(CGImage: savedImage,size: NSSize(width: CGFloat(CGImageGetWidth(image)), height: CGFloat(CGImageGetHeight(image))))
                
                viewController.imageView.image = nImage
                
                for index in 0...63 {
                    let pieceOfImage = nImage[index]
                    
                    let npImage = NSImage(CGImage: pieceOfImage!,size: NSSize(width: CGFloat(CGImageGetWidth(pieceOfImage)), height: CGFloat(CGImageGetHeight(pieceOfImage))))
                    
                    
                    let finalPath = savePanel.URL!.path!
                    
                    let idx = finalPath.characters.indexOf(".")
                    
                    let path = finalPath.substringToIndex(idx!)
                    
                    let ext = finalPath.substringFromIndex(idx!)
                    
                    let savePath = path + "\(index)" + ext
                    
                    print("\(savePath)")
                  
                    saveImage(npImage.CGImage!, path: savePath)
                }
 
                
            }
           
            
        }
        
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
        
        NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: "Play", userInfo: self, repeats: true)

    }

    
    func Play(){

        
        let app = NSApplication.sharedApplication()
        
        let window: NSWindow = app.windows[0]
        
        let viewController = window.contentViewController as! ViewController
        
        viewController.screenPlayer.play(curSecond)
        
        curSecond++;
        
        curSecond = max(0, min(curSecond, (screenShot?.seconds.count)!-1))
        
    }


}



