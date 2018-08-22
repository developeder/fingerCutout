//
//  ImageBuffer.swift
//  PaintBucket
//
//  Created by Jack Flintermann on 3/15/16.
//  Copyright © 2016 jflinter. All rights reserved.
//

//import CoreGraphics
import Foundation
import UIKit

class ImageBuffer {
    let imageWidth: Int
    let imageHeight: Int
    
    private var bitmap: [Pixel]?
    
    init(image: UIImage) {
        self.imageWidth = Int(image.size.width)
        self.imageHeight = Int(image.size.height)
        let bytesArr = image.pixelData()
        var pixelsArray = [Pixel]()
        var pixelArray = [UInt8]()
        for byte in bytesArr ?? [] {
            pixelArray.append(byte)
            if pixelArray.count == 4 {
                let pixel = Pixel(pixelArray[0], pixelArray[2], pixelArray[1], pixelArray[3])
                pixelsArray.append(pixel)
                pixelArray = [UInt8]()
            }
        }
        self.bitmap = pixelsArray
    }
    
    func indexFrom(_ x: Int, _ y: Int) -> Int {
        return x + (self.imageWidth * y)
    }
    
    func differenceAtPoint(_ x: Int, _ y: Int, toPixel pixel: Pixel) -> Int {
        let index = indexFrom(x, y)
        let newPixel = self[index]
        return pixel.diff(newPixel)
    }
    
    func differenceAtIndex(_ index: Int, toPixel pixel: Pixel) -> Int {
        let newPixel = self[index]
        return pixel.diff(newPixel)
    }
    
//    func previousColorDiff(pixel: Pixel) -> CGFloat {
//        struct Holder {
//            static var average: Pixel?
//            static var counter: Int = 1
//        }
//        if Holder.average == nil {
//            Holder.average = Pixel(pixel.data.r, pixel.data.g, pixel.data.b, pixel.data.a)
//            return 0.0
//        }
//
//        let diff = pixel.diff(Holder.average!)
//        let a = (Int(Holder.average!.data.a) * Holder.counter + Int(pixel.data.a)) / (Holder.counter + 1)
//        let r = (Int(Holder.average!.data.r) * Holder.counter + Int(pixel.data.r)) / (Holder.counter + 1)
//        let g = (Int(Holder.average!.data.g) * Holder.counter + Int(pixel.data.g)) / (Holder.counter + 1)
//        let b = (Int(Holder.average!.data.b) * Holder.counter + Int(pixel.data.b)) / (Holder.counter + 1)
//        Holder.average = Pixel(UInt8(r), UInt8(g), UInt8(b), UInt8(a))
//        Holder.counter += 1
//        return CGFloat(diff)
//    }
    
