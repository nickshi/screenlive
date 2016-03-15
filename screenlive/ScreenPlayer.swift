//
//  ScreenPlayer.swift
//  screenlive
//
//  Created by nick.shi on 16/3/15.
//  Copyright © 2016年 nick.shi. All rights reserved.
//

import Cocoa

class ScreenPlayer: NSView {
    private(set) var screenShot: ScreenShot?
    
    var second: Int = 0
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        
    }
    
    func loadScreenShot(screenShot: ScreenShot) {
        self.screenShot = screenShot
    }
    
    func play() {
        self.needsDisplay = true
    }
    
    func play(second: Int){
        self.second = second
        self.needsDisplay = true;
    }
    
    func loadFrame(second: Int) ->ScreenFrame? {
        if let screenShot = self.screenShot {
            if(screenShot.seconds.count > 0) {
                var frameSecond: Int = screenShot.seconds.count - 1
                for (var i = 0; i < screenShot.seconds.count; i++) {
                    let s = screenShot.seconds[i]
                    if(s == second) {
                        frameSecond = s
                        break
                    }
                    else if(s > second) {
                        frameSecond = (i > 0 ? screenShot.seconds[i-1] : s)
                        break
                    }
                }
                return screenShot.fullFrames[frameSecond]
            }
        }
        return nil
    }
    
    func drawFrameImage(frame: ScreenFrame)  -> NSImage {
        let image = NSImage(size: NSMakeSize(1024,768))
        
        image.lockFocus()
        let tileWidth:CGFloat = 1024 / 8
        let tileHeight:CGFloat = 768 / 8
        if let screenShot = self.screenShot {
            for (_,tile) in frame.tiles {
                if let imgData = screenShot.loadTileData(tile) {
                    if let img = NSImage(data: imgData) {
                        let rect = NSMakeRect(tileWidth * CGFloat(tile.col), 768 - tileHeight * CGFloat(tile.row + 1), tileWidth, tileHeight)
                        img.drawInRect(rect)
                    }
                }
            }
        }
        image.unlockFocus()
        
        return image
    }
    
    
    override func drawRect(dirtyRect: NSRect) {
        NSColor.blackColor().set()
        NSRectFill(self.bounds)
        
        if let frame = self.loadFrame(self.second), let _ = self.screenShot {
            
            let width: CGFloat, height:CGFloat
            if (self.bounds.height / self.bounds.width > 3 / 4) {
                width = CGFloat(self.bounds.width)
                height = width * 3 / 4
            } else {
                height = CGFloat(self.bounds.height)
                width = height * 4 / 3
            }
            
            let img = self.drawFrameImage(frame)
            img.drawInRect(NSMakeRect(0, 0, width, height))
        }
    }
}
