//
//  OpenGLImageView.swift
//  HED-CoreML
//
//  Created by eder yifrach on 23/08/2018.
//  Copyright © 2018 s1ddok. All rights reserved.
//


import GLKit
import UIKit

/// `OpenGLImageView` wraps up a `GLKView` and its delegate into a single class to simplify the
/// display of `CIImage`.
///
/// `OpenGLImageView` is hardcoded to simulate ScaleAspectFit: images are sized to retain their
/// aspect ratio and fit within the available bounds.
///
/// `OpenGLImageView` also respects `backgroundColor` for opaque colors

class OpenGLImageView: GLKView {
    var eaglContext: EAGLContext!
    
    lazy var ciContext: CIContext = {
        var wideColor = false
        
        if #available(iOS 10, *) {
            if UIScreen.main.traitCollection.displayGamut == .P3 {
                wideColor = true
            }
        }
        
        if wideColor {
            return CIContext(eaglContext: self.eaglContext, options:[ kCIContextWorkingFormat : Int(kCIFormatRGBAh)])
        } else {
            return CIContext(eaglContext: self.eaglContext, options:nil)
        }
        
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame, context: eaglContext)
        
        isOpaque = false
        
        context = self.eaglContext
        delegate = self
    }
    
    override init(frame: CGRect, context: EAGLContext) {
        eaglContext = context;
        super.init(frame: frame, context: context)
        
        isOpaque = false
        delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        isOpaque = false
        delegate = self
    }
    
    /// The image to display
    @objc var image: CIImage? {
        didSet {
            setNeedsDisplay()
        }
    }
}

extension OpenGLImageView: GLKViewDelegate {
    func glkView(_ view: GLKView, drawIn rect: CGRect) {
        guard let image = image else {
            return
        }
        
        // OpenGLES drawing setup.
        glClearColor(0.0, 0.0, 0.0, 0.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        
        // Set the blend mode to "source over" so that CI will use that.
        glEnable(GLenum(GL_BLEND))
        glBlendFunc(GLenum(GL_ONE), GLenum(GL_ONE_MINUS_SRC_ALPHA))
        
        
        let scale = rect.size.width*UIScreen.main.scale/image.extent.size.width
        contentScaleFactor = scale > 1 ? 1.0 : UIScreen.main.scale
        
        let targetRect = image.extent.aspetFillInRect(CGRect(origin: CGPoint.zero, size: CGSize(width: drawableWidth, height: drawableHeight)))
        ciContext.draw(image, in: targetRect, from: image.extent)
    }
}

extension CGRect {
    
    func aspetFillInRect(_ target: CGRect) -> CGRect {
        let aspect = self.size.width / self.size.height
        let rect: CGRect
        if target.size.width / aspect > target.size.height {
            let height = target.size.width / aspect
            rect = CGRect(x: 0, y: (target.size.height - height) / 2,
                          width: target.size.width, height: height)
        } else {
            let width = target.size.height * aspect
            rect = CGRect(x: (target.size.width - width) / 2, y: 0,
                          width: width, height: target.size.height)
        }
        return rect
    }
    
    func aspectFitInRect(_ target: CGRect) -> CGRect {
        let scale: CGFloat = {
            let scale = target.width / self.width
            return self.height * scale <= target.height ? scale : target.height / self.height
        }()
        
        let width = self.width * scale
        let height = self.height * scale
        let x = target.midX - width / 2
        let y = target.midY - height / 2
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

