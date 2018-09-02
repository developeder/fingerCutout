//
//  ImageProcessKernel.swift
//  HED-CoreML
//
//  Created by eder yifrach on 30/08/2018.
//  Copyright © 2018 s1ddok. All rights reserved.
//

import UIKit
import MetalPerformanceShaders

class ThresholdImageProcessorKernel: CIImageProcessorKernel {
    static let device = MTLCreateSystemDefaultDevice()
    override class func process(with inputs: [CIImageProcessorInput]?, arguments: [String : Any]?, output: CIImageProcessorOutput) throws {
        guard
            let device = device,
            let commandBuffer = output.metalCommandBuffer,
            let input = inputs?.first,
            let sourceTexture = input.metalTexture,
            let destinationTexture = output.metalTexture else  {
                return
        }
        
        let threshold = MPSImageThresholdToZero(device: device, thresholdValue: 0.0, linearGrayColorTransform: nil)

        threshold.encode(
            commandBuffer: commandBuffer,
            sourceTexture: sourceTexture,
            destinationTexture: destinationTexture)
    }
}
