//
//  ImageProcess.swift
//  SimpleCoreML
//
//  Created by 何家瑋 on 2017/7/13.
//  Copyright © 2017年 何家瑋. All rights reserved.
//

import Foundation
import CoreGraphics
import CoreVideo
import AVFoundation

struct imageProcess {
        
        static func cgImageToPixelBuffer(_ image : CGImage) -> CVPixelBuffer? {
                let size = CGSize(width: CoreMLModel.bufferWidth, height: CoreMLModel.bufferHeight)
                var pixelBuffer : CVPixelBuffer? = nil
                
                let pixelAttributes = [ kCVPixelBufferCGImageCompatibilityKey : true,
                                     kCVPixelBufferCGBitmapContextCompatibilityKey : true ]
                
                let createResult = CVPixelBufferCreate(kCFAllocatorDefault,
                                                                          Int(size.width),
                                                                          Int(size.height),
                                                                          kCVPixelFormatType_32ARGB,
                                                                          pixelAttributes as CFDictionary,
                                                                          &pixelBuffer)
                if createResult != kCVReturnSuccess {
                        return nil
                }
                
                CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags.init(rawValue: 0))
                
                let pixelBufferData = CVPixelBufferGetBaseAddress(pixelBuffer!)
                let colorSpace = CGColorSpaceCreateDeviceRGB()
                let context = CGContext(data: pixelBufferData,
                                                     width: Int(size.width),
                                                     height: Int(size.height),
                                                     bitsPerComponent: 8,
                                                     bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!),
                                                     space: colorSpace,
                                                     bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
                let rect = CGRect(x: 0, y: 0, width: Int(size.width), height: Int(size.height))
                context?.draw(image, in: rect)
                
                CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags.init(rawValue: 0))
                
                return pixelBuffer
        }
}

extension CMSampleBuffer {
        var cgimage : CGImage? {
                get {
                        guard let imageRef = CMSampleBufferGetImageBuffer(self) else {
                                return nil
                        }
                        
                        CVPixelBufferLockBaseAddress(imageRef, CVPixelBufferLockFlags.init(rawValue: 0))
                        
                        let imageBufferData = CVPixelBufferGetBaseAddress(imageRef)
                        let size = CGSize(width: CVPixelBufferGetWidth(imageRef), height: CVPixelBufferGetHeight(imageRef))
                        let colorSpace = CGColorSpaceCreateDeviceRGB()
                        let context = CGContext(data: imageBufferData,
                                                width: Int(size.width),
                                                height: Int(size.height),
                                                bitsPerComponent: 8,
                                                bytesPerRow: CVPixelBufferGetBytesPerRow(imageRef),
                                                space: colorSpace,
                                                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
                        guard let cgimage = context?.makeImage() else {
                                return nil
                        }
                        
                        CVPixelBufferUnlockBaseAddress(imageRef, CVPixelBufferLockFlags.init(rawValue: 0))
                        
                        return cgimage
                }
        }
}
