//
//  CameraModel.swift
//  SimpleCoreML
//
//  Created by 何家瑋 on 2017/7/22.
//  Copyright © 2017年 何家瑋. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

@objc protocol CameraModelDelegate {
        @objc optional func cameraModelDidReceiveOutput(cameraModel: CameraModel, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)
}

class CameraModel : NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        
        var delegate : CameraModelDelegate?
        var captureSession = AVCaptureSession()
        var previewLayer = AVCaptureVideoPreviewLayer()
        let queue = DispatchQueue(label: "SampleBufferDelegateQueue")
        
        // MARK: - public
        func checkCameraAuthorization(_ completionHandler :   @escaping (Bool) -> Void) {
                switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
                case .authorized:
                        setupCaptureSession()
                        completionHandler(true)
                case .denied, .restricted:
                        completionHandler(false)
                case .notDetermined:
                        requestAuthorization({ (result) in
                                if result {
                                        self.setupCaptureSession()
                                }
                                
                                completionHandler(result)
                        })
                }
        }
        
        func launchCamera() -> Void {
                captureSession.startRunning()
        }
        
        func closeCamera() -> Void {
                captureSession.stopRunning()
        }
        
        func switchCamera() -> Void {
                guard let device = chagneDevice() else {
                        return
                }
                
                guard let deviceInput = try? AVCaptureDeviceInput(device: device) else {
                        return
                }
                
                captureSession.beginConfiguration()
                
                let currentInput = captureSession.inputs.first
                captureSession.removeInput(currentInput!)

                if captureSession.canAddInput(deviceInput) {
                        captureSession.addInput(deviceInput)
                } else {
                        captureSession.addInput(currentInput!)
                }
                
                captureSession.commitConfiguration()
        }
        
        // MARK: - private
        private func requestAuthorization(_ completionHandler : @escaping (Bool) -> Void) {
                AVCaptureDevice.requestAccess(for: AVMediaType.video) { (result) in
                        completionHandler(result)
                }
        }
        
        // MARK: capture session
        private func setupCaptureSession() {
                guard let device = AVCaptureDevice.default(for: .video) else {
                        return
                }
                
                guard let deviceInput = try? AVCaptureDeviceInput(device: device) else {
                        return
                }
                
                guard captureSession.canAddInput(deviceInput) else {
                        return
                }
                
                let videoDataOutput = setupCaptureVideoDataOutput()
                guard captureSession.canAddOutput(videoDataOutput) else {
                        return
                }
                
                captureSession.beginConfiguration()
                captureSession.sessionPreset = .photo
                captureSession.addInput(deviceInput)
                captureSession.addOutput(videoDataOutput)
                captureSession.commitConfiguration()
        }
        
        private func setupCapturePhotoOutput() -> AVCapturePhotoOutput {
                let captureOutput = AVCapturePhotoOutput()
                
                captureOutput.isHighResolutionCaptureEnabled = true
                captureOutput.isLivePhotoCaptureEnabled = captureOutput.isLivePhotoCaptureSupported
                
                return captureOutput
        }
        
        private func setupCaptureVideoDataOutput() -> AVCaptureVideoDataOutput {
                let captureOutput = AVCaptureVideoDataOutput()
                
                let settings = [String(kCVPixelBufferPixelFormatTypeKey) : kCVPixelFormatType_32BGRA]
                captureOutput.videoSettings = settings
                captureOutput.setSampleBufferDelegate(self, queue: queue)
                
                return captureOutput
        }
        
        private func chagneDevice() -> AVCaptureDevice? {
                let newPosition : AVCaptureDevice.Position
                let newDeviceType : AVCaptureDevice.DeviceType
                
                guard let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput else {
                        return nil
                }
                
                let currentPosition = currentInput.device.position
                switch currentPosition {
                case .back:
                        newPosition = .front
                        newDeviceType = .builtInWideAngleCamera
                case .front, .unspecified:
                        newPosition = .back
                        newDeviceType = .builtInDualCamera
                }
                
                let discoverySession = AVCaptureDevice.DiscoverySession(__deviceTypes: [.builtInDualCamera, .builtInWideAngleCamera], mediaType: .video, position: newPosition)
                let devices = discoverySession.devices
                if let device = devices.first(where: { $0.deviceType == newDeviceType }) {
                        return device
                } else if let device = devices.first {
                        return device
                }
                
                return nil
        }
        
        // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
                delegate?.cameraModelDidReceiveOutput?(cameraModel: self, didOutput: sampleBuffer, from: connection)
        }
}
