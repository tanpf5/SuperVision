//
//  ImageProcess.m
//  EyeSee
//
//  Created by Zewen Li on 7/5/13.
//  Copyright (c) 2013 Zewen Li. All rights reserved.
//

#import "ImageProcess.h"
#import "../../../Framework/opencv2.framework/Headers/opencv.hpp"
using namespace cv;

#define MAX_FEATURES 30

@interface ImageProcess ()

//  record the number of features in fast detection
//@property (nonatomic, assign) int featureNum;
//  record the number of valid features in tracking
@property (nonatomic, assign) int trackedFeatureNum;
@end

std::vector<cv::KeyPoint> fastFeaturePoints(100);
cv::Mat feature_pts1(MAX_FEATURES, 2, CV_32FC1);
cv::Mat feature_pts2(MAX_FEATURES, 2, CV_32FC1);
cv::Mat err(MAX_FEATURES, 1, CV_32FC1);
cv::Mat status(MAX_FEATURES, 1, CV_8UC1);
/// tracking window size
cv::Size winSize = cv::Size(21,21);
/// number of pyramid levels
int maxLevel=2;
cv::TermCriteria criteria = cv::TermCriteria(cv::TermCriteria::COUNT+cv::TermCriteria::EPS, 30, 0.01);
/// relative weight of gradients
double derivLambda=0.05;
int featureNum;

std::vector<double> meanList;
std::vector<double> stdDev;


@implementation ImageProcess

@synthesize lastImgMat = _lastImgMat;
@synthesize currentImgMat = _currentImgMat;
@synthesize maxFeatureNumber = _maxFeatureNumber;
@synthesize threshold = _threshold;

#pragma mark - initial
- (ImageProcess *) init {
    self.threshold = 25;
    self.maxFeatureNumber = 30;
    self = [super init];
    return self;
}

#pragma mark - motion estimation, detection and tracking
//  fast feature detection
- (int) fastFeatureDetection {

    cv::FAST(self.lastImgMat, fastFeaturePoints, self.threshold);
    featureNum = fastFeaturePoints.size();
    if (featureNum >= self.maxFeatureNumber) {
        featureNum = self.maxFeatureNumber;
    }
    //  convert the result from vector to matrix for tracking
    for (int i = 0; i < featureNum; i++) {
        feature_pts1.row(i).col(0) = fastFeaturePoints[i].pt.x;
        feature_pts1.row(i).col(1) = fastFeaturePoints[i].pt.y;
    }
    if (featureNum == 0) {
        return 0;
    }
    else {
        return 1;
    }
}


/* calculate the vairance of the whole grey image */
- (double) calVariance {
    
    //! computes mean value and standard deviation of all or selected array elements
    meanStdDev(self.currentImgMat, meanList, stdDev);
    return stdDev[0];
}


- (CGPoint) featureTracking {
    cv::calcOpticalFlowPyrLK(self.lastImgMat, self.currentImgMat, feature_pts1, feature_pts2, status, err, winSize, maxLevel, criteria, derivLambda);
    //  clear valid feature number first
    self.trackedFeatureNum = 0;

    float diffX = 0;
    float diffY = 0;
    float avgX = 0;
    float avgY = 0;
    //  count the number of valid tracking features
    for (int i = 0; i < featureNum; i++)
    {
        if (status.at<uchar>(i,1) == 1) {
            self.trackedFeatureNum++;
            cv::Point2f pt1(feature_pts1.at<float>(i,0), feature_pts1.at<float>(i,1));
            cv::Point2f pt2(feature_pts2.at<float>(i,0), feature_pts2.at<float>(i,1));
            diffX += pt2.x - pt1.x;
            diffY += pt2.y - pt1.y;
        }
    }
    //  if there are available tracking features, get the average
    if (self.trackedFeatureNum > 0) {
        avgX = diffX / self.trackedFeatureNum;
        avgY = diffY / self.trackedFeatureNum;
    }
    //  if no tracked feature points, just set motion vector 0
    else {
        //avgX = 0;
        //avgY = 0;
    }
    return CGPointMake(avgX, avgY);
}

- (CGPoint) motionEstimation {
    //NSDate *fastStartTime = [NSDate date];
    [self fastFeatureDetection];
    //NSDate *fastEndTime = [NSDate date];
    //double timeForFast = [fastEndTime timeIntervalSinceDate:fastStartTime];
    //NSLog(@"3. time for fast detection is: %f\n", timeForFast);
    //NSDate *trackStart = [NSDate date];
    
    //  if there is no feature points after detection
    if (featureNum == 0) {
        self.lastImgMat = self.currentImgMat;
        
        //NSDate *trackEnds = [NSDate date];
        //double timeForTrack = [trackEnds timeIntervalSinceDate:trackStart];
        //NSLog(@"4. time for track is: %f\n", timeForTrack);

        return CGPointMake(0, 0);
    }
    //  if there are feature points
    else {
        CGPoint result = [self featureTracking];
        self.lastImgMat = self.currentImgMat;
        
        //NSDate *trackEnds = [NSDate date];
        //double timeForTrack = [trackEnds timeIntervalSinceDate:trackStart];
        //NSLog(@"4. time for track is: %f\n", timeForTrack);

        return result;
    }
}

