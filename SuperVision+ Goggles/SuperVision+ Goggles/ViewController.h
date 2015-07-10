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

@class ImageProcess;

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
@property (assign, nonatomic) float currentZoomScale;

// messages
@property (strong, nonatomic) IBOutlet UILabel *messageLeft;
@property (strong, nonatomic) IBOutlet UILabel *messageRight;

//  HelperView
@property (strong, nonatomic) HelpViewController *helpViewController;

//  Capture
// capture session is used to control frame flow from camerra
@property (nonatomic, strong) AVCaptureSession *captureSession;
//  image process logic class
@property (nonatomic, strong) ImageProcess *imageProcess;
//  a state to indicate whether to hide all controls;
@property (nonatomic, strong) NSString *currentResolution;
// lock state for application
@property (nonatomic, assign) BOOL isLocked;
//  to change it 1080p for ip4S
@property (nonatomic, assign) BOOL beforeLock;
// count the current frame number of image number, starts with 0
@property (nonatomic, assign) int imageNo;
// accumulate the motion vector on x and y axis
@property (nonatomic, assign) float motionX;
@property (nonatomic, assign) float motionY;
// feature detection window size
@property (nonatomic, assign) int featureWindowWidth;
@property (nonatomic, assign) int featureWindowHeight;
/* store the highest variance's image */
@property (nonatomic, strong) UIImage *highVarImg;
@property (nonatomic, assign) double maxVariance;
@property (nonatomic, assign) CGImageRef maxVarImg;
@property (nonatomic, assign) BOOL adjustingFocus;
@property (nonatomic, assign) int lockDelay;
//  offset array
@property (nonatomic, strong) NSMutableArray* offsetArray;
// release stablization
@property (assign, nonatomic) BOOL isStabilizationEnable;
@property (assign, nonatomic) BOOL releasing;
@property (assign, nonatomic) NSInteger increasing;
@property (assign, nonatomic) float move_x;
@property (assign, nonatomic) float move_y;

//  User Interface Control
@property (assign, nonatomic) BOOL isMenuHidden;
@property (assign, nonatomic) BOOL isControlHidden;
@property (assign, nonatomic) BOOL isFlashOn;
@property (assign, nonatomic) BOOL isImageModeOn;
// Menu Target Control
@property (assign, nonatomic) BOOL isZoomTargetted;
@property (assign, nonatomic) BOOL isFlashTargetted;
@property (assign, nonatomic) BOOL isImageTargetted;
@property (assign, nonatomic) BOOL isExitTargetted;
@property (assign, nonatomic) float targetCursor;
@property (assign, nonatomic) BOOL zoomIsSelected;

//  Motion
@property (strong, nonatomic) CMMotionManager * motionManager;
// Magnet
@property (assign, nonatomic) SuperVision::MagnetSensor * magnetSensor;
// Accelerometer
@property (assign, nonatomic) SuperVision::Accelerometer * accelerometer;
// Gyro
@property (assign, nonatomic) SuperVision::Gyro * gyro;

@end

