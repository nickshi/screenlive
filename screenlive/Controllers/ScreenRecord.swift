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

class Tile {
    var second:Int = 1
    var imageData:NSData?
    var grid:Int = 0
    
    
    init(sec:Int, grid:Int){
        self.second = sec
        self.grid = grid
    }
    
    
    func appendTileIndexToData(indexData:NSMutableData,imagesData:NSMutableData, inout offset:Int) {
        let row:Int = self.grid / 8
        let column:Int = self.grid % 8
        
        var wrapped_grid:Int = row<<4
        wrapped_grid = wrapped_grid | column
        
        
        var sec:UInt16 = UInt16(second)
        indexData.appendBytes(&sec, length: 2)
        
        var grid:UInt8 = UInt8(wrapped_grid)
        indexData.appendBytes(&grid, length: 1)
        
        indexData.appendBytes(&offset, length: 4)
        
        var length = imageData!.length
        
        indexData.appendBytes(&length, length: 4)
        
        
        
        if(offset != -1 )
        {
            offset += length
            imagesData.appendBytes((imageData?.bytes)!, length: length)
        }
        
    }
    
}


class TilePipe {
    var tiles:[Tile]
    
    var lastTile:Tile? {
        get {
            return self.tiles.last;
        }
    }
    
    init(){
        tiles = [Tile]()
        
    }
    
    func addTile(tile:Tile){
        tiles.append(tile)
    }
    
    
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
    
    
    var pipes:[Int:TilePipe]
    
    override init(){
        pipes = [Int:TilePipe]()
        
        for i in 0...63 {
            pipes[i] = TilePipe()
        }
    }
    
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
        captureScreen()
        recordDelegate?.screenRecordBegin()
    }
    
    func endRecord() {
        if let aTimer = timer {
            aTimer.invalidate()
            timer = nil
            
            curSecond = 1
            
            recording = false
            
            saveTilesToLocal()
        }
        
        recordDelegate?.screenRecordEnd()

    }
    
    func captureScreen()
    {
        let image:CGImageRef? = CGDisplayCreateImage(CGMainDisplayID())
        
        if let capturedImage = image {
            let nscapturedImage = NSImage(CGImage: capturedImage,size: NSSize(width: CGFloat(CGImageGetWidth(image)), height: CGFloat(CGImageGetHeight(image))))
            
            self.saveTiles(nscapturedImage, second: self.curSecond)
            
            curSecond += 1
            recordDelegate?.screenRecordTimeDuration(curSecond)
            
        }
    }
    
    private func saveTiles(frameImage:NSImage, second:Int){
        
        for idx in 0...63 {
            
            let cgImage = frameImage[idx]
            
            let pieceNSImage = NSImage(CGImage: cgImage!, size: NSSize(width: CGFloat(CGImageGetWidth(cgImage)), height: CGFloat(CGImageGetHeight(cgImage))))
            
            let imageData = pieceNSImage.imagePNGRepresentation
            
            let tile = Tile(sec: second, grid: idx)
            
            tile.imageData = imageData
            
            //remove the duplicate tile in sequence
            if let lastTile = pipes[idx]?.lastTile {
                if lastTile.imageData?.isEqualToData(tile.imageData!) == false {
                   
                    pipes[idx]?.addTile(tile)
                }
            }
            else {
                
                 pipes[idx]?.addTile(tile)
            }
            
            
        }
    }
    
    
    private func saveTilesToLocal() {
       
        //sort the tile and process the duplicate tile
        dispatch_async(seriel_queue, { () -> Void in
            
            var dic:[NSData:[Tile]] = [NSData:[Tile]]()
            
            self.pipes.forEach {
                sec, pipe in
                
                for tile in pipe.tiles {
           
                    if (dic[tile.imageData!] == nil) {dic[tile.imageData!] = [Tile]()}
                    
                    dic[tile.imageData!]?.append(tile)
                
                }
            }
            
            for (_, tiles) in dic {
                
                var is_first = true;
                for tile in tiles {
                   
                    if is_first {
                       tile.appendTileIndexToData(self.indexData!, imagesData: self.imagesData!, offset: &self.curOffsetIndex)
                    }
                    else
                    {
                        var offset = -1;
                        tile.appendTileIndexToData(self.indexData!, imagesData: self.imagesData!, offset: &offset)
                    }
                    
                    is_first = false
                }
            }
            
            let folderPath = Helper.createSnapShotDirectoryIfNoExist()
            let indexDataPath = folderPath.stringByAppendingString("/screenindex.pak")
            let screenDataPath = folderPath.stringByAppendingString("/screendata.pak")
            
            self.indexData!.gzippedData()!.writeToFile(indexDataPath, atomically: true)
            self.imagesData!.writeToFile(screenDataPath, atomically: true)
        })
        
 
    }
    

    
}
