//
//  ViewController.m
//  SuperVision+ Goggles
//
//  Created by Pengfei Tan on 6/2/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

#import "ViewController.h"
#import "MagnetSensor.h"
#import "Accelerometer.h"

#pragma mark - resolution settings
#define RESOLUTION1 AVCaptureSessionPreset1920x1080
#define RESOLUTION2 AVCaptureSessionPreset1280x720
#define RESOLUTION3 AVCaptureSessionPresetiFrame960x540
#define RESOLUTION4 AVCaptureSessionPreset640x480
#define OTHERRESOLUTION RESOLUTION1
#define IP4RESOLUTION RESOLUTION3
#define FREQUENCY 50

@interface ViewController ()
//  User Interface Control
@property (assign, nonatomic) BOOL isMenuHidden;
@property (assign, nonatomic) BOOL isControlHidden;
@property (assign, nonatomic) BOOL isFlashOn;
@property (assign, nonatomic) BOOL isImageModeOn;

//  Motion
@property (strong, nonatomic) CMMotionManager * motionManager;
// Magnet
@property (assign, nonatomic) SuperVision::MagnetSensor * magnetSensor;
// Accelerometer
@property (assign, nonatomic) SuperVision::Accelerometer * accerometer;

@end

@implementation ViewController
//  User Interface
// control
@synthesize isMenuHidden; // all menu items
@synthesize isControlHidden; // all buttons
@synthesize isFlashOn;
@synthesize isImageModeOn;


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

// buttons
@synthesize flashButtonLeft;
@synthesize flashButtonRight;
@synthesize imageButtonLeft;
@synthesize imageButtonRight;
@synthesize infoButtonLeft;
@synthesize infoButtonRight;

// zoom sliders
@synthesize sliderBackgroundLeft;
@synthesize sliderBackgroundRight;
@synthesize zoomSliderLeft;
@synthesize zoomSliderRight;
@synthesize currentZoomLevel;

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
    [self initialMotion];
}

- (void)initialView {
    self.isMenuHidden = true;
    self.isControlHidden = true;
    [self hideMenuAndControl];
}

- (void)initialSettings {
    self.scrollViewLeft.touchDelegate = self;
    self.scrollViewRight.touchDelegate = self;
    // set initial zoom level
    [self setZoomLevel:1];
    // set initial controls
    self.isFlashOn = false;
    self.isImageModeOn = false;
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

- (void) initialMotion {
    //self.gyro = [[NSMutableArray alloc] init];
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.gyroUpdateInterval = 1.0 / FREQUENCY;
    //self.gyroLock = [[NSLock alloc] init];
    
    
    //  Magnet
    self.magnetSensor = new SuperVision::MagnetSensor();
    _magnetSensor->start();
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(magneticTriggerPressed)
                                                 name:SuperVision::CBDTriggerPressedNotification
                                               object:nil];
    
    //  Accelerometer
    self.accelerometer = new SuperVision::Accelerometer;
    _acc->start();
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(doubleTapPressed)
                                                 name:SuperVision::DoubleTapsNotification
                                               object:nil];
}

#pragma mark -
#pragma mark Basic Controls
- (void)setZoomLevel:(float)zoomLevel{
    self.currentZoomLevel = zoomLevel;
    [self.scrollViewLeft setZoomScale:zoomLevel animated:YES];
    [self.scrollViewRight setZoomScale:zoomLevel animated:YES];
    [self.zoomSliderLeft setValue:zoomLevel animated:YES];
    [self.zoomSliderRight setValue:zoomLevel animated:YES];
}



- (IBAction)zoomLevelChanged:(SVSlider *)slider {
    [self setZoomLevel:slider.value];
}

- (IBAction)flashTapped {
    if (self.isFlashOn) {
        [self turnFlashOff];
        [self showMessage:@"Turned off"];
    } else {
        [self turnFlashOn];
        [self showMessage:@"Turned on"];
    }
    self.isFlashOn = !self.isFlashOn;
}

- (void)turnFlashOn {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasTorch]) {
        [device lockForConfiguration:nil];
        [device setTorchMode:AVCaptureTorchModeOn];
        //  use AVCaptureTorchModeOff to turn off
        [device unlockForConfiguration];
    }
}

- (void)turnFlashOff {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasTorch]) {
        [device lockForConfiguration:nil];
        [device setTorchMode:AVCaptureTorchModeOff];
        //  use AVCaptureTorchModeOff to turn off
        [device unlockForConfiguration];
    }
}

- (IBAction)imageModeTapped {
    if (self.isImageModeOn) {
        [self showMessage:@"Color"];
        [self messageChangeColor:[UIColor blackColor]];
    } else {
        [self showMessage:@"Black and white"];
        [self messageChangeColor:[UIColor whiteColor]];
    }
    self.isImageModeOn = !self.isImageModeOn;
}

- (void) messageChangeColor:(UIColor *)color {
    self.messageLeft.textColor = color;
    self.messageRight.textColor = color;
}



#pragma mark - 
#pragma mark UI Display Controls

- (void)hideMenuAndControl {
    //  Menu
    [self.zoomItemLeft setHidden:YES];
    [self.zoomItemRight setHidden:YES];
    [self.flashItemLeft setHidden:YES];
    [self.flashItemRight setHidden:YES];
    [self.imageItemLeft setHidden:YES];
    [self.imageItemRight setHidden:YES];
    [self.exitItemLeft setHidden:YES];
    [self.exitItemRight setHidden:YES];
    //  Control
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

- (void)hideControl {
    //  Control
    [self.flashButtonLeft setHidden:YES];
    [self.flashButtonRight setHidden:YES];
    [self.imageButtonLeft setHidden:YES];
    [self.imageButtonRight setHidden:YES];
    [self.infoButtonLeft setHidden:YES];
    [self.infoButtonRight setHidden:YES];
    
    //  Zoom sliders
    [self hideZoom];
}

- (void)showControl {
    //  Control
    [self.flashButtonLeft setHidden:NO];
    [self.flashButtonRight setHidden:NO];
    [self.imageButtonLeft setHidden:NO];
    [self.imageButtonRight setHidden:NO];
    [self.infoButtonLeft setHidden:NO];
    [self.infoButtonRight setHidden:NO];
    
    //  Zoom sliders
    [self showZoom];
}

- (void)hideZoom {
    //  Zoom sliders
    [self.sliderBackgroundLeft setHidden:YES];
    [self.sliderBackgroundRight setHidden:YES];
    [self.zoomSliderLeft setHidden:YES];
    [self.zoomSliderRight setHidden:YES];
}

- (void)showZoom {
    //  Zoom sliders
    [self.sliderBackgroundLeft setHidden:NO];
    [self.sliderBackgroundRight setHidden:NO];
    [self.zoomSliderLeft setHidden:NO];
    [self.zoomSliderRight setHidden:NO];
}

- (void)showMessage:(NSString *)s {
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
#pragma mark SVScrollView TouchDelegate
- (void)scrollViewDoubleTapped:(UIGestureRecognizer *)gesture {
    if (isControlHidden) {
        [self showControl];
    } else {
        [self hideControl];
    }
    self.isControlHidden = !self.isControlHidden;
}
- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self setZoomLevel:scrollView.zoomScale];
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