#pragma mark - data structure helper
- (Mat)cvMatGrayFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNone |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    
    return cvMat;
}

-(cv::Mat)cvMatFromUIImage: (UIImage *)image
{
    
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to backing data
                                                    cols,                      // Width of bitmap
                                                    rows,                     // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

#pragma mark - attribute access functions

- (void) setLastImageMat: (UIImage *)processUIImage {
    _lastImgMat = [self cvMatGrayFromUIImage:processUIImage];
}

- (void) setCurrentImageMat: (UIImage *)processUIImage {
    _currentImgMat = [self cvMatGrayFromUIImage:processUIImage];
}

#pragma mark - motion feedback function

- (BOOL) overEdge: (float)oldLength newLength:(float)newLength currentScale:(float)currentScale{
    if (newLength * currentScale <= oldLength) {
        return true;
    }
    else
        return false;
}

// x positive - left, negative right;
// y positive - up, negative down;
- (CGRect) calculateMyCroppedImage: (float)x ypos:(float)y width:(float)width height:(float)height scale:(float)currentScale bounds:(CGRect)bounds
{
//    CGRect bounds = [[UIScreen mainScreen]bounds];
    
    float croppedWidth = 0;
    float croppedHeight = 0;
    CGRect rect;
    if (x >= 0) {
        if (y >= 0) {
            croppedWidth = (width - 2 * x);
            if ([self overEdge:bounds.size.height newLength:croppedWidth currentScale:currentScale]) {
            //if (croppedWidth <= bounds.size.height) {
                croppedWidth = bounds.size.height/currentScale;
                x = (width - croppedWidth) / 2;
            }
            croppedHeight = (height - 2 * y);
            if ([self overEdge:bounds.size.height newLength:croppedHeight currentScale:currentScale]) /*(croppedHeight <= bounds.size.width)*/ {
                croppedHeight = bounds.size.width/currentScale;
                y = (height - croppedHeight) / 2;
            }
            rect = CGRectMake(2 * x, 2 * y, croppedWidth, croppedHeight);
        }
        if (y < 0) {
            croppedWidth = (width - 2 * x) ;
            if ([self overEdge:bounds.size.height newLength:croppedWidth currentScale:currentScale]) /*(croppedWidth <= bounds.size.height)*/ {
                croppedWidth = bounds.size.height/currentScale;
                x = (width - croppedWidth) / 2;
            }
            croppedHeight = (height + 2 * y);
            if ([self overEdge:bounds.size.width newLength:croppedHeight currentScale:currentScale]) /*(croppedHeight <= bounds.size.width)*/ {
                croppedHeight = bounds.size.width/currentScale;
                y = -(height - croppedHeight) / 2;
            }
            rect = CGRectMake(2 * x, 0, croppedWidth, croppedHeight);
        }
        return rect;
    }
    
    if (x < 0) {
        if (y >= 0) {
            croppedWidth = (width + 2 * x);
            if ([self overEdge:bounds.size.height newLength:croppedWidth currentScale:currentScale]) /*(croppedWidth <= bounds.size.height)*/ {
                croppedWidth = bounds.size.height/currentScale;
                x = -(width - croppedWidth) / 2;
            }
            croppedHeight = (height - 2 * y);
            if ([self overEdge:bounds.size.width newLength:croppedHeight currentScale:currentScale])/*(croppedHeight <= bounds.size.width)*/ {
                croppedHeight = bounds.size.width/currentScale;
                y = (height - croppedHeight) / 2;
            }
            rect = CGRectMake(0, 2 * y, croppedWidth, croppedHeight);
        }
        if (y < 0) {
            croppedWidth = (width + 2 * x);
            if ([self overEdge:bounds.size.height newLength:croppedWidth currentScale:currentScale])/*(croppedWidth <= bounds.size.height)*/ {
                croppedWidth = bounds.size.height/currentScale;
                x = -(width - croppedWidth) / 2;
            }
            croppedHeight = (height + 2 * y);
            if ([self overEdge:bounds.size.width newLength:croppedHeight currentScale:currentScale])/* (croppedHeight <= bounds.size.width)*/ {
                croppedHeight = bounds.size.width/currentScale;
                y = - (height - croppedHeight) / 2;
            }
            rect = CGRectMake(0, 0, croppedWidth, croppedHeight);
        }
        return rect;
    }
    
    else
        return CGRectMake(0, 0, width, height);
}

@end
