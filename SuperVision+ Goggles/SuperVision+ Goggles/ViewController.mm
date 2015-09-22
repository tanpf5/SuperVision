//
//  ViewController.m
//  SuperVision+ Goggles
//
//  Created by Pengfei Tan on 6/2/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

#import "ViewController.h"

#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

#define RESOLUTION1 AVCaptureSessionPreset1920x1080
#define RESOLUTION2 AVCaptureSessionPreset1280x720
#define RESOLUTION3 AVCaptureSessionPresetiFrame960x540
#define RESOLUTION4 AVCaptureSessionPreset640x480
#define OTHERRESOLUTION RESOLUTION1
#define IP4RESOLUTION RESOLUTION3
#define FREQUENCY 50
//  menu target
#define TARGET_INTERVAL 3
#define TARGETRATIO 2.5
#define ZOOMRATIO 3.5

//  release stablization
#define RELEASE_TIME 30 //frame

//  image offset
#define POINT_WND 20
#define MEAN_STABLE_THRESHOLD_UP_DOWN 1.5//1.5
#define MEAN_STABLE_THRESHOLD_LEFT_RIGHT 1.5//1.5
#define MEAN_NOT_STABLE_THRESHOLD_UP_DOWN 4//4
#define MEAN_NOT_STABLE_THRESHOLD_LEFT_RIGHT 4//4
#define MOVEMENT_UP_DOWN 15//15
#define MOVEMENT_LEFT_RIGHT 15//15
#define MOVEMENT_THRESHOLD_UP_DOWN 50 //50
#define MOVEMENT_THRESHOLD_LEFT_RIGHT 50 //50

@interface ViewController ()

@end

@implementation ViewController

#pragma mark -
#pragma mark Initial Functions

- (void)viewDidLoad {
    [super viewDidLoad];
    [self checkIphone];
    [self firstLaunch];
    [self initialView];
    [self initialSettings];
    [self initialCapture];
    [self initialMotion];
    [self initialNotification];
    [self adjustGyroDraft];
    [self retrieveData];
}

- (void)initialView {
    // hide menu and control
    self.menuHidden = true;
    self.controlHidden = true;
}

- (void)initialSettings {
    self.scrollViewLeft.touchDelegate = self;
    self.scrollViewRight.touchDelegate = self;
    // set initial controls
    self.flashOn = false; // flashlight off
    self.imageModeOn = false; // image mode off
    self.zoomSelected = false; // zoom item don't select
    self.zoomOutModeOn = false; // not in zoom out mode
    // init instance
    self.imageProcess = [[ImageProcess alloc] init];
    self.offsetArray = [[NSMutableArray alloc] init];
    // iPhone 4 need low resolution because of performance
    if ([self isIphone4]) {
        self.currentResolution = IP4RESOLUTION;
        self.featureWindowHeight = 72;
        self.featureWindowWidth = 128;
        [self.imageProcess setMaxFeatureNumber:6];
        if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
            self.resolutionWidth = 540;
            self.resolutionHeight = 960;
        } else {
            self.resolutionWidth = 960;
            self.resolutionHeight = 540;
        }
        self.lockDelay = 8;
        [self setMinimalZoomScale:0.6];
        [self setZoomScale:1];
    } else {
        self.currentResolution = OTHERRESOLUTION;
        self.featureWindowWidth = 284;
        self.featureWindowHeight = 320;
        [self.imageProcess setMaxFeatureNumber:20];
        if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
            self.resolutionWidth = 1080;
            self.resolutionHeight = 1920;
        } else {
            self.resolutionWidth = 1920;
            self.resolutionHeight = 1080;
        }
        self.lockDelay = 10;
        [self setMinimalZoomScale:0.5];
        [self setZoomScale:1];
    }
}

- (void) initialCapture {
    /*And we create a capture session*/
    self.captureSession = [[AVCaptureSession alloc] init];
    
    // setup capture device
    self.captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    /*We setup the input*/
    NSError *error;
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice
                                                                               error:&error];
    if (!error) {
        if ([self.captureSession canAddInput:captureInput]) {
            [self.captureSession addInput:captureInput];
        } else {
            NSLog(@"Video input add-to-session failed");
        }
    } else {
        NSLog(@"Video input creation failed");
    }
    
    /*We setup the output*/
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
    
    [self.captureSession addOutput:captureOutput];
    
    /*We use medium quality, on the iPhone 4 this demo would be laging too much, the conversion in UIImage and CGImage demands too much ressources for a 720p resolution.*/
    [self.captureSession setSessionPreset:self.currentResolution];
    
    if ([self.captureDevice lockForConfiguration:nil] && ![self isIphone4]) {
        self.captureDevice.videoZoomFactor = self.captureDevice.activeFormat.videoZoomFactorUpscaleThreshold;
        [self.captureDevice unlockForConfiguration];
    }
    
    /*We start the capture*/
    [self.captureSession startRunning];
}

- (void)initialMotion {
    //  Magnet
    self.magnetSensor = new SuperVision::MagnetSensor();
    [self startMagnetSensor];
    
    //  Accelerometer
    self.accelerometer = new SuperVision::Accelerometer();
    [self startAccelerometer];
    
    //  Gyro
    self.gyro = new SuperVision::Gyro(); // gyro will start when enter menu
}

- (void)initialNotification {
    /*[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];*/
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)checkIphone {
    if ([self isIpad]) {
        [self alertWithMessage:@"This app is designed to be used on iPhone together with cardboard 3D glasses. Using this app on iPad will not achieve the intended purpose."];
    }
}

