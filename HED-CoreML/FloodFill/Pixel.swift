//
//  Pixel.swift
//  PaintBucket
//
//  Created by Jack Flintermann on 3/15/16.
//  Copyright © 2016 jflinter. All rights reserved.
//

import CoreGraphics
import UIKit

struct Pixel {
    
    struct PixelData {
        var r: UInt8 = 0
        var b: UInt8 = 0
        var g: UInt8 = 0
        var a: UInt8 = 0
    }

    var data: PixelData = PixelData()
    
    init(_ r: UInt8, _ g: UInt8, _ b: UInt8, _ a: UInt8) {
        data.r = r
        data.g = g
        data.b = b
        data.a = a
    }
    
    init(color: UIColor) {
        let model = color.cgColor.colorSpace?.model
        if model == .monochrome {
            var white: CGFloat = 0
            var alpha: CGFloat = 0
            color.getWhite(&white, alpha: &alpha)
            data.r = UInt8(white * 255)
            data.g = UInt8(white * 255)
            data.b = UInt8(white * 255)
            data.a = UInt8(alpha * 255)
        } else if model == .rgb {
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            color.getRed(&r, green: &g, blue: &b, alpha: &a)
            data.r = UInt8(r * 255)
            data.g = UInt8(g * 255)
            data.b = UInt8(b * 255)
            data.a = UInt8(a * 255)
        } else {
            data.r = 0
            data.g = 0
            data.b = 0
            data.a = 0
        }
    }
    
    var color: UIColor {
        return UIColor(red: CGFloat(data.r) / 255, green: CGFloat(data.g) / 255, blue: CGFloat(data.b) / 255, alpha: CGFloat(data.a) / 255)
    }
    
    var uInt32Value: UInt32 {
        var total = (UInt32(data.a) << 24)
        total += (UInt32(data.r) << 16)
        total += (UInt32(data.g) << 8)
        total += (UInt32(data.b) << 0)
        return total
    }
    
    static func componentDiff(_ l: UInt8, _ r: UInt8) -> UInt8 {
        return max(l, r) - min(l, r)
    }
    
    func multiplyAlpha(_ alpha: CGFloat) -> Pixel {
        return Pixel(data.r, data.g, data.b, UInt8(CGFloat(data.a) * alpha))
    }
    
    func blend(_ other: Pixel) -> Pixel {
        let a1 = CGFloat(data.a) / 255.0
        let a2 = CGFloat(other.data.a) / 255.0

        return Pixel(
            UInt8((a1 * CGFloat(data.r)) + (a2 * (1 - a1) * CGFloat(other.data.r))),
            UInt8((a1 * CGFloat(data.g)) + (a2 * (1 - a1) * CGFloat(other.data.g))),
            UInt8((a1 * CGFloat(data.b)) + (a2 * (1 - a1) * CGFloat(other.data.b))),
            UInt8((255 * (a1 + a2 * (1 - a1))))
        )
    }
    
    func diff(_ other: Pixel) -> Int {
        let r = Int(Pixel.componentDiff(data.r, other.data.r))
        let g = Int(Pixel.componentDiff(data.g, other.data.g))
        let b = Int(Pixel.componentDiff(data.b, other.data.b))
//        let a = Int(Pixel.componentDiff(self.a, other.a))
        return r*r + g*g + b*b// + a*a
    }
    
    
}
