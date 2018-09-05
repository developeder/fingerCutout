//
//  OpenCVWrapper.m
//  HED-CoreML
//
//  Created by Dror Yaffe - Bazaart LTD on 9/5/18.
//  Copyright © 2018 s1ddok. All rights reserved.
//

#import "OpenCVWrapper.h"

@implementation OpenCVWrapper

+ (UIImage *)normalizeImage:(UIImage*)img {
    UIGraphicsBeginImageContextWithOptions(img.size, NO, img.scale);
    [img drawInRect:(CGRect){0, 0, img.size}];
    UIImage* orientedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return orientedImage;
}

+ (UIImage *)generateSuperPixels:(UIImage*)input {
    UIImage *normalizedInput = [self normalizeImage:input];
    cv::Mat rgbaMat = [self toCvMat:normalizedInput];

    int num_superpixels = 200;
    int num_levels = 4;
    int num_iterations = 10;
    cv::Mat result, mask, labels;

    cv::Ptr<cv::ximgproc::SuperpixelSEEDS> seeds = cv::ximgproc::createSuperpixelSEEDS(rgbaMat.size().width, rgbaMat.size().height, rgbaMat.channels(), num_superpixels, num_levels);
    
    seeds->iterate(rgbaMat, num_iterations);
    seeds->getLabelContourMask(mask, true);

    UIImage* maskJpeg = [self fromCvMat:mask];
    UIImage* maskPNG = [self clearBlackPixels:maskJpeg];
    return maskPNG;
}

// thanks - https://stackoverflow.com/questions/20963046/ios-uiimage-how-to-convert-black-to-transparent-programmatically
+(UIImage*)clearBlackPixels:(UIImage*)input {
    CIContext *context = [CIContext contextWithOptions:nil];
    
    CIImage *image = [CIImage imageWithCGImage:[input CGImage]];
    CIFilter *filter = [CIFilter filterWithName:@"CIMaskToAlpha"];
    [filter setDefaults];
    [filter setValue:image forKey:kCIInputImageKey];
    CIImage *result = [filter outputImage];
    
    CGImageRef cgImage = [context createCGImage:result fromRect:[result extent]];
    
    UIImage *newImage = [UIImage imageWithCGImage:cgImage scale:[input scale] orientation:UIImageOrientationUp];
    CGImageRelease(cgImage);
    return newImage;
}

+ (NSString *)openCVVersionString {
    return [NSString stringWithFormat:@"OpenCV Version %s",  CV_VERSION];
}

+ (cv::Mat)toCvMat:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

+ (cv::Mat)toCvMatGray:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

//+ (UIImage *)fromCvMaskMat:(cv::Mat)cvMat {
//
//}

+ (UIImage *)fromCvMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

+ (UIImage *)getMaskFromJpg:(UIImage *)image {
    if (image == nil) {
        return nil;
    }
    CGImageRef imageRef = image.CGImage;
    int width = (int) CGImageGetWidth(imageRef);
    int height = (int) CGImageGetHeight(imageRef);
    
    unsigned char *imageData = (unsigned char*)calloc(width * height, sizeof(unsigned char));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    
    CGContextRef ctx1 = CGBitmapContextCreate(imageData,
                                              width,
                                              height,
                                              8,
                                              width,
                                              colorSpace,
                                              (CGBitmapInfo)kCGImageAlphaNone |
                                              kCGBitmapByteOrderDefault);
    
    CGContextDrawImage(ctx1, CGRectMake(0, 0, width, height), image.CGImage);
    
    unsigned char *alphaData = (unsigned char*)calloc(1 * width * height, sizeof(unsigned char));
    CGContextRef ctx2 = CGBitmapContextCreate(alphaData,
                                              width,
                                              height,
                                              8,
                                              width*1,
                                              NULL,
                                              (CGBitmapInfo)kCGImageAlphaOnly);
    
    CGContextDrawImage(ctx2, CGRectMake(0, 0, width, height), imageRef);
    // Walk the pixels and invert the alpha value.
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            alphaData[y*width + x] = 255 - imageData[y*width + x];
        }
    }
    
    CGImageRef alphaMaskImage = CGBitmapContextCreateImage(ctx2);
    free(alphaData);
    free(imageData);
    CGContextRelease(ctx1);
    CGContextRelease(ctx2);
    CGColorSpaceRelease(colorSpace);
    UIImage *returnImage = [UIImage imageWithCGImage:alphaMaskImage];
    CGImageRelease(alphaMaskImage);
    return returnImage;
}


@end