- (void)alertWithMessage:(NSString*) message {
    /* open an alert with an OK button */
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"SuperVision+ Goggles"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles: nil];
    [alert show];
}

- (void)firstLaunch {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"hasPerformedFirstLaunch"]) {
        // On first launch, this block will execute
        [self showHelpViewController];
        NSLog(@"firstlaunch");
        // Set the "hasPerformedFirstLaunch" key so this block won't execute again
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasPerformedFirstLaunch"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else {
        // On subsequent launches, this block will execute
        NSLog(@"notfirstlaunch");
    }
}

- (void)adjustGyroDraft {
    _gyro->start();
    NSLog(@"start adjust");
    double delayInSeconds = 60.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        // if the menu is shown, don't stop gyro
        if (self.isMenuHidden) {
             _gyro->stop();
        }
        NSLog(@"finish adjust");
        NSLog(@"x offset = %f, y offset = %f", _gyro->xOffset(), _gyro->yOffset());
    });
}

// the frame of ui change to the true value when view did appear
- (void)viewDidAppear:(BOOL)animated {
    [self.scrollViewLeft changeImageViewFrame:CGRectMake(0, 0, self.resolutionWidth, self.resolutionHeight)];
    [self.scrollViewRight changeImageViewFrame:CGRectMake(0, 0, self.resolutionWidth, self.resolutionHeight)];
    
    /*float viewScale = fmax([ViewController screenWidth] / self.scrollViewLeft.imageView.frame.size.width,
                           [ViewController screenHeight] / self.scrollViewLeft.imageView.frame.size.height);
    
    NSLog(@"screenwidth = %d, width = %f, screenheight = %d, height = %f", [ViewController screenWidth], self.scrollViewLeft.imageView.frame.size.width, [ViewController screenHeight], self.scrollViewLeft.imageView.frame.size.height);
    [self setMinimalZoomScale:viewScale];
    NSLog(@"viewScale = %f", viewScale);*/
}

