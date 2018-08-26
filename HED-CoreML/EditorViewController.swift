//
//  EditorViewController.swift
//  HED-CoreML
//
//  Created by eder yifrach on 15/08/2018.
//  Copyright © 2018 s1ddok. All rights reserved.
//

import UIKit

class EditorViewController: UIViewController {

    @IBOutlet var imageView: UIImageView!
    var image: UIImage?
//    var edgeImage: UIImage?
    var marker: UIView?
    var imageBuffer: ImageBuffer?
    var glkImage: OpenGLImageView?
    var eaglContext: EAGLContext?
//    var edgeImageBuffer: ImageBuffer?
    @IBOutlet var imageViewHeightConstraint: NSLayoutConstraint!
    private var edittedMask: CIImage? {
        didSet {
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
//        imageView.image = image
        edittedMask = CIImage(image: image!)
        
        let ar = image!.size.height/image!.size.width
        imageViewHeightConstraint.constant = UIApplication.shared.keyWindow!.frame.width * ar
        
        if imageBuffer == nil {
            imageBuffer = ImageBuffer(image: image!)
        }
//        if edgeImageBuffer == nil {
//            edgeImageBuffer = ImageBuffer(image: edgeImage!)
//        }
        
    }
    var didAppear = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !didAppear {
            eaglContext = EAGLContext(api: .openGLES3)
            
            glkImage = OpenGLImageView(frame: imageView.frame, context: eaglContext!)
            
            glkImage!.clipsToBounds = false
            glkImage!.layer.masksToBounds = false
            glkImage!.contentMode = .center
            glkImage!.image = edittedMask
            //        glkImage?.backgroundColor = UIColor.yellow
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
        let pan = UIPanGestureRecognizer(target: self, action: #selector(didTap(sender:)))
        imageView.addGestureRecognizer(pan)
        imageView.isUserInteractionEnabled = true

    }
    
    @objc func didTap(sender: UIGestureRecognizer) {
        let point = sender.location(in: imageView)
        let ciPoint = CGPoint(x: point.x, y: imageView.frame.height - point.y)
        if point.x < 0.0 || point.x > imageView.frame.width || point.y < 0.0 || point.y > imageView.frame.height {return}
        let ar = image!.size.width/imageView.bounds.size.width
//        let startDate = Date()
        let rPoint = CGPoint(x: point.x * ar, y: point.y * ar)
        let rciPoint = CGPoint(x: ciPoint.x * ar, y: ciPoint.y * ar)
        guard let editted = edittedMask else {return}

        let filter = EdgeDetectionFilter()
        filter.inputImage = editted
        filter.center = rciPoint
        filter.radius = 40 * (editted.extent.height/glkImage!.frame.height)
        filter.color = CIColor(cgColor: image!.getPixelColor(pos: rPoint).cgColor)
        
        let imageOut = filter.outputImage
        glkImage?.image = imageOut
        imageView.image = nil
        edittedMask = imageOut
//        if let uiImage = convert(ciImage: imageOut!) {
//            edittedMask = editted
//            imageView.image = uiImage
//        }
        
        return;
//        edittedMask = pbk_imageByReplacingColorAt(Int(point.x * ar), Int(point.y * ar), withColor: .clear, tolerance: 2000, antialias: true)
//        let endDate = Date()
//        print("scanline_replaceColor in \(endDate.timeIntervalSince(startDate))")
//
//        updateMarker(center: sender.location(in: view))
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
    
    func updateMarker(center: CGPoint) {
        if marker == nil {
            let r:CGFloat = 375/500
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
//        edittedMask = edgeImage
//        edgeImageBuffer = ImageBuffer(image: edgeImage!)
        edittedMask = CIImage(image: image!)
        glkImage?.image = edittedMask
//        imageBuffer = ImageBuffer(image: image!)
    }
    
//    private func updateMask() {
//        let maskImageView = UIImageView(frame: imageView.bounds)
//        maskImageView.image = edittedMask
//        imageView.mask = maskImageView
//    }
    
    func pbk_imageByReplacingColorAt(_ x: Int, _ y: Int, withColor: UIColor, tolerance: Int, antialias: Bool = false) -> UIImage {
        if imageBuffer == nil {
            imageBuffer = ImageBuffer(image: image!)
        }

        let point = (x, y)
        let index = imageBuffer!.indexFrom(x, y)
        let pixel = imageBuffer![index]
        let replacementPixel = Pixel(color: withColor)
        imageBuffer!.scanline_replaceColor(pixel, startingAtPoint: point, withColor: replacementPixel, tolerance: tolerance, antialias: antialias, radius: 28)
        //        return image!

        let imageR = imageBuffer!.image// UIImage(cgImage: edgeImageBuffer!.image, scale: image!.scale, orientation: UIImageOrientation.up)
        return imageR!
    }
    
}
