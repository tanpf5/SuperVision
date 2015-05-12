//
//  ViewController.m
//  SuperVision 2
//
//  Created by Pengfei Tan on 5/11/15.
//
//

#import "ViewController.h"

#define INFOICONWIDTH 30
#define INFOBUTTONWIDTH 30
#define PLUSICONWIDTH 30
#define MINUSICONWIDTH 30
#define SLIDERWIDTH 44
#define SLIDERHEIGHT 250
#define degreeToRadians(x) (M_PI * x / 180.0)
#define OUTVBUTTONOFFSET 30
#define OUTHBUTTONOFFSET 15
#define BUTTONWIDTH 55
#define INBUTTONOFFSET 10

#pragma mark - resolution settings

#define RESOLUTION1 AVCaptureSessionPreset1920x1080
#define RESOLUTION2 AVCaptureSessionPreset1280x720
#define RESOLUTION3 AVCaptureSessionPresetiFrame960x540
#define RESOLUTION4 AVCaptureSessionPreset640x480
#define IP5RESOLUTION RESOLUTION1
#define IP4RESOLUTION RESOLUTION3

// ICON RESOURCES
#define EMPTYIMAGE "empty.png"
#define SLIDERTHUMB "sliderthumb2.png"

@interface ViewController ()

@end


@implementation ViewController

@synthesize zoomSlider = _zoomSlider;
@synthesize captureSession = _captureSession;
@synthesize currentResolution = _currentResolution;

#pragma mark -
#pragma mark Initial Functions

- (void)initialSettings {
//    self.currentZoomRate = 1;
//    self.avgFeaturePoints = 0;
//    self.avgTimeForAck = 0;
//    self.avgTimeForConvert = 0;
//    self.avgTimeForDetect = 0;
//    self.avgTimeForOneFrame = 0;
//    self.avgTimeForPostProcess = 0;
//    self.avgTimeForTrack = 0;
//    self.minFrameRate = 20;
//    self.maxFrameRate = 30;
//    self.imageNo = 0;
//    self.imageProcess = [[ImageProcess alloc] init];
    /*  set the flashLight by default off */
//    self.isFlashOn = false;
//    self.isStabilizationEnable = false;
    /*  set the horizontal stabilization true by default. */
//    self.isHorizontalStable = true;
//    self.motionX = 0;
//    self.motionY = 0;
//    self.isLocked = false;
//    self.beforeLock = false;
//    self.imageOrientation = UIImageOrientationRight;
//    self.hideControls = false;
//    self.correctContentOffset = CGPointZero;
//    [self.scrollView setZoomScale:self.currentZoomRate];
//    self.varQueue = [[NSMutableArray alloc]init];
//    self.maxVariance = 0;
//    self.adjustingFocus = YES;
//    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    self.currentResolution = IP4RESOLUTION;
//    self.featureWindowHeight = 72;
//    self.featureWindowWidth = 128;
//    [self.imageProcess setMaxFeatureNumber:6];
//    [self.scrollView changeImageViewFrame:CGRectMake(0, 0, 540*self.currentZoomRate, 960*self.currentZoomRate)];
//    self.resolutionWidth = 540*self.currentZoomRate;
//    self.resolutionHeight = 960*self.currentZoomRate;
}

- (void) initialControls {
    
    //  Customizing the UISlider
    UIImage *maxImage = [UIImage imageNamed:@EMPTYIMAGE];
    UIImage *minImage = [UIImage imageNamed:@EMPTYIMAGE];
    UIImage *thumbImage = [UIImage imageWithCGImage:[[UIImage imageNamed:@SLIDERTHUMB] CGImage] scale:7 orientation:UIImageOrientationUp];
    [[UISlider appearance] setMaximumTrackImage:maxImage
                                       forState:UIControlStateNormal];
    [[UISlider appearance] setMinimumTrackImage:minImage
                                       forState:UIControlStateNormal];
    [[UISlider appearance] setThumbImage:thumbImage
                                forState:UIControlStateNormal];
    //  set the slider vertical on screen
    CGAffineTransform transformRotate = CGAffineTransformMakeRotation(degreeToRadians(-90));
//    self.zoomSlider.transform = transformRotate;
    
    CGRect bounds = [[UIScreen mainScreen] bounds];
//    [self.scrollView setFrame:bounds];
/*    [self.infoButton.imageView setFrame:
     CGRectMake(0,
                0,
                INFOICONWIDTH,
                INFOICONWIDTH)];*/
/*    [self.infoButton setFrame:
     CGRectMake(bounds.size.width - SLIDERWIDTH + (SLIDERWIDTH - INFOBUTTONWIDTH)/2,
                INFOBUTTONPORTRAITORIENTATIONY,
                INFOBUTTONWIDTH,
                INFOBUTTONWIDTH)];*/
    
/*    [self.sliderBackground setFrame:CGRectMake(bounds.size.width - SLIDERWIDTH + 4,
                                               bounds.size.height/2 - SLIDERHEIGHT/2 + 14,
                                               SLIDERWIDTH - 10,
                                               SLIDERHEIGHT - 27)];*/
    
/*    [self.zoomSlider setFrame:CGRectMake(bounds.size.width - SLIDERWIDTH,
                                         bounds.size.height/2 - SLIDERHEIGHT/2,
                                         SLIDERWIDTH,
                                         SLIDERHEIGHT)];*/
/*    [self.stableDirectionButton setFrame:
     CGRectMake(OUTHBUTTONOFFSET,
                bounds.size.height - BUTTONWIDTH - OUTVBUTTONOFFSET,
                BUTTONWIDTH,
                BUTTONWIDTH)];*/
/*    [self.flashLightButton setFrame:
     CGRectMake(OUTHBUTTONOFFSET + INBUTTONOFFSET + BUTTONWIDTH,
                bounds.size.height - BUTTONWIDTH - OUTVBUTTONOFFSET,
                BUTTONWIDTH,
                BUTTONWIDTH)];*/
/*    [self.screenLockButton setFrame:
     CGRectMake(OUTHBUTTONOFFSET + INBUTTONOFFSET*2 + 2*BUTTONWIDTH,
                bounds.size.height - BUTTONWIDTH - OUTVBUTTONOFFSET,
                BUTTONWIDTH,
                BUTTONWIDTH)];*/
//    self.scrollView.touchDelegate = self;
//    self.iadView.delegate = self;
//    self.iadView.hidden = YES;
}

//  initial capture settings from camera flow
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
//    dispatch_release(queue);
    // Set the video output to store frame in BGRA (It is supposed to be faster)
    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
    [captureOutput setVideoSettings:videoSettings];
    /*And we create a capture session*/
    self.captureSession = [[AVCaptureSession alloc] init];
    
    // for ios 5.0  However, it does not work
    AVCaptureConnection *conn = [captureOutput connectionWithMediaType:AVMediaTypeVideo];
//    conn.videoMinFrameDuration = CMTimeMake(1, self.minFrameRate);
//    conn.videoMaxFrameDuration = CMTimeMake(1, self.maxFrameRate);
//    [conn release];
    
    /*We add input and output*/
    [self.captureSession addInput:captureInput];
    [self.captureSession addOutput:captureOutput];
    /*We use medium quality, ont the iPhone 4 this demo would be laging too much, the conversion in UIImage and CGImage demands too much ressources for a 720p resolution.*/
    [self.captureSession setSessionPreset:self.currentResolution];
    
    /*We start the capture*/
    [self.captureSession startRunning];
    
    // initial date time.
    //self.lastDate = [[NSDate date] retain];
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self initialSettings];
    [self initialControls];
    [self initialCapture];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