#pragma mark -
#pragma mark Capture Management

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    if (self.isLocked) {
        return; 
    }
    /*We create an autorelease pool because as we are not in the main_queue our code is
     not executed in the main thread. So we have to create an autorelease pool for the thread we are in*/
    @autoreleasepool {
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        /*Lock the image buffer*/
        CVPixelBufferLockBaseAddress(imageBuffer,0);
        /*Get information about the image*/
        uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        // screen width is 320, image width is 640 / 1920 / 1280
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        // screen height is 480, image height is 480 / 1080 / 720
        size_t height = CVPixelBufferGetHeight(imageBuffer);
        /*Create a CGImageRef from the CVImageBufferRef*/
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        // create a cgimgRef from original source.
        self.cgImageRef = CGBitmapContextCreateImage(context);
        // cut a particle of a cgimage to process fast feature detect
        CGImageRef processCGImageRef = CGImageCreateWithImageInRect(self.cgImageRef, CGRectMake(width/2 - self.featureWindowWidth/2, height/2 - self.featureWindowHeight/2, self.featureWindowWidth, self.featureWindowHeight));
        // we crop a part of cgimage to uiimage to do feature detect and track.
        UIImage *processUIImage = [UIImage imageWithCGImage:processCGImageRef];
        /* release original cgimage */
        CGImageRelease(processCGImageRef);
        /*We release some components*/
        CGContextRelease(context);
        CGColorSpaceRelease(colorSpace);
        
        //UIImage *originalUIImage;
        UIImage *originalUIImage = [UIImage imageWithCGImage:self.cgImageRef];
        // add filter
        if (self.isImageModeOn) {
            originalUIImage = [self addFilter:self.cgImageRef];
        }
        
        //UIImage *originalUIImage = [UIImage imageWithCGImage:self.cgImageRef];
        UIImage *finalUIImage = originalUIImage;
        if (self.isBeforeLocked) {
            [self.imageProcess setCurrentImageMat:processUIImage];
            double var = [self.imageProcess calVariance];
            if (self.imageNo >= self.lockDelay) {
                if ((width != 960) && ([self isIphone4])) {
                    // show to screen.
                    [self adjustForHighResolution];
                    finalUIImage = self.highVarImg;
                    self.locked = true;
                    //[self.scrollViewLeft setContentOffset:self.correctContentOffset animated:NO];
                    //[self.scrollViewRight setContentOffset:self.correctContentOffset animated:NO];
                    self.maxVariance = 0;
                } else {
                    self.locked = true;
                    finalUIImage = self.highVarImg;
                    self.maxVariance = 0;
                }
            }
            // if not reaching lock delay.
            else {
                if ((self.maxVariance < var) || (self.maxVariance == 0)) {
                    self.highVarImg = originalUIImage;
                    self.maxVariance = var;
                }
            }
        }
        // normal state that not locked.
        else {
            float mean_x = 0;
            float mean_y = 0;
            if (self.imageNo == 0) {
                [self.imageProcess setLastImageMat:processUIImage];
            }
            else {
                //  add offset into offset array
                if ([self.offsetArray count] == POINT_WND) {
                    [self.offsetArray removeObjectAtIndex:0];
                }
                // set up images
                [self.imageProcess setCurrentImageMat:processUIImage];
                // calculate motion vector 
                CGPoint motionVector = [self.imageProcess motionEstimation];
                [self.offsetArray addObject:[NSValue valueWithCGPoint:motionVector]];
                
                //  calculate total of offsets
                for (int i = 0; i < [self.offsetArray count]; i++) {
                    NSValue *val = [self.offsetArray objectAtIndex:i];
                    CGPoint p = [val CGPointValue];
                    mean_x += p.x;
                    mean_y += p.y;
                }
                mean_x /= [self.offsetArray count];
                mean_y /= [self.offsetArray count];
                if (fabs(mean_x) < MEAN_STABLE_THRESHOLD_LEFT_RIGHT && fabs(mean_y) < MEAN_STABLE_THRESHOLD_UP_DOWN && !self.isBeingReleased) {
                    if (!self.isStabilizationEnabled) {
                        self.stabilizationEnabled = true;
                        //[self displayMessage:@"start stable"];
                        [self reSet];
                    }
                }
                if (fabs(mean_x) > MEAN_NOT_STABLE_THRESHOLD_LEFT_RIGHT || fabs(mean_y) > MEAN_NOT_STABLE_THRESHOLD_UP_DOWN || fabs(motionVector.x) > MOVEMENT_LEFT_RIGHT / sqrt(self.currentZoomScale) || fabs(motionVector.y) > MOVEMENT_UP_DOWN / sqrt(self.currentZoomScale) || fabs(self.motionX) > MOVEMENT_THRESHOLD_LEFT_RIGHT || fabs(self.motionY) > MOVEMENT_THRESHOLD_UP_DOWN) {
                    if (self.isStabilizationEnabled) {
                        self.stabilizationEnabled = false;
                        //[self displayMessage:@"end stable"];
                        [self startReleaseStabilization];
                    }
                }
            }
            //  if stabilization function is disabled
            if (self.isBeingReleased) {
                CGRect windowBounds = [[UIScreen mainScreen] bounds];
                ++self.increasing;
                float x = self.move_x * (RELEASE_TIME - self.increasing);
                float y = self.move_y * (RELEASE_TIME - self.increasing);
                CGRect resultRect = [self.imageProcess calculateMyCroppedImage:x ypos:y width:width height:height scale:self.currentZoomScale bounds:CGRectMake(0, 0, windowBounds.size.width / 2, windowBounds.size.height)];
                //  cut from original to move the image
                //CGImageRef finalProcessImage = CGImageCreateWithImageInRect(self.cgImageRef, resultRect);
                CGImageRef finalProcessImage = CGImageCreateWithImageInRect([originalUIImage CGImage], resultRect);
                finalUIImage = [UIImage imageWithCGImage:finalProcessImage];
                CGImageRelease(finalProcessImage);
                if (self.increasing == RELEASE_TIME) {
                    [self endReleaseStabilization];
                }
            } else {
                // if statbilization disabled, just use original image
                if (self.isStabilizationEnabled) {
                    if (self.imageNo != 0) {
                        NSValue *val = [self.offsetArray objectAtIndex:[self.offsetArray count] - 1];
                        CGPoint p = [val CGPointValue];
                        self.motionX += p.x;
                        self.motionY += p.y;
                        
                        CGRect windowBounds = [[UIScreen mainScreen] bounds];
                        CGRect resultRect = [self.imageProcess calculateMyCroppedImage:self.motionX ypos:self.motionY width:width height:height scale:self.currentZoomScale bounds:CGRectMake(0, 0, windowBounds.size.width / 2, windowBounds.size.height)];
                        
                        //  cut from original to move the image
                        //CGImageRef finalProcessImage = CGImageCreateWithImageInRect(self.cgImageRef, resultRect);
                        CGImageRef finalProcessImage = CGImageCreateWithImageInRect([originalUIImage CGImage], resultRect);
                        finalUIImage = [UIImage imageWithCGImage:finalProcessImage];
                        CGImageRelease(finalProcessImage);
                    }
                }
            }
        }
        // set image
        [self.scrollViewLeft setImage:finalUIImage];
        [self.scrollViewRight setImage:finalUIImage];
        // We relase the CGImageRef
        CGImageRelease(self.cgImageRef);
        // We unlock the  image buffer
        CVPixelBufferUnlockBaseAddress(imageBuffer,0);
        self.imageNo++;
    } // autorelease finished
    return;
}

- (UIImage *)addFilter:(CGImageRef) cgImageRef {
    // add filter
    CIImage *image = [CIImage imageWithCGImage:self.cgImageRef];
    
    // coler black and white
    CIFilter* photoEffectMono = [CIFilter filterWithName:@"CIPhotoEffectMono"];
    [photoEffectMono setDefaults];
    [photoEffectMono setValue:image forKey:@"inputImage"];
    image = [photoEffectMono valueForKey:@"outputImage"];
    
    // coler invert filter
    CIFilter* colorInvertFilter = [CIFilter filterWithName:@"CIColorInvert"];
    [colorInvertFilter setDefaults];
    [colorInvertFilter setValue:image forKey:@"inputImage"];
    image = [colorInvertFilter valueForKey:@"outputImage"];
    
    // color control filter
    CIFilter* colorControlsFilter = [CIFilter filterWithName:@"CIColorControls"];
    [colorControlsFilter setDefaults];
    [colorControlsFilter setValue:@5 forKey:@"inputContrast"];
    [colorControlsFilter setValue:image forKey:@"inputImage"];
    image = [colorControlsFilter valueForKey:@"outputImage"];
    return [self makeUIImageFromCIImage:image];
}

-(UIImage*)makeUIImageFromCIImage:(CIImage*)ciImage
{
    // create the CIContext instance, note that this must be done after _videoPreviewView is properly set up
    EAGLContext *_eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    CIContext *cicontext = [CIContext contextWithEAGLContext:_eaglContext options:@{kCIContextWorkingColorSpace : [NSNull null]}];
    //CIContext *cicontext = [CIContext contextWithOptions:nil];
    // finally!
    UIImage * returnImage;
    CGImageRef processedCGImage = [cicontext createCGImage:ciImage fromRect:[ciImage extent]];
    returnImage = [UIImage imageWithCGImage:processedCGImage];
    CGImageRelease(processedCGImage);
    return returnImage;
}

