//
//  OpenCVWrapper.h
//  HED-CoreML
//
//  Created by Dror Yaffe - Bazaart LTD on 9/5/18.
//  Copyright © 2018 s1ddok. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface OpenCVWrapper : NSObject

+ (UIImage *)normalizeImage:(UIImage*)img;
+ (UIImage *)generateSuperPixels:(UIImage*)input;

@end
