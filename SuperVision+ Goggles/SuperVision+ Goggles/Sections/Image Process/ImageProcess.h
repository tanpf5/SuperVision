//
//  ImageProcess.h
//  EyeSee
//
//  Created by Zewen Li on 7/5/13.
//  Copyright (c) 2013 Zewen Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#include "../../../Framework/opencv2.framework/Headers/opencv.hpp"
@interface ImageProcess : NSObject

@property (nonatomic, assign) cv::Mat lastImgMat;
@property (nonatomic, assign) cv::Mat currentImgMat;
//  threshold for fast detection
@property (nonatomic, assign) int threshold;
//  max feature number for fast detection;
@property (nonatomic, assign) int maxFeatureNumber;

- (void) setLastImageMat: (UIImage *)processUIImage;
- (void) setCurrentImageMat: (UIImage *)processUIImage;
- (CGPoint) motionEstimation;
- (CGRect) calculateMyCroppedImage: (float)x ypos:(float)y width:(float)width height:(float)height scale:(float)currentScale bounds:(CGRect)bounds;
- (int) fastFeatureDetection;
- (double) calVariance;
@end
