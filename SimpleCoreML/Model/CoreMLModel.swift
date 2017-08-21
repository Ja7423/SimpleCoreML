//
//  CoreMLModel.swift
//  SimpleCoreML
//
//  Created by 何家瑋 on 2017/7/26.
//  Copyright © 2017年 何家瑋. All rights reserved.
//

import Foundation
import CoreVideo
import CoreML

class CoreMLModel: NSObject {
        
        private static var sharedInstance : CoreMLModel?
        let model = Resnet50()
        static var bufferWidth : Double {
                get {
                        return 224
                }
        }
        
        static var bufferHeight : Double {
                get {
                        return 224
                }
        }
        
        static func sharedModel() -> CoreMLModel {
                if sharedInstance == nil {
                        sharedInstance = CoreMLModel()
                }
                
                return sharedInstance!
        }
        
        func prediction(pixelBuffer: CVPixelBuffer) -> String? {
                do {
                        let analyzeResult = try model.prediction(image: pixelBuffer).classLabel
                        return analyzeResult
                } catch let err{
                        print("err : ", err)
                        return nil
                }
        }
}
