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
                "float xDist = abs(x - (point.x*width));" +
                "float yDist = abs(y - (point.y*height));" +
                "float dist = sqrt((xDist * xDist) + (yDist * yDist));" +
                "if (dist > radius) {" +
                "   return premultiply(pixelValue);" +
                "}" +
                "if (dist < radius/2.0) {" +
                "   return premultiply(vec4(pixelValue.rgb, 0.0));" +
                "}" +
                "float r = abs(unpremultColor.r - pixelValue.r) * 255.0;" +
                "float rSquare = r*r;" +
                "float g = abs(unpremultColor.g - pixelValue.g) * 255.0;" +
                "float gSquare = g*g;" +
                "float b = abs(unpremultColor.b - pixelValue.b) * 255.0;" +
                "float bSquare = b*b;" +
                "float diff = (rSquare + gSquare + bSquare);" +
                "float outA = diff/tolerance * pixelValue.a;" + // tolerance
                "outA = outA < 0.4 ? 0.0 : outA;" +
                "outA = outA > 1.0 ? 1.0 : outA;" +
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
