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
    var color: CIColor?
    
    override init()
    {
        super.init()
        
        edgeDetectionKernel =  CIKernel(source:
            "kernel vec4 colorOverlayFilter(sampler image, __color color, float tolerance, float x, float y, float width, float height, float radius)" +
                "{" +
                "vec2 point = samplerCoord(image);" +
                "vec4 pixelValue = unpremultiply(sample(image, point));" +
                "vec4 unpremultColor = unpremultiply(color);" +
                "float dist = sqrt(pow(x - (point.x*width), 2.0) + pow(y - (point.y*height), 2.0));" +
                "if (dist > radius) {" +
                "   return premultiply(pixelValue);" +
                "}" +
                "float r = pow((unpremultColor.r - pixelValue.r) * 255.0, 2.0);" +
                "float g = pow((unpremultColor.g - pixelValue.g) * 255.0, 2.0);" +
                "float b = pow((unpremultColor.b - pixelValue.b) * 255.0, 2.0);" +
                "float diff = (r + g + b);" +
                "float x = dist/radius;" +
                "float distVal = x < 0.5 ? 2.0 * x * x : x * (4.0 - 2.0 * x) - 1.0;" + //easeInOutQuad
                "float outA = (diff/tolerance) * 0.9 + distVal * 0.1;" +
                "outA = outA < 0.3 || dist < radius/2.0 || (dist < (radius/3.0)*2.0 && outA < 0.6) ? 0.0 : outA;" +
                "outA = outA > 1.0 ? 1.0 : outA;" +
                "outA = outA * pixelValue.a;" +
                "vec4 outRgba = vec4(pixelValue.rgb, outA);" +
                "return premultiply(outRgba);" +
            "}"
        )
    }
    
    
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    var edgeDetectionKernel: CIKernel?
    
    override var outputImage: CIImage!
    {
        guard let image = inputImage,
            let kernel = self.edgeDetectionKernel,
            let color = color else
        {
            return nil
        }
        
        let extent = image.extent
        let arguments = [image, color, 4500.0, center.x, center.y, extent.size.width, extent.size.height, radius] as [Any]
        return kernel.apply(extent: extent, roiCallback: {(index, rect) in
            return rect//CGRect(x: max(0, self.center.x - self.radius), y: max(0, self.center.y - self.radius), width: self.radius*2, height: self.radius*2)
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
}
