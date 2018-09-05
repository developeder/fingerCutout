//
//  ViewController.swift
//  CropTest
//
//  Created by eder yifrach on 12/07/2018.
//  Copyright © 2018 eder yifrach. All rights reserved.
//

import UIKit
import CoreML

let segueToAffectVC = "toAffectViewController"
let segueToEditorVC = "toEditorViewController"

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet var startButton: UIButton!
    @IBOutlet var openCVTitle: UILabel!
    
    let hedSO = HED_so()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupButton()
        self.openCVTitle.text = OpenCVWrapper.openCvVersionString()
    }
    
    func setupButton() {
        startButton.layer.cornerRadius = 100
        startButton.layer.borderColor = UIColor.gray.cgColor
        startButton.layer.borderWidth = 1.0
        startButton.layer.shadowColor = UIColor.white.cgColor
        startButton.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        startButton.layer.shadowRadius = 8.0
        startButton.layer.shadowOpacity = 0.5
    }
    
    // Mark: - actions
    @IBAction func stertButtonPressed(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        self.present(imagePicker, animated: true) {
            
        }
    }
    
    // MARK: - imagePickerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage]  as? UIImage {
//            let edgesImage = doInferencePressed(image)
            picker.dismiss(animated: true) {
                let map = ["image": image]//, "edgesImage": edgesImage]
                self.performSegue(withIdentifier: segueToEditorVC, sender: map)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == segueToAffectVC) {
            let vc = segue.destination as! AffectViewController
            vc.choosenImage = (sender as! UIImage)
        } else if (segue.identifier == segueToEditorVC) {
            let vc = segue.destination as! EditorViewController
            let map = sender as! [String: UIImage]
            vc.image = map["image"]
            let mask = CIImage(cgImage: UIImage(named: "fitted_mask.png")!.cgImage!)
            vc.magicImage = mask
//            vc.edgeImage = map["edgesImage"]
        }
    }
    
    
    func doInferencePressed(_ inputImage: UIImage) -> UIImage {
        // Remember the time when we started
        let startDate = Date()
        
        // Convert our image to proper input format
        // In this case we need to feed pixel buffer which is 500x500 sized.
        let inputW = 500
        let inputH = 500
        guard let inputPixelBuffer = inputImage.resized(width: inputW, height: inputH)
            .pixelBuffer(width: inputW, height: inputH) else {
                fatalError("Couldn't create pixel buffer.")
        }
        
        // Use different models based on what output we need
        let featureProvider: MLFeatureProvider

            featureProvider = try! hedSO.prediction(data: inputPixelBuffer)
        
        // Retrieve results
        guard let outputFeatures = featureProvider.featureValue(for: "upscore-dsn3")?.multiArrayValue else {
            fatalError("Couldn't retrieve features")
        }
        
        // Calculate total buffer size by multiplying shape tensor's dimensions
        let bufferSize = outputFeatures.shape.lazy.map { $0.intValue }.reduce(1, { $0 * $1 })
        
        // Get data pointer to the buffer
        let dataPointer = UnsafeMutableBufferPointer(start: outputFeatures.dataPointer.assumingMemoryBound(to: Double.self),
                                                     count: bufferSize)
        
        // Prepare buffer for single-channel image result
        var imgData = [UInt8](repeating: 0, count: bufferSize)
        
        // Normalize result features by applying sigmoid to every pixel and convert to UInt8
        for i in 0..<inputW {
            for j in 0..<inputH {
                let idx = i * inputW + j
                let value = dataPointer[idx]
                
                let sigmoid = { (input: Double) -> Double in
                    return 1 / (1 + exp(-input))
                }
                
                let result = sigmoid(value)
                imgData[idx] = UInt8(result * 255)
            }
        }
        
        // Create single chanel gray-scale image out of our freshly-created buffer
        let cfbuffer = CFDataCreate(nil, &imgData, bufferSize)!
        let dataProvider = CGDataProvider(data: cfbuffer)!
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let cgImage = CGImage(width: inputW, height: inputH, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: inputW, space: colorSpace, bitmapInfo: [], provider: dataProvider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
        let resultImage = UIImage(cgImage: cgImage!)
        
        // Calculate the time of inference
        let endDate = Date()
        print("Inference is finished in \(endDate.timeIntervalSince(startDate)) for model: \("upscore-dsn3")")
        return resultImage
    }
}