- (void)startReleaseStabilization {
    self.beingReleased = true;
    self.increasing = 0;
    self.move_x = self.motionX / RELEASE_TIME;
    self.move_y = self.motionY / RELEASE_TIME;
}

- (void)endReleaseStabilization {
    self.beingReleased = false;
}

//  reSet all settings
- (void) reSet {
    self.motionX = 0;
    self.motionY = 0;
    self.imageNo = 0;
    self.adjustingFocus = NO;
}

- (void) adjustForHighResolution {
    /* needs rescaling sicne resolution changed! for
     iphone4 and 4s other than iPhone5. */
    float adjustScale = 540.0 / self.resolutionWidth;
    //  iPhone4 needs further more zooming scale, no idea why!
    float newMax = self.scrollViewLeft.maximumZoomScale * adjustScale;
    float newMin = self.scrollViewLeft.minimumZoomScale * adjustScale;
    [self.scrollViewLeft setMaximumZoomScale:newMax];
    [self.scrollViewRight setMaximumZoomScale:newMax];
    [self.scrollViewLeft setMinimumZoomScale:newMin];
    [self.scrollViewRight setMinimumZoomScale:newMin];
    self.currentZoomScale = self.scrollViewLeft.zoomScale * adjustScale;
    self.scrollViewLeft.zoomScale = self.currentZoomScale;
    self.scrollViewRight.zoomScale = self.currentZoomScale;
    [self.zoomSliderLeft setMaximumValue:newMax];
    [self.zoomSliderRight setMaximumValue:newMax];
    [self.zoomSliderLeft setMinimumValue:newMin];
    [self.zoomSliderRight setMinimumValue:newMin];
    [self.zoomSliderLeft setValue:self.currentZoomScale animated:NO];
    [self.zoomSliderRight setValue:self.currentZoomScale animated:NO];
    [self.scrollViewLeft changeImageViewFrame:CGRectMake(0, 0, self.resolutionHeight * self.currentZoomScale, self.resolutionWidth * self.currentZoomScale)];
    [self.scrollViewRight changeImageViewFrame:CGRectMake(0, 0, self.resolutionHeight * self.currentZoomScale, self.resolutionWidth * self.currentZoomScale)];
}

- (void) adjustForLowResolution {
    /* needs rescaling sicne resolution changed! for
     iphone4 and 4s other than iPhone5. */
    float adjustScale = self.resolutionWidth / 540.0;
    float newMax = self.scrollViewLeft.maximumZoomScale * adjustScale;
    float newMin = self.scrollViewLeft.minimumZoomScale * adjustScale;
    [self.scrollViewLeft setMaximumZoomScale:newMax];
    [self.scrollViewRight setMaximumZoomScale:newMax];
    [self.scrollViewLeft setMinimumZoomScale:newMin];
    [self.scrollViewRight setMinimumZoomScale:newMin];
    self.currentZoomScale = self.scrollViewLeft.zoomScale * adjustScale;
    self.scrollViewLeft.zoomScale = self.currentZoomScale;
    self.scrollViewRight.zoomScale = self.currentZoomScale;
    [self.zoomSliderLeft setMaximumValue:newMax];
    [self.zoomSliderRight setMaximumValue:newMax];
    [self.zoomSliderLeft setMinimumValue:newMin];
    [self.zoomSliderRight setMinimumValue:newMin];
    [self.zoomSliderLeft setValue:self.currentZoomScale animated:NO];
    [self.zoomSliderRight setValue:self.currentZoomScale animated:NO];

    [self.scrollViewLeft changeImageViewFrame:CGRectMake(0, 0, 960 * self.currentZoomScale, 540 * self.currentZoomScale)];
    [self.scrollViewRight changeImageViewFrame:CGRectMake(0, 0, 960 * self.currentZoomScale, 540 * self.currentZoomScale)];
}

- (void)checkFocusChange {
    NSUInteger level = [self getLevel];
    //[self displayMessage:[NSString stringWithFormat:@"dis = %lu, lens = %.03f", (unsigned long)level, self.captureDevice.lensPosition]];
    if (level != self.focusLevel) {
        [self endFocusLevelEvent];
        [self beginFocusLevelEvent];
    }
}

- (float)getOffset {
    // can extend to all kinds of devices
    /*if ([self isIphone5]) {
        return 0.14;
    }*/
    return 0.16;
}

- (NSUInteger)getLevel {
    float offset = [self getOffset];
    float g = _accelerometer->getCurrent();
    float lens = self.captureDevice.lensPosition - offset * g;
    float distance = 1 / (-0.3929 * lens + 0.2986);
    if (distance < 0 || distance > 360) {
        distance = 360;
    }
    return distance / 1;
}

#pragma mark -
#pragma mark Basic Controls
- (void) setMinimalZoomScale: (float)minScale {
    self.minZoomScale = minScale;
    self.scrollViewLeft.minimumZoomScale = minScale;
    self.scrollViewRight.minimumZoomScale = minScale;
    [self.zoomSliderLeft setMinimumValue:minScale];
    [self.zoomSliderRight setMinimumValue:minScale];
}

- (void)setZoomScale:(float)ZoomScale{
    self.currentZoomScale = ZoomScale;
    [self.scrollViewLeft setZoomScale:ZoomScale animated:YES];
    [self.scrollViewRight setZoomScale:ZoomScale animated:YES];
    [self.zoomSliderLeft setValue:ZoomScale animated:YES];
    [self.zoomSliderRight setValue:ZoomScale animated:YES];
}

