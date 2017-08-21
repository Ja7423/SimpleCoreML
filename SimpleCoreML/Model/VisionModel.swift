//
//  VisionModel.swift
//  SimpleCoreML
//
//  Created by 何家瑋 on 2017/8/9.
//  Copyright © 2017年 何家瑋. All rights reserved.
//

import Foundation
import UIKit
import Vision


class VisionModel: NSObject {
        var coreMLModel : MLModel?
        private var finishCompletion : ((VNRequest, Error?) -> Void)?

        override init() {
                super.init()
        }
        
        init(with model : MLModel) {
                super.init()
                coreMLModel = model
        }
        
        func performVisionRequests(requests : [visionRequestType], on pixelBuffer : CVPixelBuffer, completionHandler : @escaping (_ request : VNRequest, _ error : Error?) -> Void) {
                
                self.finishCompletion = completionHandler
                var performRequests = [VNRequest]()
                for type in requests {
                        switch type {
                        case .mlRequest:
                                guard let request = mlRequest else { break }
                                performRequests.append(request)
                        case .faceRequest:
                                performRequests.append(faceRequest)
                        case .faceLandMarkRequest:
                                performRequests.append(faceLandMarkRequest)
                        case .textRequest:
                                performRequests.append(textRequest)
                        }
                }
                
                let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation(rawValue: 6)!, options: [:])
                do {
                        try handler.perform(performRequests)
                } catch {
                        print(error)
                }
        }
}

extension VisionModel {
        enum visionRequestType : Int {
                case mlRequest
                case faceRequest
                case faceLandMarkRequest
                case textRequest
        }
        
        // MARK: - request
        var mlRequest : VNCoreMLRequest? {
                guard let coreML = coreMLModel else { return nil }
                guard let model = try? VNCoreMLModel(for: coreML) else { return nil }
                let coreMLRequest = VNCoreMLRequest(model: model, completionHandler: self.finishCompletion)
                
                return coreMLRequest
        }
        
        var faceRequest : VNDetectFaceRectanglesRequest {
                let request = VNDetectFaceRectanglesRequest(completionHandler: self.finishCompletion)
                return request
        }
        
        var faceLandMarkRequest : VNDetectFaceLandmarksRequest {
                let request = VNDetectFaceLandmarksRequest(completionHandler: self.finishCompletion)
                return request
        }
        
        var textRequest : VNDetectTextRectanglesRequest {
                let request = VNDetectTextRectanglesRequest(completionHandler: self.finishCompletion)
                request.reportCharacterBoxes = true
                return request
        }
}

