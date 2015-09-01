//
//  ViewController.h
//  SuperVision+ Goggles
//
//  Created by Pengfei Tan on 6/2/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <ImageIO/ImageIO.h>
#import "math.h"
#import "AppDelegate.h"
#import "SVScrollView.h"
#import "SVSlider.h"
#import "HelpViewController.h"
#import "ImageProcess.h"
#import "MagnetSensor.h"
#import "Accelerometer.h"
#import "Gyro.h"

@interface ViewController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate, SVScrollViewTouchDelegate>

//  User Interface
// scroll views
@property (strong, nonatomic) IBOutlet SVScrollView *scrollViewLeft;
@property (strong, nonatomic) IBOutlet SVScrollView *scrollViewRight;

// menu items
@property (strong, nonatomic) IBOutlet UIButton *zoomItemLeft;
@property (strong, nonatomic) IBOutlet UIButton *zoomItemRight;
@property (strong, nonatomic) IBOutlet UIButton *flashItemLeft;
@property (strong, nonatomic) IBOutlet UIButton *flashItemRight;
@property (strong, nonatomic) IBOutlet UIButton *imageItemLeft;
@property (strong, nonatomic) IBOutlet UIButton *imageItemRight;
@property (strong, nonatomic) IBOutlet UIButton *exitItemLeft;
@property (strong, nonatomic) IBOutlet UIButton *exitItemRight;

// buttons
@property (strong, nonatomic) IBOutlet UIButton *flashButtonLeft;
@property (strong, nonatomic) IBOutlet UIButton *flashButtonRight;
@property (strong, nonatomic) IBOutlet UIButton *imageButtonLeft;
@property (strong, nonatomic) IBOutlet UIButton *imageButtonRight;
@property (strong, nonatomic) IBOutlet UIButton *infoButtonLeft;
@property (strong, nonatomic) IBOutlet UIButton *infoButtonRight;

// zoom sliders
@property (strong, nonatomic) IBOutlet UIImageView *sliderBackgroundLeft;
@property (strong, nonatomic) IBOutlet UIImageView *sliderBackgroundRight;
@property (strong, nonatomic) IBOutlet SVSlider *zoomSliderLeft;
@property (strong, nonatomic) IBOutlet SVSlider *zoomSliderRight;
//  current ZoomScale
@property (nonatomic) float currentZoomScale;

// messages
@property (strong, nonatomic) IBOutlet UILabel *messageLeft;
@property (strong, nonatomic) IBOutlet UILabel *messageRight;

//  HelperView
@property (strong, nonatomic) HelpViewController *helpViewController;

//  Capture
// capture session is used to control frame flow from camerra
@property (strong, nonatomic) AVCaptureSession *captureSession;
// CGImageRef
@property (nonatomic) CGImageRef cgImageRef;
// CIContext is used to get new CGImageRef
@property (nonatomic) CIContext *ciContext;
//  image process logic class
@property (strong, nonatomic) ImageProcess *imageProcess;
//  a state to indicate whether to hide all controls;
@property (strong, nonatomic) NSString *currentResolution;
// lock state for application
@property (nonatomic, getter=isLocked) BOOL locked;
//  to change it 1080p for ip4S
@property (nonatomic, getter=isBeforeLocked) BOOL beforeLocked;
// count the current frame number of image number, starts with 0
@property (nonatomic) int imageNo;
// accumulate the motion vector on x and y axis
@property (nonatomic) float motionX;
@property (nonatomic) float motionY;
// resulution of the image
@property (nonatomic) int resolutionWidth;
@property (nonatomic) int resolutionHeight;
// offset
@property (nonatomic) CGPoint correctContentOffset;
// feature detection window size
@property (nonatomic) int featureWindowWidth;
@property (nonatomic) int featureWindowHeight;
/* store the highest variance's image */
@property (strong, nonatomic) UIImage *highVarImg;
@property (nonatomic) double maxVariance;
@property (nonatomic) CGImageRef maxVarImg;
@property (nonatomic) BOOL adjustingFocus;
@property (nonatomic) int lockDelay;
//  offset array
@property (strong, nonatomic) NSMutableArray* offsetArray;
// release stablization
@property (nonatomic, getter=isStabilizationEnabled) BOOL stabilizationEnabled;
@property (nonatomic, getter=isBeingReleased) BOOL beingReleased;
@property (nonatomic) NSInteger increasing;
@property (nonatomic) float move_x;
@property (nonatomic) float move_y;

//  User Interface Control
@property (nonatomic, getter=isMenuHidden) BOOL menuHidden;
@property (nonatomic, getter=isControlHidden) BOOL controlHidden;
@property (nonatomic, getter=isFlashOn) BOOL flashOn;
@property (nonatomic, getter=isImageModeOn) BOOL imageModeOn;
// Menu Target Control
@property (nonatomic, getter=isZoomTargetted) BOOL zoomTargetted;
@property (nonatomic, getter=isFlashTargetted) BOOL flashTargetted;
@property (nonatomic, getter=isImageTargetted) BOOL imageTargetted;
@property (nonatomic, getter=isExitTargetted) BOOL exitTargetted;
@property (nonatomic) float targetCursor;
@property (nonatomic, getter=isZoomSelected) BOOL zoomSelected;
// Quickly Zoom Out
@property (nonatomic, getter=isZoomOutModeOn) BOOL zoomOutModeOn;

//  Motion
@property (strong, nonatomic) CMMotionManager * motionManager;
// Magnet
@property (nonatomic) SuperVision::MagnetSensor * magnetSensor;
// Accelerometer
@property (nonatomic) SuperVision::Accelerometer * accelerometer;
// Gyro
@property (nonatomic) SuperVision::Gyro * gyro;

- (void)applicationWillResignActive;
- (void)applicationDidBecomeActive;
- (void)applicationDidEnterBackground;
- (void)applicationWillEnterForeground;

@end

