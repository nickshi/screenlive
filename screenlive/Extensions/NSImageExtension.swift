//
//  NSImageExtension.swift
//  screenlive
//
//  Created by nick.shi on 16/3/14.
//  Copyright © 2016年 nick.shi. All rights reserved.
//

import Cocoa
extension NSImage {
    var CGImage: CGImageRef? {
        get {
            var imageRect = NSRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
            let imageRef = self.CGImageForProposedRect(&imageRect, context: nil, hints: nil)
            
            return imageRef
        }
    }
    
    var imagePNGRepresentation: NSData {
        return NSBitmapImageRep(data: TIFFRepresentation!)!.representationUsingType(.NSPNGFileType, properties: [:])!
    }
    
    var imageJPEGRepresentation: NSData {
        return NSBitmapImageRep(data: TIFFRepresentation!)!.representationUsingType(.NSJPEGFileType, properties: [:])!
    }
    
    subscript(nIndex:Int) ->CGImageRef?
     {
        let n = max(0, min(nIndex, 63))
        let row = n / 8
        let col = n % 8
        let pWidth = self.size.width / 8
        let pHeight = self.size.height / 8
        let cgImage = self.CGImage
        
        let rect = NSRect(x: CGFloat(col) * pWidth, y: CGFloat(row) * pHeight, width: pWidth, height: pHeight)
        let desImage = CGImageCreateWithImageInRect(cgImage, rect)
        
        return desImage
        
    }
    
}
