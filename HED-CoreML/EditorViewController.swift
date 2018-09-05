//
//  EditorViewController.swift
//  HED-CoreML
//
//  Created by eder yifrach on 15/08/2018.
//  Copyright © 2018 s1ddok. All rights reserved.
//

import UIKit
import Metal

class EditorViewController: UIViewController {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var slider: UISlider!
    @IBOutlet var sliderVal: UILabel!
    @IBOutlet var sizeSliderVal: UILabel!
    @IBOutlet var imageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var sizeSider: UISlider!
    @IBOutlet var resetButton: UIButton!
    
    var counter: Int = 0
    var buffer: MTLBuffer?
    var image: UIImage?
    var marker: UIView?
    var glkImage: MetalImageView?
    var eaglContext: EAGLContext?
    var magicImage: CIImage?
    var didAppear = false
    var imageData = [[UIColor]]()
    var colors = [UIColor]()
    var reversY = true
    private var edittedMask: CIImage?
    private var sourceImage: CIImage?
    var lastPoint: CGPoint?
    
    func getImageUnsafePointer(image: UIImage) -> UnsafeRawPointer? {
        let data = UIImagePNGRepresentation(image) as NSData?
        let ptr: UnsafeRawPointer? = data?.bytes
        return ptr
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let image = self.image,
            let cgImage = image.cgImage else {
                return
        }
        imageView.image = OpenCVWrapper.generateSuperPixels(image);

        edittedMask = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: "CIMakeVaribleBlur")
        filter?.setValue(edittedMask, forKeyPath: kCIInputImageKey)
        //        let filterColorControls = CIFilter(name: "CIColorControls")
        //        filterColorControls?.setValue(edittedMask, forKey: kCIInputImageKey)
        //        filterColorControls?.setValue(1.25, forKey: kCIInputContrastKey)
        //        sourceImage = filterColorControls?.outputImage
        sourceImage = CIImage(cgImage: cgImage)
        
        let ar = image.size.height/image.size.width
        imageViewHeightConstraint.constant = UIApplication.shared.keyWindow!.frame.width * ar
        eaglContext = EAGLContext(api: .openGLES3)
        self.sliderVal.text = "\(slider.value)"
        self.sizeSliderVal.text = "\(sizeSider.value)"
        
