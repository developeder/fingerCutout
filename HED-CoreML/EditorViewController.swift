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
    
    var buffer: MTLBuffer?
    var image: UIImage?
    var marker: UIView?
    var glkImage: MetalImageView?
    var eaglContext: EAGLContext?
    var magicImage: CIImage?
    var didAppear = false
    var colors = [UIColor]()
    var reversY = true
    private var edittedMask: CIImage? {
        didSet {
        }
    }
    
    func getImageUnsafePointer(image: UIImage) -> UnsafeRawPointer? {
        let data = UIImagePNGRepresentation(image) as NSData?
        let ptr: UnsafeRawPointer? = data?.bytes
        return ptr
    }
    
//    private func getAlphaChannel(image: CGImage) -> UnsafeRawPointer? {
//        let width = image.width
//        let height = image.height
//        var imageData = UInt8()
//        let strideLength = width + (width % 4)
//
//        let colorSpace = CGColorSpaceCreateDeviceGray()
//        let ctx1 = CGContext(data: imageData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width, space: colorSpace, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue).rawValue | 0)
//
//        var ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: strideLength, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue)
//
//
//        ctx.draw(in: image,  CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
//
//        let alphaData = UInt8() as? [UInt8]
//
//
//        func calloc(height: width?) {
//
//            calloc(1, *width*heightsizeof(unsignedchar)
//        }
//        return nil
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //        guard let device = MTLCreateSystemDefaultDevice(),
        guard let image = self.image,
            let cgImage = image.cgImage else {
                return
        }
//        let length = image.size.width * image.size.height
        
//        buffer = device.makeBuffer(bytes: getImageUnsafePointer(image: image)!, length: Int(length), options: MTLResourceOptions.storageModeShared)
        edittedMask = CIImage(cgImage: cgImage)

        let ar = image.size.height/image.size.width
        imageViewHeightConstraint.constant = UIApplication.shared.keyWindow!.frame.width * ar
        eaglContext = EAGLContext(api: .openGLES3)
        self.sliderVal.text = "\(slider.value)"
        
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
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        let velocityPoint = (sender as! UIPanGestureRecognizer).velocity(in: imageView)
        let velocity = sqrt(pow(velocityPoint.x, 2.0) + pow(velocityPoint.y, 2.0)) / sqrt(pow(imageView.frame.width, 2.0) + pow(imageView.frame.height, 2.0))
        erase(at: point, velocity: velocity)
        if sender.state == .ended || sender.state == .cancelled {
            colors = [UIColor]()
            let imageTemp = convert(ciImage: edittedMask!)
            self.edittedMask = CIImage(cgImage: imageTemp!.cgImage!)
            reversY = true
        }
    }
    
    @objc func didTap(sender: UIGestureRecognizer) {
        colors = [UIColor]()
        let point = sender.location(in: imageView)
        erase(at: point, velocity: 0.0)
        let imageTemp = convert(ciImage: edittedMask!)
        self.edittedMask = CIImage(cgImage: imageTemp!.cgImage!)
        reversY = true
    }
    
    func getLastEdited() -> CIImage? {
        
//        if let texture = self.glkImage?.copyTexture,
//            let image = CIImage(mtlTexture: texture, options: nil) {
//            return image
//        }
        return edittedMask
    }
    
    func erase(at point: CGPoint, velocity: CGFloat) {
        let date = Date()
        reversY = true
        let y = reversY ? point.y : imageView.frame.height - point.y
        reversY = false
        let ciPoint = CGPoint(x: point.x, y: y)
        if point.x < 0.0 || point.x > imageView.frame.width || point.y < 0.0 || point.y > imageView.frame.height {return}
        let ar = image!.size.width/imageView.bounds.size.width
        let rPoint = CGPoint(x: point.x * ar, y: point.y * ar)
        let rciPoint = CGPoint(x: ciPoint.x * ar, y: ciPoint.y * ar)
        
        guard let editted = edittedMask else {return}
        
        let filter = EdgeDetectionFilter()
        filter.inputImage = editted//CIImage(cgImage: image!.cgImage!)
        filter.center = rciPoint
        let radius = CGFloat(sizeSider.value) * (editted.extent.height/glkImage!.frame.height)
        filter.radius = radius
        filter.magicMask = magicImage
        filter.tolerance = slider.value
        filter.velocity = velocity*0.5
        colors.append(image!.getPixelColor(pos: rPoint))
        filter.color = CIColor(cgColor: colors[colors.count-1].cgColor)
        if colors.count > 1 {
            filter.color1 = CIColor(cgColor: colors[colors.count-2].cgColor)
        }
        if colors.count > 2 {
            filter.color2 = CIColor(cgColor: colors[colors.count-3].cgColor)
        }
        if colors.count > 3 {
            filter.color3 = CIColor(cgColor: colors[colors.count-4].cgColor)
        }
        
        while colors.count > 4 {
            colors.remove(at: 0)
        }
        
        let imageOut = filter.outputImage//.cropped(to: CGRect(x: point.x - radius, y: imageView.frame.height - point.y - radius, width: 2 * radius, height: 2 * radius))
        
        glkImage?.image = imageOut
        glkImage?.setNeedsDisplay()
        edittedMask = imageOut
        let date1 = Date()
        guard let buffer = glkImage?.ciContext.rsq_render(toIntermediateImage: imageOut) else {return}
        let date2 = Date()
        print("created CVPixelBuffer in \(date2.timeIntervalSince1970 - date1.timeIntervalSince1970)")
        edittedMask = CIImage(cvPixelBuffer: buffer)
        let date3 = Date()
        print("erase finished in \(date3.timeIntervalSince1970 - date.timeIntervalSince1970)")

        return
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
//        imageView.image = image
    }
}

extension CIContext {
    func rsq_render(toIntermediateImage image: CIImage?) -> CVPixelBuffer? {
//        var intermediateImage: CIImage? = nil
        let size: CGSize? = image?.extent.size
        var pixelBuffer: CVPixelBuffer? = nil
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(size!.width), Int(size!.height), kCVPixelFormatType_32ARGB, [kCVPixelBufferIOSurfacePropertiesKey as String: [:]] as CFDictionary?, &pixelBuffer)
        
        if status == kCVReturnSuccess {
            if let anImage = image, let aBuffer = pixelBuffer {
                render(anImage, to: aBuffer)
            }
//            if let aBuffer = pixelBuffer {
//                intermediateImage = CIImage(cvPixelBuffer: aBuffer)
//            }
        }

            return pixelBuffer
//        return intermediateImage
    }

}