- (IBAction)ZoomScaleChanged:(SVSlider *)slider {
    [self setZoomScale:slider.value];
}

- (IBAction)flashTapped {
    if (self.isFlashOn) {
        [self turnFlashOff];
        [self.flashItemLeft setSelected:NO];
        [self.flashItemRight setSelected:NO];
        [self.flashButtonLeft setSelected:NO];
        [self.flashButtonRight setSelected:NO];
        [self displayMessage:@"Turned off"];
    } else {
        [self turnFlashOn];
        [self.flashItemLeft setSelected:YES];
        [self.flashItemRight setSelected:YES];
        [self.flashButtonLeft setSelected:YES];
        [self.flashButtonRight setSelected:YES];
        [self displayMessage:@"Turned on"];
    }
    self.flashOn = !_flashOn;
}

- (void)turnFlashOn {
    if ([self.captureDevice hasTorch]) {
        [self.captureDevice lockForConfiguration:nil];
        //  turn on
        [self.captureDevice setTorchMode:AVCaptureTorchModeOn];
        [MobClick beginEvent:@"FlashlightOn"];
        [self.captureDevice unlockForConfiguration];
    }
}

- (void)turnFlashOff {
    if ([self.captureDevice hasTorch]) {
        [self.captureDevice lockForConfiguration:nil];
        //  turn off
        [MobClick endEvent:@"FlashlightOn"];
        [self.captureDevice setTorchMode:AVCaptureTorchModeOff];
        [self.captureDevice unlockForConfiguration];
    }
}

- (IBAction)imageModeTapped {
    if (self.isImageModeOn) {
        [self.imageItemLeft setSelected:NO];
        [self.imageItemRight setSelected:NO];
        [self.imageButtonLeft setSelected:NO];
        [self.imageButtonRight setSelected:NO];
        [self displayMessage:@"Color"];
        [self messageChangeColor:[UIColor blackColor]];
        [MobClick endEvent:@"ImageModeOn" label:@"Enh-Inv"];
    } else {
        [MobClick beginEvent:@"ImageModeOn" label:@"Enh-Inv"];
        [self.imageItemLeft setSelected:YES];
        [self.imageItemRight setSelected:YES];
        [self.imageButtonLeft setSelected:YES];
        [self.imageButtonRight setSelected:YES];
        [self displayMessage:@"Black and white"];
        [self messageChangeColor:[UIColor whiteColor]];
    }
    self.imageModeOn = !_imageModeOn;
}

- (void) messageChangeText:(NSString *)text {
    self.messageLeft.text = text;
    self.messageRight.text = text;
}

- (void) messageChangeColor:(UIColor *)color {
    self.messageLeft.textColor = color;
    self.messageRight.textColor = color;
}

- (IBAction)infoTapped {
    [self showHelpViewController];
}

- (IBAction)freezeScreen {
    // unlock screen
    if (self.isLocked) {
        self.beforeLocked = false;
        self.locked = false;
        [self reSet];
        if ([self isIphone4]) {
            self.currentResolution = IP4RESOLUTION;
            [self.captureSession beginConfiguration];
            [self.captureSession setSessionPreset:self.currentResolution];
            [self.captureSession commitConfiguration];
            [self recoverFlash];
            [self adjustForLowResolution];
            self.resolutionWidth = 540;
            self.resolutionHeight = 960;
        }
    }
    // lock screen
    else {
        self.locked = false;
        self.beforeLocked = true;
        [self reSet];
        if ([self isIphone4]) {
            //  1080p
            self.currentResolution = OTHERRESOLUTION;
            self.resolutionWidth = 1080;
            self.resolutionHeight= 1920;
            //  if 1080p not available set 720p
            if (![self.captureSession canSetSessionPreset:self.currentResolution]) {
                self.currentResolution = RESOLUTION2;
                self.resolutionWidth = 720;
                self.resolutionHeight = 1280;
            }
            [self.captureSession beginConfiguration];
            [self.captureSession setSessionPreset:self.currentResolution];
            [self.captureSession commitConfiguration];
            [self recoverFlash];
            self.correctContentOffset = self.scrollViewLeft.contentOffset;
        }
    }
}

- (void) recoverFlash {
    if (self.isFlashOn)
        [self turnFlashOn];
    else
        [self turnFlashOff];
}

- (void)showHelpViewController
{
    CGRect screenBounds = self.view.bounds;
    CGRect fromFrame = CGRectMake(0.0f, screenBounds.size.height, screenBounds.size.width, screenBounds.size.height);
    CGRect toFrame = screenBounds;
    
    self.helpViewController = [[HelpViewController alloc] initWithNibName:@"HelpViewController" bundle:nil];
    [self addChildViewController:self.helpViewController];
    self.helpViewController.view.frame = fromFrame;
    [self.view addSubview:self.helpViewController.view];
    [UIView animateWithDuration:0.3f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.helpViewController.view.frame = toFrame;
                     } completion:^(BOOL finished){
                         [self.helpViewController didMoveToParentViewController:self];
                     }];
}


#pragma mark - 
#pragma mark UI Display Controls

