//
//  Helper.swift
//  screenlive
//
//  Created by Junhua Shi on 4/4/16.
//  Copyright © 2016 nick.shi. All rights reserved.
//

import Cocoa


class Helper {
    
    class func createSnapShotDirectoryIfNoExist() -> String
    {
        let fileManager = NSFileManager.defaultManager()
        let documentsPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first
        let snapshotPath = documentsPath?.stringByAppendingString("/SnapShot");
        
        var isDir : ObjCBool = true
        if !fileManager.fileExistsAtPath(snapshotPath!, isDirectory: &isDir) {
            do {
                try fileManager.createDirectoryAtPath(snapshotPath!, withIntermediateDirectories: true, attributes: nil)
                
            }
            catch {
                
            }
            
        }
        
        return snapshotPath!
    }
}