    func scanline_replaceColor(_ colorPixel: Pixel, startingAtPoint startingPoint: (Int, Int), withColor replacementPixel: Pixel, tolerance: Int, antialias: Bool/*, sourceImageBuffer: ImageBuffer*/, radius: Int) {

        func testPixelAtPoint(_ x: Int, _ y: Int) -> Bool {
            return differenceAtPoint(x, y, toPixel: colorPixel) <= tolerance
        }
        
//        let sourceIndex = sourceImageBuffer.indexFrom(startingPoint.0, startingPoint.1)
//        let sourceColorPixel = sourceImageBuffer[sourceIndex]
        
        
        let startPoint = CGPoint(x: startingPoint.0, y: startingPoint.1)
        let seenIndices = NSMutableIndexSet()
        let indices = NSMutableIndexSet(index: indexFrom(startingPoint.0, startingPoint.1))
        
        let startDate = Date()
        var counter = 0
        var innerWhile = 0
        var innerFor = 0
        
        while indices.count > 0 {
            counter += 1
            let index = indices.firstIndex
            indices.remove(index)
            
            if seenIndices.contains(index) {
                continue
            }
            seenIndices.add(index)
            
            let pointX = index % imageWidth
            let y = index / imageWidth
            var minX = pointX
            var maxX = pointX + 1
            
            if differenceAtIndex(index, toPixel: colorPixel) > tolerance && startPoint.distance(from: CGPoint(x: pointX, y: y)) >= radius/2 {
                continue
            }
            
            func renderPixel(x: Int, y: Int) -> Bool {
                counter += 1
                seenIndices.add(indexFrom(x, y))
                // source colorfull image => do I need this??
//                let indexSource = sourceImageBuffer.indexFrom(x, y)
//                let pixelSource = sourceImageBuffer[indexSource]
//                let diffSource = sourceColorPixel.diff(pixelSource)
//                var diffSourceVal:CGFloat = CGFloat(diffSource)/CGFloat(tolerance*3)
//                diffSourceVal = diffSourceVal < 0.5 ? 0.0 : diffSourceVal

                // edge image
                let index = indexFrom(x, y)
                let pixel = self[index]
                let diff = pixel.diff(colorPixel)
                var diffVal:CGFloat = CGFloat(diff)/CGFloat(tolerance*3)
                diffVal = diffVal < 0.5 ? 0.0 : diffVal
                // distance
                let dist = CGFloat(startPoint.distance(from: CGPoint(x: x, y: y)))
                let distVal: CGFloat = easeInOutQuad(x: dist/CGFloat(radius))
                let oldAlpha = CGFloat(pixel.data.a) / 255
                if oldAlpha != 1 && oldAlpha != 0 {
                    print(oldAlpha)
                }
                // previous color
//                let prevDiff = previousColorDiff(pixel: pixelSource)
//                print(prevDiff)
                var alpha = max(oldAlpha * (diffVal*0.9 + /*diffSourceVal*0.9 +*/ distVal*0.1), 0.0)
                if dist < CGFloat(radius/2) || alpha < 0.3 {alpha = 0.0}
                else if alpha > 1.0 { return true }
                if dist < CGFloat(radius/3)*2 && alpha < 0.6 {alpha = 0.0}
                let alphaMultiplier = (tolerance == 0) ? 1 : min(1.0, alpha)
                let newPixel = Pixel(pixel.data.r, pixel.data.g, pixel.data.b, UInt8(alphaMultiplier * 255))
//                let newPixel = antialias ? pixel.multiplyAlpha(alphaMultiplier).blend(replacementPixel) : replacementPixel
                self[index] = newPixel
                return false
            }

            while minX >= 0 && startPoint.distance(from: CGPoint(x: minX, y: y)) <= radius {
                let shouldBreak = renderPixel(x: minX, y: y)
                if shouldBreak {break}
                minX -= 1
            }
            while maxX < imageWidth && startPoint.distance(from: CGPoint(x: maxX, y: y)) < radius {
                let shouldBreak = renderPixel(x: maxX, y: y)
                if shouldBreak {break}
                maxX += 1
            }
            if maxX - minX <= 1 {
                continue
            }
            for x in ((minX + 1)...(maxX - 1)) {
                counter += 1
                if y < imageHeight - 1 && y < startingPoint.1 + radius {
                    let index = indexFrom(x, y + 1)
                    if !seenIndices.contains(index) && (differenceAtIndex(index, toPixel: colorPixel) <= tolerance  || startPoint.distance(from: CGPoint(x: x, y: y+1)) <= radius/2){
                        indices.add(index)
                    }
                }
                if y > 0 && y > startingPoint.1 - radius {
                    let index = indexFrom(x, y - 1)
                    if !seenIndices.contains(index) && (differenceAtIndex(index, toPixel: colorPixel) <= tolerance || startPoint.distance(from: CGPoint(x: x, y: y+1)) <= radius/2) {
                        indices.add(index)
                    }
                }
            }
        }
        let endDate = Date()
        print("finished in \(endDate.timeIntervalSince(startDate)) \(counter) times")
    }
    
    func easeInOutQuad(x: CGFloat) -> CGFloat {
        return x < 0.5 ? 2 * x * x : x * (4 - 2 * x) - 1
    }
    
    subscript(index: Int) -> Pixel {
        get {
            return bitmap![index]
        }
        set(pixel) {
            self.bitmap?[index] = pixel
        }
    }
    
    var image: UIImage? {
//        var arr = [UInt8]()
//        for pix in bitmap ?? [] {
//            arr.append(pix.r * UInt8(Double(pix.a) / 255.0))
//            arr.append(pix.g * UInt8(Double(pix.a) / 255.0))
//            arr.append(pix.b * UInt8(Double(pix.a) / 255.0))
//        }

        return imageFromBitmap(pixels: bitmap!, width: imageWidth, height: imageHeight)
//        let datos: Data = NSData(bytes: arr, length: arr.count) as Data
//        return UIImage(data: datos) // Note it's optional. Don't force unwrap!!!
    }
    
    func imageFromBitmap(pixels: [Pixel], width: Int, height: Int) -> UIImage? {
        let pixelsData = pixels.map { (pixel) in
            return pixel.data
        }
        
        let pixelDataSize = MemoryLayout<Pixel.PixelData>.size
        let data: Data = pixelsData.withUnsafeBufferPointer {
            return Data(buffer: $0)
        }
        
        let cfdata = NSData(data: data) as CFData
        let provider: CGDataProvider! = CGDataProvider(data: cfdata)
        if provider == nil {
            print("CGDataProvider is not supposed to be nil")
            return nil
        }
        let cgimage: CGImage! = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * pixelDataSize,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
        if cgimage == nil {
            print("CGImage is not supposed to be nil")
            return nil
        }
        return UIImage(cgImage: cgimage)
    }

    
}


extension CGPoint {
    func distance(from point: CGPoint) -> Int {
        let xDist = x - point.x
        let yDist = y - point.y
        return Int(sqrt((xDist * xDist) + (yDist * yDist)))
    }
}