- (void)hideMenuAndControl {
    [self hideMenu];
    [self hideControl];
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


- (void)showMenuExceptZoom {
    // menu
    [self showMenu];
    // zoom
    [self hideZoom];
}

- (void)hideMenuExceptZoom {
    // menu
    [self hideMenu];
    // zoom
    [self showZoom];
}

- (void)showMessage {
    [self.messageLeft setHidden:NO];
    [self.messageRight setHidden:NO];
}

- (void)hideMessage {
    [self.messageLeft setHidden:YES];
    [self.messageRight setHidden:YES];
}

- (void)showMenu {
    [self.zoomItemLeft setHidden:NO];
    [self.zoomItemRight setHidden:NO];
    [self.flashItemLeft setHidden:NO];
    [self.flashItemRight setHidden:NO];
    [self.imageItemLeft setHidden:NO];
    [self.imageItemRight setHidden:NO];
    [self.exitItemLeft setHidden:NO];
    [self.exitItemRight setHidden:NO];
    [self showMessage];
}

- (void)hideMenu {
    [self.zoomItemLeft setHidden:YES];
    [self.zoomItemRight setHidden:YES];
    [self.flashItemLeft setHidden:YES];
    [self.flashItemRight setHidden:YES];
    [self.imageItemLeft setHidden:YES];
    [self.imageItemRight setHidden:YES];
    [self.exitItemLeft setHidden:YES];
    [self.exitItemRight setHidden:YES];
    [self hideMessage];
}

- (void)showZoom {
    //  Zoom sliders
    [self.sliderBackgroundLeft setHidden:NO];
    [self.sliderBackgroundRight setHidden:NO];
    [self.zoomSliderLeft setHidden:NO];
    [self.zoomSliderRight setHidden:NO];
}

- (void)hideZoom {
    //  Zoom sliders
    [self.sliderBackgroundLeft setHidden:YES];
    [self.sliderBackgroundRight setHidden:YES];
    [self.zoomSliderLeft setHidden:YES];
    [self.zoomSliderRight setHidden:YES];
}

- (void)displayMessage:(NSString *)s {
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
#pragma mark Menu Control

- (void) menuControl {
    if (self.isMenuHidden) {
        //  menu display
        [self enterMenu];
        return ;
    }
    //  zoom in/out
    if (self.isZoomTargetted) {
        [self freezeScreen];
        if (self.isZoomSelected) {
            self.zoomSelected = false;
            [self stopGyroUpAndDown];
            [self startGyroLeftAndRight];
            [self showMenuExceptZoom];
            [self exitMenu];
        } else {
            self.zoomSelected = true;
            [self hideMenuExceptZoom];
            [self stopGyroLeftAndRight];
            [self startGyroUpAndDown];
        }
        return ;
    }
     //  flashlight
     if (self.isFlashTargetted) {
         [self flashTapped];
         [self exitMenu];
         return ;
     }
     //  image mode
     if (self.isImageTargetted) {
         [self imageModeTapped];
         [self exitMenu];
         return ;
     }
     //  exit
     if (self.isExitTargetted) {
         [self exitMenu];
     return ;
     }
}

- (void) zoomControl {
    if (self.isZoomOutModeOn) {
        [self displayMessage:@"Normal Mode"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.zoomSliderLeft setValue:self.currentZoomScale animated:YES];
            [self.zoomSliderRight setValue:self.currentZoomScale animated:YES];
            [self.scrollViewLeft setZoomScale:self.currentZoomScale animated:YES];
            [self.scrollViewRight setZoomScale:self.currentZoomScale animated:YES];
        });
        
    } else {
        [self displayMessage:@"Zoom Mode"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.zoomSliderLeft setValue:self.minZoomScale animated:YES];
            [self.zoomSliderRight setValue:self.minZoomScale animated:YES];
            [self.scrollViewLeft setZoomScale:self.minZoomScale animated:YES];
            [self.scrollViewRight setZoomScale:self.minZoomScale animated:YES];
            // tap zoom out umeng event
            [MobClick event:@"TapZoomOut"];
        });
    }
    self.zoomOutModeOn = !_zoomOutModeOn;
}

- (void)enterMenu {
    // stop acc
    [self stopAccelerometer];
    // start gyro
    [self startGyro];
    [self resetTargetCursor];
    self.menuHidden = false;
}

- (void)exitMenu {
    self.menuHidden = true;
    [self hideMenu];
    // stop gyro
    [self stopGyro];
    // start acc again
    [self startAccelerometer];
}

- (void) resetTargetCursor {
    // target at zoom
    [self messageChangeText:@"Zoom"];
    self.zoomTargetted = true;
    self.flashTargetted = false;
    self.imageTargetted = false;
    self.exitTargetted = false;
    self.targetCursor = 1.0;
}

#pragma mark -
#pragma mark Motion Control

- (void)startMagnetSensor {
    _magnetSensor->start();
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(magneticTriggerPressed)
                                                 name:SuperVision::MagnetSensorTriggerDidPressNotification
                                               object:nil];
}

- (void)stopMagnetSensor {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SuperVision::MagnetSensorTriggerDidPressNotification object:nil];
    _magnetSensor->stop();
}

- (void)startAccelerometer {
    _accelerometer->start();
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(doubleTapTriggered)
                                                 name:SuperVision::AccelerometerDidDoubleTapNotification
                                               object:nil];
}

- (void)stopAccelerometer {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SuperVision::AccelerometerDidDoubleTapNotification object:nil];
    _accelerometer->stop();
}

- (void)startGyro {
    _gyro->start();
    [self startGyroLeftAndRight];
}

- (void)stopGyro {
    [self stopGyroLeftAndRight];
    _gyro->stop();
}

- (void)startGyroLeftAndRight {
    _gyro->startLeftAndRight();
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(targetCursorChanged:)
                                                 name:SuperVision::GyroDidMoveLeftAndRightNotification
                                               object:nil];
}

- (void)stopGyroLeftAndRight {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SuperVision::GyroDidMoveLeftAndRightNotification object:nil];
    _gyro->stopLeftAndRight();
}

