//
//  OpenCVWrapper.m
//  HED-CoreML
//
//  Created by eder yifrach on 02/09/2018.
//  Copyright © 2018 s1ddok. All rights reserved.
//


#import "OpenCVWrapper.h"
#import <opencv2/opencv.hpp>


@implementation OpenCVWrapper

+(NSString*)openCvVersionString {
    return [NSString stringWithFormat:@"OpenCv Version %s", CV_VERSION];
}

+(void)createSuperPixelsFromImage:(UIImage*)image {
}

+ (UIBezierPath*)extractContourFromImage:(UIImage *)image {
    if (!image) {
        return nil;
    }
    
    UIImage* paddedImage = [OpenCVWrapper pad:CGRectMake(50, 50, image.size.width, image.size.height) image:image withColor:[UIColor clearColor] andSize:CGSizeMake(image.size.width + 100, image.size.height + 100)];
    
    cv::Mat maskMat;
    maskMat = [OpenCVWrapper cvMatGrayFromUIImage:image];
    
    IplImage *inImage = new IplImage(maskMat);
    
    IplImage *rgbaImage1 = cvCreateImage(cvGetSize(inImage), IPL_DEPTH_8U, 4);
    cvCvtColor(inImage, rgbaImage1, CV_GRAY2BGR);
    UIImage *retImage1 = [OpenCVWrapper UIImageFromIplImage:rgbaImage1];
    cvReleaseImage(&rgbaImage1);
    
    CvMemStorage *g_storage = cvCreateMemStorage();
    CvSeq *contours = 0;
    
    int i = cvFindContours(inImage, g_storage, &contours,
                           sizeof(CvContour), CV_RETR_LIST, CV_CHAIN_APPROX_NONE, cvPoint(0,0));
    
    for (CvSeq *c=contours; c!=NULL; c=c->h_next ) {
        cvDrawContours(inImage, c, cv::Scalar(255, 255, 255), cv::Scalar(45, 100, 200), 1, CV_FILLED, 8);
    }
    
    IplImage *rgbaImage = cvCreateImage(cvGetSize(inImage), IPL_DEPTH_8U, 4);
    cvCvtColor(inImage, rgbaImage, CV_GRAY2BGR);
    UIImage *retImage = [OpenCVWrapper UIImageFromIplImage:rgbaImage];
    cvReleaseImage(&rgbaImage);
    
    cvSmooth(inImage, inImage, CV_GAUSSIAN, 9, 9);
    IplImage *retMask = cvCreateImage(cvGetSize(inImage), IPL_DEPTH_8U, 1);
    for(int y=0; y<inImage->height; y++) {
        for(int x=0; x<inImage->width; x++) {
            double currentVal = cvGet2D(inImage, y ,x).val[0];
            double newVal=0;
            
            if (currentVal < 128) {
                newVal = 0;
            } else {
                newVal = 255;
            }
            cvSet2D(retMask, y, x, cvScalarAll(newVal));
        }
    }
    
    CvMemStorage *g_storageb = cvCreateMemStorage();
    CvSeq *contoursb = 0;
    
    int n = cvFindContours(retMask, g_storageb, &contoursb,
                           sizeof(CvContour), CV_RETR_CCOMP, CV_CHAIN_APPROX_NONE, cvPoint(0,0));
    
    UIBezierPath *path = [OpenCVWrapper extractContour:contours];
    
    //    cvFree_(retMask);
    //    cvFree_(g_storageb);
    //    cvFree_(g_storage);
    
    return path;
    
}

