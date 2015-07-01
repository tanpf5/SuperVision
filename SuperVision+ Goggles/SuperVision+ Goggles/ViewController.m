//
//  ViewController.m
//  SuperVision+ Goggles
//
//  Created by Pengfei Tan on 6/2/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

#import "ViewController.h"

#pragma mark - resolution settings
#define RESOLUTION1 AVCaptureSessionPreset1920x1080
#define RESOLUTION2 AVCaptureSessionPreset1280x720
#define RESOLUTION3 AVCaptureSessionPresetiFrame960x540
#define RESOLUTION4 AVCaptureSessionPreset640x480
#define OTHERRESOLUTION RESOLUTION1
#define IP4RESOLUTION RESOLUTION3

@interface ViewController ()
//  User Interface Control
@property (assign, nonatomic) BOOL isMenuHidden;
@property (assign, nonatomic) BOOL isButtonHidden;


@end

@implementation ViewController
//  User Interface
// scroll views
@synthesize scrollViewLeft;
@synthesize scrollViewRight;

// menu items
@synthesize zoomItemLeft;
@synthesize zoomItemRight;
@synthesize flashItemLeft;
@synthesize flashItemRight;
@synthesize imageItemLeft;
@synthesize imageItemRight;
@synthesize exitItemLeft;
@synthesize exitItemRight;
@synthesize isMenuHidden; // all menu items

// buttons
@synthesize flashButtonLeft;
@synthesize flashButtonRight;
@synthesize imageButtonLeft;
@synthesize imageButtonRight;
@synthesize infoButtonLeft;
@synthesize infoButtonRight;
@synthesize isButtonHidden; // all buttons

// zoom sliders
@synthesize sliderBackgroundLeft;
@synthesize sliderBackgroundRight;
@synthesize zoomSliderLeft;
@synthesize zoomSliderRight;

// messages
@synthesize messageLeft;
@synthesize messageRight;

//  Capture
@synthesize captureSession;

#pragma mark -
#pragma mark Initial Functions

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initialView];
    [self initialSettings];
    [self initialCapture];
}

- (void)initialView {
    self.isMenuHidden = true;
    self.isButtonHidden = true;
    [self hideAllControls];
}

- (void)initialSettings {
    self.scrollViewLeft.touchDelegate = self;
    self.scrollViewRight.touchDelegate = self;
    if ([self isIphone4]) {
        self.currentResolution = IP4RESOLUTION;
        /*self.featureWindowHeight = 72;
        self.featureWindowWidth = 128;
        [self.imageProcess setMaxFeatureNumber:6];
        [self.scrollView changeImageViewFrame:CGRectMake(0, 0, 540*self.currentZoomRate, 960*self.currentZoomRate)];
        [self.scrollViewRight changeImageViewFrame:CGRectMake(0, 0, 540*self.currentZoomRate, 960*self.currentZoomRate)];
        float viewScale = min(self.scrollView.imageView.frame.size.width/ScreenWidth,
                              self.scrollView.imageView.frame.size.height/ScreenHeight);
        [self.scrollView setMinimumZoomScale:1/viewScale];
        [self.scrollViewRight setMinimumZoomScale:1/viewScale];
        [self.zoomSlider setMinimumValue:1/viewScale];
        [self.zoomSliderRight setMinimumValue:1/viewScale];
        self.resolutionWidth = 540*self.currentZoomRate;
        self.resolutionHeight = 960*self.currentZoomRate;
        [self.scrollView setZoomScale:1];
        [self.scrollViewRight setZoomScale:1];
        self.lockDelay = [self isIphone4]? 12:8;*/
    } else {
        self.currentResolution = OTHERRESOLUTION;
        /*[self.scrollView setZoomScale:1];
        [self.scrollViewRight setZoomScale:1];
        [self.zoomSlider setValue:1];
        [self.zoomSliderRight setValue:1];
        self.featureWindowWidth = 284;
        self.featureWindowHeight = 320;
        [self.imageProcess setMaxFeatureNumber:20];
        [self.scrollView changeImageViewFrame:CGRectMake(0, 0, 1080, 1920)];
        [self.scrollViewRight changeImageViewFrame:CGRectMake(0, 0, 1080, 1920)];
        float viewScale = min(self.scrollView.imageView.frame.size.width/ScreenWidth,
                              self.scrollView.imageView.frame.size.height/ScreenHeight);
        //        [self.scrollView setMinimumZoomScale:1/viewScale];
        //        [self.zoomSlider setMinimumValue:1/viewScale];
        [self setMinimalZoomScale:1/viewScale];
        self.resolutionWidth = 1080;
        self.resolutionHeight = 1920;
        self.lockDelay = 10;*/
    }
}