- (void)startGyroUpAndDown {
    _gyro->startUpAndDown();
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(zoomSliderChanged:)
                                                 name:SuperVision::GyroDidMoveUpAndDownNotification
                                               object:nil];
}

- (void)stopGyroUpAndDown {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SuperVision::GyroDidMoveUpAndDownNotification object:nil];
    _gyro->stopUpAndDown();
}

- (void)doubleTapTriggered {
    if (self.isMenuHidden && self.isControlHidden) {
        [self zoomControl];
    }
}

- (void)magneticTriggerPressed {
    if (self.isControlHidden) {
        [self menuControl];
    }
}

- (void)zoomSliderChanged:(NSNotification *) notification {
    //[self displayMessage:@"up and down"];
    NSNumber * movement = [notification.userInfo objectForKey:@"Value"];
    float scale = self.currentZoomScale - movement.floatValue * ZOOMRATIO;
    if (scale > 8) {
        scale = 8;
    } else if (scale < 0.5) {
        scale = 0.5;
    }
    [self setZoomScale:scale];
}

- (void)targetCursorChanged:(NSNotification *) notification {
    //[self showMessage:@"left and right"];
    NSNumber * movement = [notification.userInfo objectForKey:@"Value"];
    // left +x, right -x
    float scale = self.targetCursor - [movement floatValue] * TARGETRATIO;
    if (scale >= 4 * TARGET_INTERVAL) {
        scale = 4 * TARGET_INTERVAL;
    } else if (scale < 0) {
        scale = 0;
    }
    
    if (scale >= 0 && scale < TARGET_INTERVAL) {
        self.zoomTargetted = true;
        self.flashTargetted = false;
        self.imageTargetted = false;
        self.exitTargetted = false;
    } else if (scale >= TARGET_INTERVAL && scale < 2 * TARGET_INTERVAL) {
        self.zoomTargetted = false;
        self.flashTargetted = true;
        self.imageTargetted = false;
        self.exitTargetted = false;
    } else if (scale >= 2 * TARGET_INTERVAL && scale < 3 * TARGET_INTERVAL) {
        self.zoomTargetted = false;
        self.flashTargetted = false;
        self.imageTargetted = true;
        self.exitTargetted = false;
    } else if (scale >= 3 * TARGET_INTERVAL && scale <= 4 * TARGET_INTERVAL) {
        self.zoomTargetted = false;
        self.flashTargetted = false;
        self.imageTargetted = false;
        self.exitTargetted = true;
    }
    self.targetCursor = scale;
}


#pragma mark -
#pragma mark SVScrollView TouchDelegate
- (void)scrollViewDoubleTapped:(UIGestureRecognizer *)gesture {
    self.controlHidden = !_controlHidden;
}

#pragma mark -
#pragma mark Helper Functions

- (BOOL)isIphone4 {
    return [AppDelegate isIphone4];
}

- (BOOL)isIpad {
    return [AppDelegate isIpad];
}

// hide status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

+ (NSInteger)screenWidth {
    if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        return ceil(CGRectGetHeight([[UIScreen mainScreen] bounds]) / 2);
    } else {
        return ceil(CGRectGetWidth([[UIScreen mainScreen] bounds]) / 2);
    }
}

+ (NSInteger)screenHeight {
    if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        return CGRectGetWidth([[UIScreen mainScreen] bounds]);
    } else {
        return CGRectGetHeight([[UIScreen mainScreen] bounds]);
    }
}

#pragma mark -
#pragma mark Setters and Getters

- (void)setControlHidden:(BOOL)controlHidden {
    _controlHidden = controlHidden;
    if (controlHidden) {
        [self hideControl];
    } else {
        [self showControl];
    }
}

- (void)setMenuHidden:(BOOL)menuHidden {
    _menuHidden = menuHidden;
    if (menuHidden) {
        [self hideMenu];
    } else {
        [self showMenuExceptZoom];
    }
}

- (void)setZoomTargetted:(BOOL)zoomTargetted {
    _zoomTargetted = zoomTargetted;
    if (_zoomTargetted) {
        // set message Zoom
        [self messageChangeText:@"Zoom"];
        // zoom
        [self.zoomItemLeft setBackgroundColor:[UIColor redColor]];
        [self.zoomItemRight setBackgroundColor:[UIColor redColor]];
        self.zoomItemLeft.layer.borderColor = [[UIColor redColor] CGColor];
        self.zoomItemRight.layer.borderColor = [[UIColor redColor] CGColor];
    } else {
        [self.zoomItemLeft setBackgroundColor:nil];
        [self.zoomItemRight setBackgroundColor:nil];
        self.zoomItemLeft.layer.borderColor = nil;
        self.zoomItemRight.layer.borderColor = nil;
    }
}

- (void)setFlashTargetted:(BOOL)flashTargetted {
    _flashTargetted = flashTargetted;
    if (_flashTargetted) {
        // set message Flashlight
        [self messageChangeText:@"Flashlight"];
        // flash
        [self.flashItemLeft setBackgroundColor:[UIColor redColor]];
        [self.flashItemRight setBackgroundColor:[UIColor redColor]];
        self.flashItemLeft.layer.borderColor = [[UIColor redColor] CGColor];
        self.flashItemRight.layer.borderColor = [[UIColor redColor] CGColor];
    } else {
        // flash
        [self.flashItemLeft setBackgroundColor:nil];
        [self.flashItemRight setBackgroundColor:nil];
        self.flashItemLeft.layer.borderColor = nil;
        self.flashItemRight.layer.borderColor = nil;
    }
}

