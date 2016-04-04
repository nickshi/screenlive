//  https://github.com/1024jp/NSData-GZIP/blob/master/Sources/NSData%2BGZIP.swift
//  NSDataExtension.swift
//  Online Learning
//
//  Created by Junmin Liu on 9/4/15.
//  Copyright (c) 2015 depaul. All rights reserved.
//

import Foundation


private let CHUNK_SIZE : Int = 2 ^ 14
private let STREAM_SIZE : Int32 = Int32(sizeof(z_stream))


public extension NSData
{
    /// Return gzip-compressed data object or nil.
    public func gzippedData() -> NSData?
    {
        if self.length == 0 {
            return NSData()
        }
        
        var stream = self.createZStream()
        var status : Int32
        
        //status = deflateInit2_(&stream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, MAX_WBITS + 16, MAX_MEM_LEVEL, Z_DEFAULT_STRATEGY, ZLIB_VERSION, STREAM_SIZE)
        status = deflateInit_(&stream, Z_DEFAULT_COMPRESSION, ZLIB_VERSION, STREAM_SIZE)
        
        if status != Z_OK {
            if let errorMessage = String.fromCString(stream.msg) {
                print(String(format: "Compression failed: %@", errorMessage))
            }
            
            return nil
        }
        
        let data = NSMutableData(length: CHUNK_SIZE)!
        while stream.avail_out == 0 {
            if Int(stream.total_out) >= data.length {
                data.length += CHUNK_SIZE
            }
            
            stream.next_out = UnsafeMutablePointer<Bytef>(data.mutableBytes).advancedBy(Int(stream.total_out))
            stream.avail_out = uInt(data.length) - uInt(stream.total_out)
            
            deflate(&stream, Z_FINISH)
        }
        
        deflateEnd(&stream)
        data.length = Int(stream.total_out)
        
        return data
    }
    
    
    /// Return gzip-decompressed data object or nil.
    public func gunzippedData() -> NSData?
    {
        if self.length == 0 {
            return NSData()
        }
        
        var stream = self.createZStream()
        var status : Int32
        
       //status = inflateInit2_(&stream, MAX_WBITS + 32, ZLIB_VERSION, STREAM_SIZE)
       status = inflateInit_(&stream, ZLIB_VERSION, STREAM_SIZE)
        if status != Z_OK {
            if let errorMessage = String.fromCString(stream.msg) {
                print(String(format: "Decompression failed: %@", errorMessage))
            }
            return nil
        }
        
        let data = NSMutableData(length: self.length * 2)!
        repeat {
            if Int(stream.total_out) >= data.length {
                data.length += self.length / 2;
            }
            
            stream.next_out = UnsafeMutablePointer<Bytef>(data.mutableBytes).advancedBy(Int(stream.total_out))
            stream.avail_out = uInt(data.length) - uInt(stream.total_out)
            
            status = inflate(&stream, Z_SYNC_FLUSH)
        } while status == Z_OK
        
        if inflateEnd(&stream) != Z_OK || status != Z_STREAM_END {
            if let errorMessage = String.fromCString(stream.msg) {
                print(String(format: "Decompression failed: %@", errorMessage))
            }
            return nil
        }
        
        data.length = Int(stream.total_out)
        
        return data
    }
    
    
    private func createZStream() -> z_stream
    {
        return z_stream(
            next_in: UnsafeMutablePointer<Bytef>(self.bytes),
            avail_in: uint(self.length),
            total_in: 0,
            next_out: nil,
            avail_out: 0,
            total_out: 0,
            msg: nil,
            state: nil,
            zalloc: nil,
            zfree: nil,
            opaque: nil,
            data_type: 0,
            adler: 0,
            reserved: 0
        )
    }
}