- (void) initialCapture {
    /*We setup the input*/
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput
                                          deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo]
                                          error:nil];
    /*We setupt the output*/
    AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    /*While a frame is processes in -captureOutput:didOutputSampleBuffer:fromConnection: delegate methods no other frames are added in the queue.
     If you don't want this behaviour set the property to NO */
    captureOutput.alwaysDiscardsLateVideoFrames = YES;
    /*We specify a minimum duration for each frame (play with this settings to avoid having too many frames waiting
     in the queue because it can cause memory issues). It is similar to the inverse of the maximum framerate.
     In this example we set a min frame duration of 1/10 seconds so a maximum framerate of 10fps. We say that
     we are not able to process more than 10 frames per second.*/
    
    /*We create a serial queue to handle the processing of our frames*/
    dispatch_queue_t queue;
    queue = dispatch_queue_create("cameraQueue", NULL);
    [captureOutput setSampleBufferDelegate:self queue:queue];
    // Set the video output to store frame in BGRA (It is supposed to be faster)
    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
    [captureOutput setVideoSettings:videoSettings];
    /*And we create a capture session*/
    self.captureSession = [[AVCaptureSession alloc] init];
    
    /*We add input and output*/
    [self.captureSession addInput:captureInput];
    [self.captureSession addOutput:captureOutput];
    /*We use medium quality, ont the iPhone 4 this demo would be laging too much, the conversion in UIImage and CGImage demands too much ressources for a 720p resolution.*/
    [self.captureSession setSessionPreset:self.currentResolution];
    /*We start the capture*/
    [self.captureSession startRunning];
}

#pragma mark - 
#pragma mark UI Controls

- (void)hideAllControls {
    //  Menu
    [self.zoomItemLeft setHidden:YES];
    [self.zoomItemRight setHidden:YES];
    [self.flashItemLeft setHidden:YES];
    [self.flashItemRight setHidden:YES];
    [self.imageItemLeft setHidden:YES];
    [self.imageItemRight setHidden:YES];
    [self.exitItemLeft setHidden:YES];
    [self.exitItemRight setHidden:YES];
    //  Buttons
    [self.flashButtonLeft setHidden:YES];
    [self.flashButtonRight setHidden:YES];
    [self.imageButtonLeft setHidden:YES];
    [self.imageButtonRight setHidden:YES];
    [self.infoButtonLeft setHidden:YES];
    [self.infoButtonRight setHidden:YES];
    //  Zoom sliders
    [self.sliderBackgroundLeft setHidden:YES];
    [self.sliderBackgroundRight setHidden:YES];
    [self.zoomSliderLeft setHidden:YES];
    [self.zoomSliderRight setHidden:YES];
    //  Messages
    [self.messageLeft setHidden:YES];
    [self.messageRight setHidden:YES];
}

- (void) showMessage:(NSString*)s {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.messageLeft.text = s;
        self.messageRight.text = s;
        [self.messageLeft setHidden:NO];
        [self.messageRight setHidden:NO];
    });
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.messageLeft setHidden:YES];
        [self.messageRight setHidden:YES];
    });
}

#pragma mark -
#pragma mark UI Controls
- (void)handleDoubleTap:(UIGestureRecognizer *)gesture {
    [self showMessage:@"double Tap"];
}
- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    
}

#pragma mark -
#pragma mark Helper Functions

- (BOOL)isIphone4 {
    return [AppDelegate isIphone4];
}

#pragma mark -
#pragma mark Memory management
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
