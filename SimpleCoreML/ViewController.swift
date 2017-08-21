//
//  ViewController.swift
//  SimpleCoreML
//
//  Created by 何家瑋 on 2017/7/12.
//  Copyright © 2017年 何家瑋. All rights reserved.
//

import UIKit
import Vision

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        
        @IBOutlet weak var resultLabel: UILabel!
        @IBOutlet weak var identifyImageView: UIImageView!
        
        let mlModel = CoreMLModel.sharedModel()
        var analyzeResult : String {
                set {
                        resultLabel.text = newValue
                }
                get {
                        return resultLabel.text!
                }
        }
        
        override func viewDidLoad() {
                super.viewDidLoad()
                analyzeResult = "choose an image..."
                identifyImageView.contentMode = .scaleAspectFit
        }
        
        override func didReceiveMemoryWarning() {
                super.didReceiveMemoryWarning()
                // Dispose of any resources that can be recreated.
        }
        
        // MARK: - Button Action
        @IBAction func camera(_ sender: Any) {
                if !UIImagePickerController.isSourceTypeAvailable(.camera) {
                        return
                }
                
                let cameraController = UIImagePickerController()
                cameraController.delegate = self
                cameraController.sourceType = .camera
                cameraController.allowsEditing = false
                
                present(cameraController, animated: true) {
                        
                }
        }
        
        @IBAction func library(_ sender: Any) {
                let photoPickerController = UIImagePickerController()
                photoPickerController.delegate = self
                photoPickerController.sourceType = .photoLibrary
                photoPickerController.allowsEditing = false
                
                present(photoPickerController, animated: true) {
                        
                }
        }
        
        @IBAction func realTimeCamera(_ sender: Any) {
                let cameraVC = CameraViewController()
                present(cameraVC, animated: true) {

                }
        }
        
        // MARK: - UIImagePickerControllerDelegate
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                dismiss(animated: true) {
                        
                }
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
                dismiss(animated: true, completion: nil)
                guard let image = info["UIImagePickerControllerOriginalImage"] as? UIImage else { return }
                
                identifyImageView.image = image
                if let pixelBuffer = imageProcess.cgImageToPixelBuffer(image.cgImage!) {
                        analyzeResult = mlModel.prediction(pixelBuffer: pixelBuffer) ?? "Not Identify"
                }
        }
}

