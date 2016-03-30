//
//  RecordScreen.swift
//  screenlive
//
//  Created by nick.shi on 16/3/15.
//  Copyright © 2016年 nick.shi. All rights reserved.
//

import Cocoa


class ScreenRecord:NSObject {
    var lastFrame:ScreenFrame?
    
    var curOffsetIndex:Int = 0
    
    var indexData:NSMutableData?
    
    var imagesData:NSMutableData?
    
    var timer:NSTimer?
    
    var curSecond:Int = 0
    
    var seriel_queue = dispatch_queue_create("com.raywenderlich.GooglyPuff.photoQueue", DISPATCH_QUEUE_SERIAL)
    
    func beginRecord() {
        
        if let aTimer = timer {
            aTimer.invalidate()
            timer = nil
        }

        
        indexData = NSMutableData()
        imagesData = NSMutableData()
        curSecond = 0
        
        
         timer = NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: #selector(ScreenRecord.captureScreen), userInfo: nil, repeats: true)
    }
    
    func endRecord() {
        if let aTimer = timer {
            aTimer.invalidate()
            timer = nil
            
            curSecond = 0
            
            
            
            dispatch_async(seriel_queue, { () -> Void in
                self.indexData!.gzippedData()!.writeToFile("/Users/nick/Desktop/clip/indexData.data", atomically: true)
                self.imagesData!.writeToFile("/Users/nick/Desktop/clip/imagesData.data", atomically: true)
            })
        }

    }
    
    func captureScreen()
    {
        let image:CGImageRef? = CGDisplayCreateImage(CGMainDisplayID())
        
        if let capturedImage = image {
            let nscapturedImage = NSImage(CGImage: capturedImage,size: NSSize(width: CGFloat(CGImageGetWidth(image)), height: CGFloat(CGImageGetHeight(image))))
            
            self.saveNSImageAsFrame(nscapturedImage, second: self.curSecond)
            
            
            curSecond += 1
            
            
        }
    }
    
    private func saveNSImageAsFrame(frameImage:NSImage, second:Int)
    {
        let curFrame = ScreenFrame(second: second)
        
        for idx in 0...63 {
            let cgImage = frameImage[idx]
            
            let nsImage = NSImage(CGImage: cgImage!, size: NSSize(width: CGFloat(CGImageGetWidth(cgImage)), height: CGFloat(CGImageGetHeight(cgImage))))
            
            let imageData = nsImage.TIFFRepresentation
            
            var length = imageData!.length
            
            let row:Int = idx / 8
            let column:Int = idx % 8
            
            var grid_2:Int = row<<4
            grid_2 = grid_2 | column
            
            let tile = ScreenTile(grid: grid_2)
            
            tile.length = length
            
            tile.imageData = imageData
            
            curFrame.addTile(tile)
            
            var sec:UInt16 = UInt16(second)
            indexData!.appendBytes(&sec, length: 2)
            
            var grid:UInt8 = UInt8(grid_2)
            indexData!.appendBytes(&grid, length: 1)
            
            
            if let prevFrame = lastFrame {
                let prevTile = prevFrame.tiles[idx]
                let isSame = prevTile?.imageData?.isEqualToData(tile.imageData!)
                //print("isSame \(idx) \(isSame)")
                if isSame == true {
                    indexData!.appendBytes(&(prevTile!.offset), length: 4)
                    tile.offset = prevTile!.offset
                    
                    
                }
                else
                {
                    indexData!.appendBytes(&curOffsetIndex, length: 4)
                    imagesData!.appendBytes((imageData?.bytes)!, length: length)
                    tile.offset = curOffsetIndex
                    curOffsetIndex += length
                    
                    //print("\(idx)")
                }
                
            }
            else
            {
                indexData!.appendBytes(&curOffsetIndex, length: 4)
                imagesData!.appendBytes((imageData?.bytes)!, length: length)
                tile.offset = curOffsetIndex
                curOffsetIndex += length
            }
            
            indexData!.appendBytes(&length, length: 4)
        }
        
        lastFrame = curFrame
    }
}
