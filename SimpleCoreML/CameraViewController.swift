//
//  CameraViewController.swift
//  SimpleCoreML
//
//  Created by 何家瑋 on 2017/7/22.
//  Copyright © 2017年 何家瑋. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class CameraViewController: UIViewController, CameraModelDelegate {
        
        let mlModel = CoreMLModel.sharedModel()
        let caModel = CameraModel()
        let vnModel = VisionModel()
        var requests = [VisionModel.visionRequestType]()
        var openVision = false {
                willSet {
                        updateRequests(newValue)
                }
                didSet {
                        if openVision {
                                visibleButton?.setImage(UIImage(named: "visible-open.png"), for: .normal)
                        } else {
                                visibleButton?.setImage(UIImage(named: "visible-close.png"), for: .normal)
                                identifyResult = ""
                        }
                }
        }
        
        var previewView = UIView()
        var dismissButton : UIButton?
        var visibleButton : UIButton?
        var switchButton : UIButton?
        var identifyLabel: UILabel?
        var identifyResult : String {
                set {
                        identifyLabel?.text = newValue
                }
                get {
                        return identifyLabel?.text ?? ""
                }
        }
        
        override func viewDidLoad() {
                super.viewDidLoad()
                vnModel.coreMLModel = mlModel.model.model
                caModel.delegate = self
                caModel.checkCameraAuthorization { (authResult) in
                        DispatchQueue.main.async {
                                self.setupUI()
                        }
                }
        }
        
        override func viewWillAppear(_ animated: Bool) {
                super.viewWillAppear(animated)
                caModel.launchCamera()
        }
        
        override func viewWillDisappear(_ animated: Bool) {
                super.viewWillDisappear(animated)
                caModel.closeCamera()
        }
        
        // MARK: - UI
        private func setupUI() {
                self.previewView.frame = CGRect(x: 0, y: 64, width: view.frame.width, height: 500)
                let layer = AVCaptureVideoPreviewLayer(session: caModel.captureSession)
                layer.frame = self.previewView.bounds
                self.previewView.layer.addSublayer(layer)
                self.view.addSubview(self.previewView)
                
                self.identifyLabel = self.configureIdentifyLabel()
                self.view.addSubview(self.identifyLabel!)
                
                self.dismissButton = self.configureDismissButton()
                self.view.addSubview(self.dismissButton!)
                
                self.visibleButton = self.configureVisibleButton()
                self.view.addSubview(self.visibleButton!)
                
                self.switchButton = self.configureSwitchButton()
                self.view.addSubview(self.switchButton!)
        }
        
        private func configureIdentifyLabel() -> UILabel{
                let label = UILabel(frame: CGRect(x: 10, y: self.view.frame.size.height - 50, width: self.view.frame.size.width - 20, height: 40))
                label.alpha = 0.6
                label.backgroundColor = UIColor.darkGray
                label.textColor = UIColor.white
                label.textAlignment = .center
                return label
        }
        
        private func configureDismissButton() -> UIButton {
                let button = UIButton(frame: CGRect(x: 10, y: 10, width: 50, height: 50))
                button.setImage(UIImage(named: "cancel.png"), for: .normal)
                button.backgroundColor = .clear
                button.addTarget(self, action: #selector(cancelCamera(_:)), for: .touchUpInside)
                return button
        }
        
        private func configureVisibleButton() -> UIButton {
                let button = UIButton(frame: CGRect(x: self.view.frame.size.width - 60, y: 10, width: 50, height: 50))
                button.setImage(UIImage(named: "visible-close.png"), for: .normal)
                button.backgroundColor = .clear
                button.addTarget(self, action: #selector(clickVisibleButton(_:)), for: .touchUpInside)
                return button
        }
        
        private func configureSwitchButton() -> UIButton {
                let button = UIButton(frame: CGRect(x: 70, y: 10, width: 50, height: 50))
                button.setImage(UIImage(named: "switch_camera.png"), for: .normal)
                button.backgroundColor = .clear
                button.addTarget(self, action: #selector(switchCamera(_:)), for: .touchUpInside)
                return button
        }
        
        // MARK: - Vision Request
        func requestCompletion(request : VNRequest, error : Error?) {
                guard error == nil else {
                        print(error!)
                        return
                }
                
                guard let results = request.results else {
                        print("no results")
                        return
                }
                
                DispatchQueue.main.async {
                        self.previewView.layer.sublayers?.removeSubrange(1...)
                }
                
                switch results.first {
                case is VNClassificationObservation:
                        processMLRequest(result: results.first as! VNClassificationObservation)
                case is VNFaceObservation:
                        processFaceRequest(results: results as! [VNFaceObservation])
                case is VNTextObservation:
                        processTextRequest(results: results as! [VNTextObservation])
                default: break
                }
        }
        
        func processMLRequest(result : VNClassificationObservation) {
                DispatchQueue.main.async {
                        if self.openVision {
                                self.identifyResult = "\(result.identifier) : \(Int(result.confidence * 100))%"
                        }
                }
        }
        
        func processFaceRequest(results : [VNFaceObservation]) {
                DispatchQueue.main.async {
                        for faceObservation in results {
                                let boundingBox = faceObservation.boundingBox
                                let height = self.previewView.frame.size.height * boundingBox.size.height
                                let rect = CGRect(x: boundingBox.origin.x * self.previewView.frame.size.width,
                                                  y: (1 - boundingBox.origin.y) * self.previewView.frame.size.height - height,
                                                  width: self.previewView.frame.size.width * boundingBox.size.width,
                                                  height: height)
                                
                                let layer = CALayer()
                                layer.frame = rect
                                layer.borderWidth = 3.0
                                layer.borderColor = UIColor.red.cgColor
                                self.previewView.layer.addSublayer(layer)
                        }
                }
        }
        
        func processTextRequest(results : [VNTextObservation]) {
                DispatchQueue.main.async {
                        for textObservation in results {
                                if let characters = textObservation.characterBoxes {
                                        for char in characters {
                                                let rect = CGRect(x: char.topLeft.x * self.previewView.frame.size.width,
                                                                  y: (1 - char.topLeft.y) * self.previewView.frame.size.height,
                                                                  width: (char.topRight.x - char.topLeft.x) * self.previewView.frame.size.width,
                                                                  height: (char.topRight.y - char.bottomRight.y) * self.previewView.frame.size.height)
                                                
                                                let layer = CALayer()
                                                layer.frame = rect
                                                layer.borderWidth = 3.0
                                                layer.borderColor = UIColor.red.cgColor
                                                self.previewView.layer.addSublayer(layer)
                                        }
                                }
                        }
                }
        }
        
        func updateRequests(_ vision : Bool) {
                if vision {
                        requests.append(contentsOf: [VisionModel.visionRequestType.mlRequest,
                                                                     VisionModel.visionRequestType.faceRequest,
                                                                     VisionModel.visionRequestType.textRequest])
                } else {
                        requests = []
                }
        }
        
        // MARK: - Action
        func analyzeCameraCapture(sampleBuffer : CMSampleBuffer) {
                if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                        vnModel.performVisionRequests(requests: requests, on: pixelBuffer, completionHandler: self.requestCompletion)
                }
        }
        
        // MARK: Button
        @objc func cancelCamera(_ sender : UIButton) {
                dismiss(animated: true) {
                        
                }
        }
        
        @objc func switchCamera(_ sender : UIButton) {
                caModel.switchCamera()
        }
        
        @objc func clickVisibleButton(_ sender : UIButton) {
                openVision = !openVision
        }
        
        // MARK: - CameraModelDelegate
        func cameraModelDidReceiveOutput(cameraModel: CameraModel, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
                analyzeCameraCapture(sampleBuffer: sampleBuffer)
        }
}
