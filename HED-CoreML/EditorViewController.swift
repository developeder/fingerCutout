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
    var edgeImage: UIImage?
    var marker: UIView?
    private var edittedMask: UIImage? {
        didSet {
            updateMask()
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = image
        edittedMask = edgeImage
        setupGuesters()
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
        if point.x < 0.0 || point.x > imageView.frame.width || point.y < 0.0 || point.y > imageView.frame.height {return}
        let ar = image!.size.width/imageView.bounds.size.width
        let startDate = Date()
        edittedMask = pbk_imageByReplacingColorAt(Int(point.x * ar), Int(point.y * ar), withColor: .clear, tolerance: 2000, antialias: true)
        let endDate = Date()
        print("scanline_replaceColor in \(endDate.timeIntervalSince(startDate))")
        
        updateMarker(center: sender.location(in: view))
    }
    
    func updateMarker(center: CGPoint) {
        if marker == nil {
            marker = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
            marker?.backgroundColor = UIColor.clear
            marker?.layer.borderColor = UIColor.red.cgColor
            marker?.layer.borderWidth = 3
            marker?.layer.cornerRadius = 30
            marker?.isUserInteractionEnabled = false
            view.addSubview(marker!)
            view.bringSubview(toFront: marker!)
        }
        
        marker?.center = center
    }
    
    @IBAction func resetButtonPressed(_ sender: Any) {
        edittedMask = edgeImage
        edgeImageBuffer = ImageBuffer(image: edgeImage!)
    }
    
    private func updateMask() {
        let maskImageView = UIImageView(frame: imageView.bounds)
        maskImageView.image = edittedMask
        imageView.mask = maskImageView
    }
    var imageBuffer: ImageBuffer?
    var edgeImageBuffer: ImageBuffer?
    
    func pbk_imageByReplacingColorAt(_ x: Int, _ y: Int, withColor: UIColor, tolerance: Int, antialias: Bool = false) -> UIImage {
        if imageBuffer == nil {
            imageBuffer = ImageBuffer(image: image!)
        }
        if edgeImageBuffer == nil {
            edgeImageBuffer = ImageBuffer(image: edgeImage!)
        }
        let point = (x, y)
        let index = edgeImageBuffer!.indexFrom(x, y)
        let pixel = edgeImageBuffer![index]
        let replacementPixel = Pixel(color: withColor)
        edgeImageBuffer!.scanline_replaceColor(pixel, startingAtPoint: point, withColor: replacementPixel, tolerance: tolerance, antialias: antialias, sourceImageBuffer: imageBuffer!, radius: 35)
        //        return image!

        let imageR = edgeImageBuffer!.image// UIImage(cgImage: edgeImageBuffer!.image, scale: image!.scale, orientation: UIImageOrientation.up)
        return imageR!
    }
}
