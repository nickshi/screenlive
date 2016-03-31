//
//  RecordScreen.swift
//  screenlive
//
//  Created by nick.shi on 16/3/15.
//  Copyright © 2016年 nick.shi. All rights reserved.
//

import Cocoa

protocol ScreenRecordDelegate {
    func screenRecordBegin()
    func screenRecordEnd()
    func screenRecordTimeDuration(duration:Int)
}

class ScreenRecord:NSObject {
    var lastFrame:ScreenFrame?
    
    var curOffsetIndex:Int = 0
    
    var indexData:NSMutableData?
    
    var imagesData:NSMutableData?
    
    var timer:NSTimer?
    
    var curSecond:Int = 0
    
    var recording:Bool = false
    
    var seriel_queue = dispatch_queue_create("com.raywenderlich.GooglyPuff.photoQueue", DISPATCH_QUEUE_SERIAL)
    
    var recordDelegate:ScreenRecordDelegate?
    
    func beginRecord() {
        
        if let aTimer = timer {
            aTimer.invalidate()
            timer = nil
        }

        
        indexData = NSMutableData()
        imagesData = NSMutableData()
        curSecond = 0
        curOffsetIndex = 0
        recording = true
        timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(ScreenRecord.captureScreen), userInfo: nil, repeats: true)
        
        recordDelegate?.screenRecordBegin()
    }
    
    func endRecord() {
        if let aTimer = timer {
            aTimer.invalidate()
            timer = nil
            
            curSecond = 0
            
            recording = false
            
            dispatch_async(seriel_queue, { () -> Void in
                self.indexData!.gzippedData()!.writeToFile("/Users/nick/Desktop/clip/indexData.data", atomically: true)
                self.imagesData!.writeToFile("/Users/nick/Desktop/clip/imagesData.data", atomically: true)
            })
        }
        
        recordDelegate?.screenRecordEnd()

    }
    
    func captureScreen()
    {
        let image:CGImageRef? = CGDisplayCreateImage(CGMainDisplayID())
        
        if let capturedImage = image {
            let nscapturedImage = NSImage(CGImage: capturedImage,size: NSSize(width: CGFloat(CGImageGetWidth(image)), height: CGFloat(CGImageGetHeight(image))))
            
            self.saveNSImageAsFrame(nscapturedImage, second: self.curSecond)
            
            
            curSecond += 1
            recordDelegate?.screenRecordTimeDuration(curSecond)
            
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
            
            var wrapped_grid:Int = row<<4
            wrapped_grid = wrapped_grid | column
            
            let tile = ScreenTile(grid: wrapped_grid)
            
            tile.length = length
            
            tile.imageData = imageData
            
            curFrame.addTile(tile)
            
            var sec:UInt16 = UInt16(second)
            indexData!.appendBytes(&sec, length: 2)
            
            var grid:UInt8 = UInt8(wrapped_grid)
            indexData!.appendBytes(&grid, length: 1)
            
            
            if let prevFrame = lastFrame {
                let prevTile = prevFrame.tiles[idx]
                let isSame = prevTile?.imageData?.isEqualToData(tile.imageData!)
              
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
