//
//  ScreenIndex.swift
//  Online Learning
//
//  Created by Jim Liu on 8/27/15.
//  Copyright (c) 2015 depaul. All rights reserved.
//

import Foundation


/// We have 8x8=64 tiles per screen shot
/// this is the data for every tile
class ScreenTile : NSCoding {
    
    var imageData: NSData?
    /// Time second
    private(set) var timestamp: Int = 0
    
    /// Row and Col
    private(set) var grid: Int = 0
    
    /// Row index on screen
    /// From 0 to 7
    private(set) var row: Int
    
    /// Col index on screen
    /// From 0 to 7
    private(set) var col: Int
    
    /// Offset in data file
     var offset: Int = 0
    
    /// Lengh in data file
     var length: Int = 0
    
    /// Init from index data
    init(data:NSData, offset: Int) {
        var _timestamp: UInt16 = 0
        var _grid: UInt8 = 0
        var _offset: Int32 = 0
        var _length: Int32 = 0
        data.getBytes(&_timestamp, range: NSMakeRange(offset, 2))
        data.getBytes(&_grid, range: NSMakeRange(offset + 2, 1))
        data.getBytes(&_offset, range: NSMakeRange(offset + 3, 4))
        data.getBytes(&_length, range: NSMakeRange(offset + 7, 4))
        self.timestamp = Int(_timestamp)
        self.row = Int(_grid >> 4)
        self.col = Int(_grid & 0xf)
        self.grid = self.row * 8 + self.col // 8 x 8
        self.length = Int(_length)
        self.offset = Int(_offset)
        
        
        
    }
    
    
    init(grid: Int) {
        self.row = Int(grid >> 4)
        self.col = Int(grid & 0xf)
        self.grid = self.row * 8 + self.col // 8 x 8
    }
    
    @objc func encodeWithCoder(coder: NSCoder) {
        coder.encodeInt(Int32(self.row), forKey: "row")
        coder.encodeInt(Int32(self.col), forKey: "col")
        coder.encodeInt(Int32(self.grid), forKey: "grid")
        coder.encodeInt(Int32(self.timestamp), forKey: "timestamp")
        coder.encodeInt(Int32(self.length), forKey: "length")
        coder.encodeInt(Int32(self.offset), forKey: "offset")
    }
    
    @objc required init?(coder decoder: NSCoder) {
        self.row = Int(decoder.decodeIntForKey("row"))
        self.col = Int(decoder.decodeIntForKey("col"))
        self.grid = Int(decoder.decodeIntForKey("grid"))
        self.timestamp = Int(decoder.decodeIntForKey("timestamp"))
        self.length = Int(decoder.decodeIntForKey("length"))
        self.offset = Int(decoder.decodeIntForKey("offset"))
    }
    
    /// Clone the offset and length data from another tile
    func cloneTileRange(tile: ScreenTile) {
        self.offset = tile.offset
        self.length = tile.length
    }
}

/// A screenshot at specific second
class ScreenFrame : NSCoding {
    
    /// Time second
    var second: Int
    
    /// all 8x8 tiles in frame
    var tiles: [Int : ScreenTile]
    
    init(second: Int) {
        self.second = second
        self.tiles = [Int : ScreenTile]()
    }
    
    func addTile(tile: ScreenTile) {
        self.tiles[tile.grid] = tile
    }
    
    
    @objc func encodeWithCoder(coder: NSCoder) {
        coder.encodeInt(Int32(self.second), forKey: "second")
        coder.encodeObject(self.tiles, forKey: "tiles")
    }
    
    @objc required init?(coder decoder: NSCoder) {
        self.second = Int(decoder.decodeIntForKey("second"))
        self.tiles = decoder.decodeObjectForKey("tiles") as! [Int : ScreenTile]
    }
    
}

/// Screen data parsed from index file
class ScreenShot : NSCoding {
    
    /// Screen Index Data
    private var indexData: NSData?
    
    /// Screen Data
    private var screenData: NSData?
    
    /// Screen Index file path
    var indexFilePath: String
    
