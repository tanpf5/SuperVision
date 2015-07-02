//
//  ViewController.h
//  Image Mode
//
//  Created by Pengfei Tan on 6/9/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>

@interface ViewController : GLKViewController <AVCaptureVideoDataOutputSampleBufferDelegate>{
    AVCaptureSession *avCaptureSession;
    CIContext *coreImageContext;
    CIImage *maskImage;
    CGSize screenSize;
    CGContextRef cgContext;
    GLuint _renderBuffer;
    float scale;
}

@property (strong, nonatomic) EAGLContext *context;

-(void)setupCGContext;

@end

