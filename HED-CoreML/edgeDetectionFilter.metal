//
//  edgeDetectionFilter.metal
//  HED-CoreML
//
//  Created by eder yifrach on 27/08/2018.
//  Copyright © 2018 s1ddok. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#include <CoreImage/CoreImage.h>

extern "C" { namespace coreimage {
    
    float4 edgeDetection (sampler editted,
                          sampler src,
                          sampler mask,
                          float4 color,
                          float4 color1,
                          float4 color2,
                          float4 color3,
                          float tolerance,
                          float2 center,
                          float width,
                          float height,
                          float radius)
    {
        float2 edittedPoint = editted.coord();
        float4 edittedPixelValue = unpremultiply(editted.sample(edittedPoint));
        float dist = sqrt(pow(center.x - (edittedPoint.x*width), 2.0) + pow(center.y - (edittedPoint.y*height), 2.0));
        if (dist > radius) {
            return premultiply(edittedPixelValue);
        }
        
        float2 srcPoint = src.coord();
        float4 srcPixelValue = unpremultiply(src.sample(srcPoint));
        
//        float2 maskPoint = mask.coord();
//        float4 maskPixelValue = unpremultiply(mask.sample(maskPoint));
        
        float r = pow((color.r - srcPixelValue.r) * 255.0, 2.0);
        float g = pow((color.g - srcPixelValue.g) * 255.0, 2.0);
        float b = pow((color.b - srcPixelValue.b) * 255.0, 2.0);
        float diff = (r + g + b);

        float r1 = pow((color1.r - srcPixelValue.r) * 255.0, 2.0);
        float g1 = pow((color1.g - srcPixelValue.g) * 255.0, 2.0);
        float b1 = pow((color1.b - srcPixelValue.b) * 255.0, 2.0);
        float diff1 = (r1 + g1 + b1);

        float r2 = pow((color2.r - srcPixelValue.r) * 255.0, 2.0);
        float g2 = pow((color2.g - srcPixelValue.g) * 255.0, 2.0);
        float b2 = pow((color2.b - srcPixelValue.b) * 255.0, 2.0);
        float diff2 = (r2 + g2 + b2);

        float r3 = pow((color3.r - srcPixelValue.r) * 255.0, 2.0);
        float g3 = pow((color3.g - srcPixelValue.g) * 255.0, 2.0);
        float b3 = pow((color3.b - srcPixelValue.b) * 255.0, 2.0);
        float diff3 = (r3 + g3 + b3);

        float rdist = dist/radius;
        rdist = rdist < 0.0 ? 0.0 : rdist;
        float distVal = rdist < 0.5 ? 8.0 * pow(rdist, 4.0) : 1.0 - 8 * pow((rdist - 1.0), 4.0); // easeInOutQuart
        float outA = (diff/tolerance) * rdist * 0.3
        + (diff1/tolerance) * rdist * 0.2
        + (diff2/tolerance) * rdist * 0.1
        + (diff3/tolerance) * rdist * 0.1
        + distVal;

        outA = outA > 1.0 ? 1.0 : outA;
        outA = outA < 0.2 ? 0.0 : outA;
        outA = outA * edittedPixelValue.a;
        float4 outRgba = float4(edittedPixelValue.rgb, outA);
        return premultiply(outRgba);
    }
}}