- (void)setImageTargetted:(BOOL)imageTargetted {
    _imageTargetted = imageTargetted;
    if (_imageTargetted) {
        // set message Image Mode
        [self messageChangeText:@"Image Mode"];
        // image
        [self.imageItemLeft setBackgroundColor:[UIColor redColor]];
        [self.imageItemRight setBackgroundColor:[UIColor redColor]];
        self.imageItemLeft.layer.borderColor = [[UIColor redColor] CGColor];
        self.imageItemRight.layer.borderColor = [[UIColor redColor] CGColor];
    } else {
        // image
        [self.imageItemLeft setBackgroundColor:nil];
        [self.imageItemRight setBackgroundColor:nil];
        self.imageItemLeft.layer.borderColor = nil;
        self.imageItemRight.layer.borderColor = nil;
    }
}

- (void)setExitTargetted:(BOOL)exitTargetted {
    _exitTargetted = exitTargetted;
    if (_exitTargetted) {
        // set message Exit
        [self messageChangeText:@"Exit"];
        // exit
        [self.exitItemLeft setBackgroundColor:[UIColor redColor]];
        [self.exitItemRight setBackgroundColor:[UIColor redColor]];
        self.exitItemLeft.layer.borderColor = [[UIColor redColor] CGColor];
        self.exitItemRight.layer.borderColor = [[UIColor redColor] CGColor];
    } else {
        // exit
        [self.exitItemLeft setBackgroundColor:nil];
        [self.exitItemRight setBackgroundColor:nil];
        self.exitItemLeft.layer.borderColor = nil;
        self.exitItemRight.layer.borderColor = nil;
    }
}


#pragma mark -
#pragma mark System Notification Methods

- (void)applicationWillResignActive {
    if (!self.isMenuHidden) {
        self.menuHidden = true;
        [self stopGyro];
    }
    if (!self.isControlHidden) {
        self.controlHidden = true;
    }
    if (self.flashOn) {
        [self flashTapped];
    }
    if (self.imageModeOn) {
        [MobClick endEvent:@"ImageModeOn" label:@"Enh-Inv"];
    }
    // zoom exit umeng event
    NSString *value = [NSString stringWithFormat:@"%ld", (long)ceil(self.currentZoomScale)];
    [MobClick event:@"ZoomAtExit" label:value];
    // stop the timer for focus level
    if ([self hasLensPosition]) {
        [self stopTimer];
        [self endFocusLevelEvent];
    }
}

- (void)applicationDidBecomeActive {
    if (self.imageModeOn) {
        [MobClick beginEvent:@"ImageModeOn" label:@"Enh-Inv"];
    }
    // set up a timer for focus level
    if ([self hasLensPosition]) {
        [self startTimer];
        [self beginFocusLevelEvent];
    }
    //[self recoverFlash];
}

- (void)applicationDidEnterBackground {
    [self stopPlaying];
    [self stopAccelerometer];
    [self stopMagnetSensor];
    [self storeData];
}

- (void)applicationWillEnterForeground {
    [self startMagnetSensor];
    [self startAccelerometer];
    [self resumePlaying];
}

- (void) stopPlaying {
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
    [self.captureSession stopRunning];
}

- (void) resumePlaying {
    [self.captureSession startRunning];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
}

- (void)startTimer {
    self.repeatTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(checkFocusChange) userInfo:nil repeats:YES];
}

- (void)beginFocusLevelEvent {
    self.focusLevelTimer = [NSDate date];
    self.focusLevel = [self getLevel];
    NSString *label = [NSString stringWithFormat:@"%ld", (long)self.focusLevel];
    [MobClick beginEvent:@"FocusLevel" label:label];
}

- (void)stopTimer {
    if (self.repeatTimer) {
        [self.repeatTimer invalidate];
        self.repeatTimer = nil;
    }
}

- (void)endFocusLevelEvent {
    float seconds = [[NSDate date] timeIntervalSinceDate:self.focusLevelTimer];
    if (seconds >= 3) {
        NSString *label = [NSString stringWithFormat:@"%ld", (long)self.focusLevel];
        [MobClick endEvent:@"FocusLevel" label:label];
    }
}

- (BOOL)hasLensPosition {
    if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        return false;
    }
    return true;
}

#pragma mark -
#pragma mark System Data Storage

- (void)storeData {
    NSMutableDictionary *svGoggles = [[NSMutableDictionary alloc] init];
    [svGoggles setObject:[NSString stringWithFormat:@"%f", self.currentZoomScale] forKey:@"Zoom Scale"];
    [svGoggles setObject:[NSString stringWithFormat:@"%f", _gyro->xOffset()] forKey:@"X Offset"];
    [svGoggles setObject:[NSString stringWithFormat:@"%f", _gyro->yOffset()] forKey:@"Y Offset"];
    [svGoggles setObject:[NSString stringWithFormat:@"%d", _gyro->xNumber()] forKey:@"X Number"];
    [svGoggles setObject:[NSString stringWithFormat:@"%d", _gyro->yNumber()] forKey:@"Y Number"];
    [[NSUserDefaults standardUserDefaults] setObject:svGoggles forKey:@"SVGoggles"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)retrieveData {
    NSDictionary *svGoggles = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"SVGoggles"];
    if (svGoggles) {
        [self setZoomScale:[[svGoggles objectForKey:@"Zoom Scale"] floatValue]];
        _gyro->setXOffset([[svGoggles objectForKey:@"X Offset"] floatValue]);
        _gyro->setYOffset([[svGoggles objectForKey:@"Y Offset"] floatValue]);
        _gyro->setXNumber([[svGoggles objectForKey:@"X Number"] intValue]);
        _gyro->setYNumber([[svGoggles objectForKey:@"Y Number"] intValue]);
    }
}

@end