    /// Screen Data file path
    var dataFilePath: String
    
    
    /// All seconds
    private(set) var seconds: [Int]
    
    /// All frames, remove the unchange tiles
    private(set) var frames: [Int: ScreenFrame]
    
    /// All frames, with full tils for every frame
    private(set) var fullFrames: [Int: ScreenFrame]
    
    
    init(indexFilePath: String, dataFilePath: String) {
        self.seconds = [Int]()
        self.frames = [Int: ScreenFrame]()
        self.fullFrames = [Int: ScreenFrame]()
        self.indexFilePath = indexFilePath
        self.dataFilePath = dataFilePath
        
        self.indexData = NSData(contentsOfFile: self.indexFilePath)
        self.screenData = NSData(contentsOfFile: self.dataFilePath)
        
        self.parse(); // parse index file. @Warning: Maybe this is not the best position for parsing index data
    }
    
    
    @objc func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(self.seconds, forKey: "seconds")
        coder.encodeObject(self.frames, forKey: "frames")
        coder.encodeObject(self.fullFrames, forKey: "fullFrames")
        coder.encodeObject(self.indexFilePath, forKey: "indexFilePath")
        coder.encodeObject(self.dataFilePath, forKey: "dataFilePath")
    }
    
    @objc required init?(coder decoder: NSCoder) {
        self.seconds = decoder.decodeObjectForKey("seconds") as! [Int]
        self.frames = decoder.decodeObjectForKey("frames") as! [Int: ScreenFrame]
        self.fullFrames = decoder.decodeObjectForKey("fullFrames") as! [Int: ScreenFrame]
        self.indexFilePath = decoder.decodeObjectForKey("indexFilePath") as! String
        self.dataFilePath = decoder.decodeObjectForKey("dataFilePath") as! String
        
        self.screenData = NSData(contentsOfFile: self.dataFilePath)
    }
    
    /// Parse index data
    private func parse() {
        if let data = self.indexData {
            // decompress the data first
            if let decompressedData = data.gunzippedData() {
                var offset: Int = 0;
                var lastTile: ScreenTile? = nil
                var seconds = [Int]()
                // 11 = Int16(2) + Int8(1) + Int32(4) + Int32(4)
                while (offset < decompressedData.length) {
                    let tile = ScreenTile(data: decompressedData, offset: offset);
                    
                    // if offset is -1, copy previous one
                    if (tile.offset == -1 && lastTile != nil) {
                        tile.cloneTileRange(lastTile!)
                    }
                    let second = Int(tile.timestamp)
                    var frame = self.frames[second]
                    
                    if (frame == nil) {
                        frame = ScreenFrame(second: second)
                        self.frames[second] = frame
                        seconds.append(second)
                    }
                    frame!.addTile(tile)
                    self.frames[second] = frame!
                    
                    lastTile = tile;
                    offset += 11;
                }
                
                seconds.sortInPlace({ $0 < $1 })
                self.seconds = seconds
                
                var prevFrame: ScreenFrame? = nil
                for s in self.seconds {
                    
                    let frame = self.frames[s]
                    let fullFrame = ScreenFrame(second: s);
                    if (prevFrame == nil) {
                        prevFrame = frame
                    }
                    
                    for (var i = 0; i < 64; i++) {
                        if let tile = frame!.tiles[i] {
                            fullFrame.addTile(tile)
                        } else if let previousTile = prevFrame!.tiles[i] { // if can't find the tile from current frame
                            // use the previous's
                            fullFrame.addTile(previousTile)
                        } else { // in case the first frame misses any tile
                            fullFrame.addTile(ScreenTile(grid: i))
                            
                            
                          
                        }
                    }
                    self.fullFrames[s] = fullFrame
                    
                    prevFrame = fullFrame;
                }
            }
            
        }
    }
    
    // Load tile's image data
    func loadTileData(tile: ScreenTile) -> NSData? {
        if let screenData = self.screenData {
            if (tile.offset + tile.length <= screenData.length) {
                return screenData.subdataWithRange(NSMakeRange(tile.offset, tile.length))
            }
        }
        return nil
    }
    
}