        let navItem = UIBarButtonItem(customView: resetButton)
        self.navigationItem.rightBarButtonItem = navItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !didAppear {
            glkImage = MetalImageView(frame: imageView.frame, device: nil)//OpenGLImageView(frame: imageView.frame)
            glkImage!.clipsToBounds = false
            glkImage!.layer.masksToBounds = false
            glkImage!.contentMode = .center
            glkImage!.image = edittedMask
            self.view.addSubview(glkImage!)
            self.view.sendSubview(toBack: glkImage!)
            setupGuesters()
            didAppear = true
            self.view.isUserInteractionEnabled = false
            DispatchQueue.global().async {
                let date = Date()
                print("started createImageData")
                self.createImageData()
                let date1 = Date()
                print("finish createImageData \(date1.timeIntervalSince1970 - date.timeIntervalSince1970)")
                DispatchQueue.main.async {
                    self.view.isUserInteractionEnabled = true
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func createImageData() {
        guard let image = image else {return}
        imageData = image.getImageData()
    }
    
    func setupGuesters() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTap(sender:)))
        imageView.addGestureRecognizer(gesture)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(didPan(sender:)))
        imageView.addGestureRecognizer(pan)
        imageView.isUserInteractionEnabled = true
    }
    
    @objc func didPan(sender: UIGestureRecognizer) {
        let point = sender.location(in: imageView)
        
        if lastPoint == nil {
            erase(at: point)
        } else {
            var vector = CGPoint(x: point.x - lastPoint!.x, y: point.y - lastPoint!.y)
            let distance = hypot(vector.x, vector.y)
            vector.x /= distance
            vector.y /= distance
            
            for i in stride(from: 0, to: Int(distance), by: 4) {
                let p = CGPoint(x: lastPoint!.x + CGFloat(i) * vector.x, y: lastPoint!.y + CGFloat(i) * vector.y)
                erase(at: p)
            }
        }
        updateMetalView()
        
        lastPoint = point
        
        
        if sender.state == .ended || sender.state == .cancelled {
            lastPoint = nil
            colors = [UIColor]()
            let imageTemp = convert(ciImage: edittedMask!)
            self.edittedMask = CIImage(cgImage: imageTemp!.cgImage!)
            reversY = true
        }
    }
    
    @objc func didTap(sender: UIGestureRecognizer) {
        colors = [UIColor]()
        let point = sender.location(in: imageView)
        erase(at: point)
        updateMetalView()
        
        let imageTemp = convert(ciImage: edittedMask!)
        self.edittedMask = CIImage(cgImage: imageTemp!.cgImage!)
        reversY = true
    }
    
    func erase(at point: CGPoint) {
        let date = Date()
        let y = reversY ? point.y : imageView.frame.height - point.y
        reversY = false
        let ciPoint = CGPoint(x: point.x, y: y)
        if point.x < 0.0 || point.x > imageView.frame.width || point.y < 0.0 || point.y > imageView.frame.height {return}
        let ar = image!.size.width/imageView.bounds.size.width
        let rPoint = CGPoint(x: point.x * ar, y: point.y * ar)
        let rciPoint = CGPoint(x: ciPoint.x * ar, y: ciPoint.y * ar)
        
        guard let editted = edittedMask,
            let source = image
            else {return}
        
        if rPoint.x < 0
            || rPoint.y < 0
            || rPoint.x > source.size.width - 1
            || rPoint.x > source.size.width - 1 {
            return
        }
        let filter = EdgeDetectionFilter()
        filter.inputImage = editted
        filter.sourceImage = sourceImage
        filter.magicMask = magicImage
        filter.center = rciPoint
        let radius = CGFloat(sizeSider.value) * (editted.extent.height/glkImage!.frame.height)
        filter.radius = radius
        filter.tolerance = slider.value
        let color = imageData[Int(rPoint.x)][Int(rPoint.y)]
        self.colors.append(color)
        while self.colors.count > 4 {
            self.colors.remove(at: 0)
        }
        filter.prevColors = colors
        
        guard let imageOut = filter.outputImage else {return}
        self.edittedMask = imageOut
        let date1 = Date()
        print("erase in \(date1.timeIntervalSince1970 - date.timeIntervalSince1970)")
    }
    
    func updateMetalView() {
        //        let filter = CIFilter(name: "CIGaussianBlur")
        //        filter?.setValue(self.edittedMask, forKeyPath: kCIInputImageKey)
        //        filter?.setValue(3.0, forKeyPath: kCIInputRadiusKey)
        self.glkImage?.image = self.edittedMask//filter?.outputImage
        self.glkImage?.setNeedsDisplay()
        let date = Date()
        guard let buffer = self.glkImage?.ciContext.rsq_render(toIntermediateImage: self.edittedMask) else {return}
        self.edittedMask = CIImage(cvPixelBuffer: buffer)
        self.reversY = true
        let date1 = Date()
        print("updateMetalView in \(date1.timeIntervalSince1970 - date.timeIntervalSince1970)")
    }
    
    var isConverting = false
    func createIntermediate(image: CIImage) {
        DispatchQueue.global().async {
            guard let buffer = self.glkImage?.ciContext.rsq_render(toIntermediateImage: self.edittedMask) else {return}
            self.edittedMask = CIImage(cvPixelBuffer: buffer)
            self.reversY = true
        }
    }
    
    func convert(ciImage: CIImage) -> UIImage? {
        let context =  CIContext(options: [kCIContextWorkingFormat: kCIFormatRGBAh])
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let imageRef = context.createCGImage(ciImage, from: ciImage.extent, format: kCIFormatRGBA8, colorSpace: colorSpace)
        var outputImage: UIImage? = nil
        if let aRef = imageRef {
            outputImage = UIImage(cgImage: aRef)
        }
        return outputImage
    }
    
    @IBAction func didSlide(_ slider: UISlider) {
        if slider == self.slider {
            self.sliderVal.text = "\(slider.value)"
        } else if slider == self.sizeSider {
            self.sizeSliderVal.text = "\(slider.value)"
        }
    }
    
    func updateMarker(center: CGPoint) {
        if marker == nil {
            let r:CGFloat = 375/(image?.size.width ?? 500)
            marker = UIView(frame: CGRect(x: 0, y: 0, width: 56*r, height: 56*r))
            marker?.backgroundColor = UIColor.clear
            marker?.layer.borderColor = UIColor.red.cgColor
            marker?.layer.borderWidth = 3
            marker?.layer.cornerRadius = 28*r
            marker?.isUserInteractionEnabled = false
            view.addSubview(marker!)
            view.bringSubview(toFront: marker!)
        }
        marker?.center = center
    }
    
    @IBAction func resetButtonPressed(_ sender: Any) {
        edittedMask = CIImage(cgImage: image!.cgImage!)
        glkImage?.image = edittedMask
        glkImage?.setNeedsDisplay()
    }
}

extension CIContext {
    func rsq_render(toIntermediateImage image: CIImage?) -> CVPixelBuffer? {
        let size: CGSize? = image?.extent.size
        var pixelBuffer: CVPixelBuffer? = nil
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(size!.width), Int(size!.height), kCVPixelFormatType_32ARGB, [kCVPixelBufferIOSurfacePropertiesKey as String: [:]] as CFDictionary?, &pixelBuffer)
        
        if status == kCVReturnSuccess {
            if let anImage = image, let aBuffer = pixelBuffer {
                render(anImage, to: aBuffer)
            }
        }
        return pixelBuffer
    }
}
