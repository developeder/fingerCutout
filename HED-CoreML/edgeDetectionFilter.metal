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
    
    float4 edgeDetection (sampler src,
                          sampler mask,
                          float4 color,
                          float4 color1,
                          float4 color2,
                          float4 color3,
                          float tolerance,
                          float x,
                          float y,
                          float width,
                          float height,
                          float radius,
                          float velocity)
    {
        float2 point = src.coord();
        float4 pixelValue = unpremultiply(src.sample(point));
        
        float2 pointMask = mask.coord();
        float4 maskPixelValue = unpremultiply(mask.sample(pointMask));
        
        float dist = sqrt(pow(x - (point.x*width), 2.0) + pow(y - (point.y*height), 2.0));
        if (dist > radius) {
            return premultiply(pixelValue);
        }
        
        float r = pow((color.r - pixelValue.r) * 255.0, 2.0);
        float g = pow((color.g - pixelValue.g) * 255.0, 2.0);
        float b = pow((color.b - pixelValue.b) * 255.0, 2.0);
        float diff = (r + g + b);

        float r1 = pow((color1.r - pixelValue.r) * 255.0, 2.0);
        float g1 = pow((color1.g - pixelValue.g) * 255.0, 2.0);
        float b1 = pow((color1.b - pixelValue.b) * 255.0, 2.0);
        float diff1 = (r1 + g1 + b1);

        float r2 = pow((color2.r - pixelValue.r) * 255.0, 2.0);
        float g2 = pow((color2.g - pixelValue.g) * 255.0, 2.0);
        float b2 = pow((color2.b - pixelValue.b) * 255.0, 2.0);
        float diff2 = (r2 + g2 + b2);

        float r3 = pow((color3.r - pixelValue.r) * 255.0, 2.0);
        float g3 = pow((color3.g - pixelValue.g) * 255.0, 2.0);
        float b3 = pow((color3.b - pixelValue.b) * 255.0, 2.0);
        float diff3 = (r3 + g3 + b3);

        float rdist = dist/radius - 0.2;
        rdist = rdist < 0.0 ? 0.0 : rdist;
        float distVal = rdist < 0.5 ? 2.0 * rdist * rdist : rdist * (4.0 - 2.0 * rdist) - 1.0; // easeInOut
        float outA = (diff/tolerance) * rdist * 0.3
        + (diff1/tolerance) * rdist * 0.2
        + (diff2/tolerance) * rdist * 0.1
        + (diff3/tolerance) * rdist * 0.1
        + distVal
        - velocity;
        
        if (maskPixelValue.a > 0.8 && pixelValue.a > 0.8) {
            outA = outA * 2;
        }

        outA = outA > 1.0 ? 1.0 : outA;
        outA = outA < 0.0 ? 0.0 : outA;
        outA = outA * pixelValue.a;
        float4 outRgba = float4(pixelValue.rgb, outA);
        return premultiply(outRgba);
    }
}}
