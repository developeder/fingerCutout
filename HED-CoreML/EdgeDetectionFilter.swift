//
//  EdgeDetectionFilter.swift
//  HED-CoreML
//
//  Created by eder yifrach on 22/08/2018.
//  Copyright © 2018 s1ddok. All rights reserved.
//

import Foundation
import UIKit

@objc class EdgeDetectionFilter: CIFilter {
    @objc var inputImage : CIImage?
    @objc var center: CGPoint = CGPoint.zero
    var radius: CGFloat = 15
    var prevColors = [UIColor]()
    var sourceImage: CIImage?
    var magicMask: CIImage?
    var tolerance: Float = 4000
    
    private var color: CIColor?
    private var color1: CIColor?
    private var color2: CIColor?
    private var color3: CIColor?
    
    override init()
    {
        super.init()
        let url = Bundle.main.url(forResource: "default", withExtension: "metallib")!
        let data = try! Data(contentsOf: url)
        edgeDetectionKernel = try! CIKernel(functionName: "edgeDetection", fromMetalLibraryData: data)
    }
    
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    var edgeDetectionKernel: CIKernel?
    
    override var outputImage: CIImage!
    {
        guard let image = inputImage,
            let mask = magicMask,
            let kernel = self.edgeDetectionKernel,
            let source = sourceImage
            else
        {
            return nil
        }
        
        let colorsCount = prevColors.count
        if colorsCount > 0 {
            color = CIColor(cgColor: prevColors[colorsCount-1].cgColor)
        } else { return nil }
        if colorsCount > 1 {
            color1 = CIColor(cgColor: prevColors[colorsCount-2].cgColor)
        }
        if colorsCount > 2 {
            color2 = CIColor(cgColor: prevColors[colorsCount-3].cgColor)
        }
        if colorsCount > 3 {
            color3 = CIColor(cgColor: prevColors[colorsCount-4].cgColor)
        }
        
        let extent = image.extent
        let arguments = [image,
                         source,
                         mask,
                         color!,
                         color1 ?? color!,
                         color2 ?? color!,
                         color3 ?? color!,
                         tolerance,
                         CIVector(cgPoint: center),
                         extent.size.width,
                         extent.size.height,
                         radius] as [Any]
        return kernel.apply(extent: extent, roiCallback: {(index, rect) in
            return rect
            } , arguments: arguments)
    }
}

extension UIImage {
    
    func getPixelColor(pos: CGPoint) -> UIColor {
        
        if let pixelData = self.cgImage?.dataProvider?.data {
            let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
            
            let pixelInfo: Int = ((Int(self.size.width) * Int(pos.y)) + Int(pos.x)) * 4
            
            let r = CGFloat(data[pixelInfo+0]) / CGFloat(255.0)
            let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
            let b = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
            let a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)
            let color = UIColor(red: r, green: g, blue: b, alpha: a)
            return color
        } else {
            //IF something is wrong I returned WHITE, but change as needed
            return UIColor.white
        }
    }
    
    func getImageData() -> [[UIColor]] {
        
        var imageData = [[UIColor]]()
        if let pixelData = self.cgImage?.dataProvider?.data {
            let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
            
            for x in 0..<Int(size.width) {
                var xRow = [UIColor]()
                for y in 0..<Int(size.height) {
                    let pixelInfo: Int = ((Int(self.size.width) * y) + x) * 4
                    let r = CGFloat(data[pixelInfo+0]) / CGFloat(255.0)
                    let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
                    let b = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
                    let a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)
                    let color = UIColor(red: r, green: g, blue: b, alpha: a)
                    xRow.append(color)
                }
                imageData.append(xRow)
            }
        }
        return imageData
    }
    
