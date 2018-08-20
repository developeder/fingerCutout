//
//  UIImage+PaintBucket.swift
//  PaintBucket
//
//  Created by Jack Flintermann on 3/13/16.
//  Copyright © 2016 jflinter. All rights reserved.
//

import UIKit

public extension UIImage {
    
    func pixelData() -> [UInt8]? {
        let size = self.size
        let dataSize = size.width * size.height * 4
        var pixelData = [UInt8](repeating: 0, count: Int(dataSize))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: &pixelData,
                                width: Int(size.width),
                                height: Int(size.height),
                                bitsPerComponent: 8,
                                bytesPerRow: 4 * Int(size.width),
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        guard let cgImage = self.cgImage else { return nil }
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        return pixelData
    }
    
    //    @objc public func pbk_imageByReplacingColorAt(_ x: Int, _ y: Int, withColor: UIColor, tolerance: Int, antialias: Bool = false, sourceImage: UIImage) -> UIImage {
    //        let point = (x, y)
    //        let imageBuffer = ImageBuffer(image: self.cgImage!)
//        let index = imageBuffer.indexFrom(x, y)
//        let pixel = imageBuffer[index]
//        let replacementPixel = Pixel(color: withColor)
//        imageBuffer.scanline_replaceColor(pixel, startingAtPoint: point, withColor: replacementPixel, tolerance: tolerance, antialias: antialias, radius: 50)
////        let imageSource = UIImage(cgImage: edgesImageBuffer.image, scale: self.scale, orientation: UIImageOrientation.up)
////        let edgesImage = UIImage(cgImage: imageBuffer.image, scale: self.scale, orientation: UIImageOrientation.up)
////
//        return UIImage(cgImage: imageBuffer.image, scale: self.scale, orientation: UIImageOrientation.up)
//    }
    
}