+ (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image
{
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels
    cvMat.data = [OpenCVWrapper getUIImageData:image];
    return cvMat;
}

+ (unsigned char *)getUIImageData:(UIImage *)image
{
    CGImageRef imageRef = image.CGImage;
    int width = (int) CGImageGetWidth(imageRef);
    int height = (int) CGImageGetHeight(imageRef);
    int strideLength = width*1;
    //invert mask
    unsigned char *alphaData = (unsigned char*)calloc(strideLength * height, sizeof(unsigned char));
    CGContextRef ctx = CGBitmapContextCreate(alphaData,
                                             width,
                                             height,
                                             8,
                                             strideLength,
                                             NULL,
                                             (CGBitmapInfo)kCGImageAlphaOnly);
    CGContextDrawImage(ctx, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(ctx);
    return alphaData;
}

+ (UIBezierPath *)extractContour:(CvSeq *)contour {
    if (!contour) {
        return nil;
    }
    UIBezierPath *path = [[UIBezierPath alloc] init];
    for (; contour != 0; contour = contour->h_next) {
        
        cv::Point start, point;
        
        CvSeqReader reader;
        int i, count = contour->total;
        cvStartReadSeq(contour, &reader, 0 );
        
        count -= !CV_IS_SEQ_CLOSED(contour);
        CV_READ_SEQ_ELEM(start, reader);
        UIBezierPath *tempPath = [[UIBezierPath alloc] init];
        
        CGPoint begin = CGPointMake(start.x, start.y);
        [tempPath moveToPoint: begin];
        
        for (i = 0; i < count; i++) {
            CV_READ_SEQ_ELEM(point, reader);
            [tempPath addLineToPoint: CGPointMake(point.x, point.y)];
        }
        [tempPath addLineToPoint:begin];
        [tempPath closePath];
        [path appendPath:tempPath];
    }
    
    return path;
}

+ (IplImage *)removeBlobs:(IplImage *)inImage{
    IplImage *imgCopy = cvCreateImage(cvSize(inImage->width, inImage->height), 8, 1);
    cvCopy(inImage, imgCopy);
    
    CvMemStorage *g_storage = cvCreateMemStorage();
    CvSeq *contours = 0;
    
    cvFindContours(imgCopy, g_storage, &contours,
                   sizeof(CvContour), CV_RETR_LIST, CV_CHAIN_APPROX_NONE, cvPoint(0,0));
    
    for (CvSeq *c=contours; c!=NULL; c=c->h_next ){
        cvDrawContours(inImage, c, cv::Scalar(0, 0, 0), cv::Scalar(0, 0, 0), -1, CV_FILLED, 8);
    }
    
    cvSmooth(inImage, inImage, CV_GAUSSIAN, 7, 7);
    
    for(int y=0; y<inImage->height; y++) {
        for(int x=0; x<inImage->width; x++) {
            double currentVal = cvGet2D(inImage, y ,x).val[0];
            double newVal=0;
            
            if (currentVal < 128) {
                newVal = 0;
            } else {
                newVal = 255;
            }
        }
    }
    
    cvReleaseImage(&imgCopy);
    return inImage;
}

+ (UIImage *)UIImageFromIplImage:(IplImage *)image {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSData *data = [NSData dataWithBytes:image->imageData length:image->imageSize];
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    CGImageRef imageRef = CGImageCreate(image->width, image->height,
                                        image->depth, image->depth * image->nChannels, image->widthStep,
                                        colorSpace, kCGImageAlphaPremultipliedLast,
                                        provider, NULL, false, kCGRenderingIntentDefault);
    UIImage *ret = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    UIGraphicsBeginImageContext(ret.size);
    CGContextRef ref = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(ref, [UIColor redColor].CGColor);
    CGContextFillRect(ref, CGRectMake(0, 0, image->width, image->height));
    
    [ret drawInRect:CGRectMake(0, 0, image->width, image->height)];
    
    return UIGraphicsGetImageFromCurrentImageContext();
}

+ (UIImage *)pad:(CGRect)newRect image:(UIImage*)image withColor:(UIColor*)color andSize:(CGSize)size {
    if (!image) {
        return nil;
    }
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 1.0);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(ctx, [color CGColor]);
    CGContextFillRect(ctx, CGRectMake(0, 0, size.width, size.height));
    
    [image drawInRect:newRect];
    UIImage* paddedMask = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return paddedMask;
}


+ (UIImage *)convert:(CIImage *)ciimage {
    BOOL wideColor = true;
    CIContext *context = context = [CIContext contextWithOptions:@{kCIContextWorkingFormat: [NSNumber numberWithInt:kCIFormatRGBAh]}];
    
    return [self convert:ciimage andContext:context andWideColor:wideColor];
}

+ (UIImage *)convert:(CIImage *)ciimage andContext:(CIContext*)context andWideColor:(BOOL)wideColor {
    CIFormat format = wideColor ? kCIFormatRGBAh : kCIFormatRGBA8;
    CGColorSpaceRef colorSpace = wideColor ? CGColorSpaceCreateWithName(kCGColorSpaceDisplayP3): CGColorSpaceCreateDeviceRGB();
    
    CGImageRef imageRef = [context createCGImage:ciimage fromRect:ciimage.extent format:format colorSpace:colorSpace];
    
    UIImage *outputImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGColorSpaceRelease(colorSpace);
    
    return outputImage;
}

@end