//    func getAlpha(pos: CGPoint) -> CGFloat {
//
//        if let pixelData = self.cgImage?.dataProvider?.data {
//            let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
//
//            let pixelInfo: Int = ((Int(self.size.width) * Int(pos.y)) + Int(pos.x)) * 4
//            let a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)
//            return a
//        } else {
//            return 0.0
//        }
//    }
}
//        edgeDetectionKernel =  CIKernel(source:
//            "kernel vec4 colorOverlayFilter(sampler image, __color color," +
//            "__color color1, __color color2, __color color3, __color color4, __color color5," +
//            "float tolerance, float x, float y, float width, float height, float radius)" +
//                "{" +
//                "vec2 point = samplerCoord(image);" +
//                "vec4 pixelValue = unpremultiply(sample(image, point));" +
//                "float dist = sqrt(pow(x - (point.x*width), 2.0) + pow(y - (point.y*height), 2.0));" +
//                "if (dist > radius) {" +
//                "   return premultiply(pixelValue);" +
//                "}" +
//                "float r = pow((color.r - pixelValue.r) * 255.0, 2.0);" +
//                "float g = pow((color.g - pixelValue.g) * 255.0, 2.0);" +
//                "float b = pow((color.b - pixelValue.b) * 255.0, 2.0);" +
//                "float diff = (r + g + b);" +
//
//                "float r1 = pow((color1.r - pixelValue.r) * 255.0, 2.0);" +
//                "float g1 = pow((color1.g - pixelValue.g) * 255.0, 2.0);" +
//                "float b1 = pow((color1.b - pixelValue.b) * 255.0, 2.0);" +
//                "float diff1 = (r1 + g1 + b1);" +
//
//                "float r2 = pow((color2.r - pixelValue.r) * 255.0, 2.0);" +
//                "float g2 = pow((color2.g - pixelValue.g) * 255.0, 2.0);" +
//                "float b2 = pow((color2.b - pixelValue.b) * 255.0, 2.0);" +
//                "float diff2 = (r2 + g2 + b2);" +
//
//                "float r3 = pow((color3.r - pixelValue.r) * 255.0, 2.0);" +
//                "float g3 = pow((color3.g - pixelValue.g) * 255.0, 2.0);" +
//                "float b3 = pow((color3.b - pixelValue.b) * 255.0, 2.0);" +
//                "float diff3 = (r3 + g3 + b3);" +
//
//                "float r4 = pow((color4.r - pixelValue.r) * 255.0, 2.0);" +
//                "float g4 = pow((color4.g - pixelValue.g) * 255.0, 2.0);" +
//                "float b4 = pow((color4.b - pixelValue.b) * 255.0, 2.0);" +
//                "float diff4 = (r4 + g4 + b4);" +
//
//                "float r5 = pow((color5.r - pixelValue.r) * 255.0, 2.0);" +
//                "float g5 = pow((color5.g - pixelValue.g) * 255.0, 2.0);" +
//                "float b5 = pow((color5.b - pixelValue.b) * 255.0, 2.0);" +
//                "float diff5 = (r5 + g5 + b5);" +
//
//                "float rdist = dist/radius;" +
//                "float distVal = rdist < 0.5 ? 2.0 * rdist * rdist : rdist * (4.0 - 2.0 * rdist) - 1.0;" + //
//                "float outA = (diff/tolerance) * 0.3" +
//                " + (diff1/tolerance) * 0.2" +
//                " + (diff2/tolerance) * 0.15" +
//                " + (diff3/tolerance) * 0.1" +
//                " + (diff4/tolerance) * 0.1" +
//                " + (diff5/tolerance) * 0.05" +
//                " + distVal * 0.1;" +
//                "outA = outA < 0.3 || dist < radius/2.0 || (dist < (radius/3.0)*2.0 && outA < 0.6) ? 0.0 : outA;" +
//                "outA = outA > 1.0 ? 1.0 : outA;" +
//                "outA = outA * pixelValue.a;" +
//                "vec4 outRgba = vec4(pixelValue.rgb, outA);" +
//                "return premultiply(outRgba);" +
//            "}"
//        )
