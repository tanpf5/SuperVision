//
//  ViewController.m
//  SuperVision+ Goggles
//
//  Created by Pengfei Tan on 6/2/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

#import "ViewController.h"

#pragma mark - resolution settings

#define ScreenWidth      ceil(CGRectGetWidth([[UIScreen mainScreen] bounds])/2)
#define ScreenHeight     CGRectGetHeight([[UIScreen mainScreen] bounds])

#define RESOLUTION1 AVCaptureSessionPreset1920x1080
#define RESOLUTION2 AVCaptureSessionPreset1280x720
#define RESOLUTION3 AVCaptureSessionPresetiFrame960x540
#define RESOLUTION4 AVCaptureSessionPreset640x480
#define OTHERRESOLUTION RESOLUTION1
#define IP4RESOLUTION RESOLUTION3
#define FREQUENCY 50
//  menu target
#define TARGET_INTERVAL 4
#define TARGETRATIO 3

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
//  User Interface
// control
@synthesize isMenuHidden; // all menu items
@synthesize isControlHidden; // all buttons
@synthesize isFlashOn;
@synthesize isImageModeOn;
// menu target control
@synthesize isZoomTargetted;
@synthesize isFlashTargetted;
@synthesize isImageTargetted;
@synthesize isExitTargetted;
@synthesize targetCursor;
@synthesize zoomIsSelected;


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
@synthesize currentZoomScale;

// messages
@synthesize messageLeft;
@synthesize messageRight;

//  HelperView
@synthesize helpViewController;

//  Capture
@synthesize captureSession;
@synthesize isLocked;
@synthesize beforeLock;
@synthesize imageNo;
@synthesize motionX;
@synthesize motionY;
@synthesize featureWindowHeight;
@synthesize featureWindowWidth;
@synthesize highVarImg;
@synthesize maxVariance;
@synthesize maxVarImg;
@synthesize adjustingFocus;
@synthesize lockDelay;
@synthesize offsetArray;
//  Stablization
@synthesize isStabilizationEnable;
@synthesize releasing;
@synthesize increasing;
@synthesize move_x;
@synthesize move_y;

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
    [self setZoomScale:1];
    // set initial controls
    self.isFlashOn = false;
    self.isImageModeOn = false;
    self.zoomIsSelected = false;
    [self.scrollViewLeft changeImageViewFrame:CGRectMake(0, 0, 1920, 1080)];
    [self.scrollViewRight changeImageViewFrame:CGRectMake(0, 0, 1920, 1080)];
    float viewScale = fmax(ScreenWidth / self.scrollViewLeft.imageView.frame.size.width,
                           ScreenHeight / self.scrollViewLeft.imageView.frame.size.height);
    
    [self setMinimalZoomScale:viewScale];
    self.imageProcess = [[ImageProcess alloc] init];
    self.offsetArray = [[NSMutableArray alloc] init];
    if ([self isIphone4]) {
        self.currentResolution = IP4RESOLUTION;
        self.featureWindowHeight = 72;
        self.featureWindowWidth = 128;
        [self.imageProcess setMaxFeatureNumber:6];
        //[self.scrollView changeImageViewFrame:CGRectMake(0, 0, 540*self.currentZoomRate, 960*self.currentZoomRate)];
        //[self.scrollViewRight changeImageViewFrame:CGRectMake(0, 0, 540*self.currentZoomRate, 960*self.currentZoomRate)];
        //self.resolutionWidth = 540*self.currentZoomRate;
        //self.resolutionHeight = 960*self.currentZoomRate;
        self.lockDelay = 10;
    } else {
        self.currentResolution = OTHERRESOLUTION;
        [self.scrollViewLeft setZoomScale:1];
        [self.scrollViewRight setZoomScale:1];
        [self.zoomSliderRight setValue:1];
        [self.zoomSliderRight setValue:1];
        self.featureWindowWidth = 284;
        self.featureWindowHeight = 320;
        [self.imageProcess setMaxFeatureNumber:20];
        //[self.scrollViewLeft changeImageViewFrame:CGRectMake(0, 0, 1080, 1920)];
        //[self.scrollViewRight changeImageViewFrame:CGRectMake(0, 0, 1080, 1920)];
        //self.resolutionWidth = 1080;
        //self.resolutionHeight = 1920;
        self.lockDelay = 10;
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
    //  Magnet
    self.magnetSensor = new SuperVision::MagnetSensor();
    [self startMagnetSensor];
    
    //  Accelerometer
    self.accelerometer = new SuperVision::Accelerometer();
    [self startAccelerometer];
    
    //  Gyro
    self.gyro = new SuperVision::Gyro();
}

#pragma mark -
#pragma mark Capture Management


- (UIImage *)addFilter:(CGImageRef) originalCGImage {
    // add filter
    CIImage *image = [CIImage imageWithCGImage:originalCGImage];
    CIContext *cicontext = [CIContext contextWithOptions:nil];
    
    //image = [CIFilter filterWithName:@"CIColorControls" keysAndValues:kCIInputImageKey, image, @"inputBrightness", [NSNumber numberWithFloat:0.0], @"inputContrast", [NSNumber numberWithFloat:2], @"inputSaturation", [NSNumber numberWithFloat:0.3], nil].outputImage;
    image = [CIFilter filterWithName:@"CIExposureAdjust" keysAndValues:kCIInputImageKey, image, @"inputEV", [NSNumber numberWithFloat:1], nil].outputImage;
    //image = [CIFilter filterWithName:@"CIColorInvert" keysAndValues:kCIInputImageKey, image, nil].outputImage;
    
    /*CIFilter* photoEffectMonoFilter = [CIFilter filterWithName:@"CIPhotoEffectNoir"];
     [photoEffectMonoFilter setDefaults];
     [photoEffectMonoFilter setValue:image forKey:@"inputImage"];
     image = [photoEffectMonoFilter valueForKey:@"outputImage"];*/
    
    CIFilter* colorInvertFilter = [CIFilter filterWithName:@"CIColorInvert"];
    [colorInvertFilter setDefaults];
    [colorInvertFilter setValue:image forKey:@"inputImage"];
    image = [colorInvertFilter valueForKey:@"outputImage"];
    
    CIFilter* colorControlsFilter = [CIFilter filterWithName:@"CIColorControls"];
    [colorControlsFilter setDefaults];
    [colorControlsFilter setValue:@5 forKey:@"inputContrast"];
    //[colorControlsFilter setValue:@0 forKey:@"inputBrightness"];
    [colorControlsFilter setValue:@0 forKey:@"inputSaturation"];
    [colorControlsFilter setValue:image forKey:@"inputImage"];
    image = [colorControlsFilter valueForKey:@"outputImage"];
    
    CGImageRef cgimg = [cicontext createCGImage:image fromRect:[image extent]];
    UIImage *uiImage = [UIImage imageWithCGImage:cgimg];
    
    CGImageRelease(cgimg);
    return uiImage;
}

- (void)startReleaseStabilization {
    self.releasing = true;
    self.increasing = 0;
    self.move_x = self.motionX / RELEASE_TIME;
    self.move_y = self.motionY / RELEASE_TIME;
}

- (void)endReleaseStabilization {
    self.releasing = false;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    if (self.isLocked) {
        return;
    }
    
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
    CGImageRef originalCGImage = CGBitmapContextCreateImage(context);
    
    UIImage *originalUIImage;
    if (self.isImageModeOn) {
        originalUIImage = [self addFilter:originalCGImage];
    } else {
        originalUIImage = [UIImage imageWithCGImage:originalCGImage];
    }
    
    
    /*We display the result on the image view (We need to change the orientation of the image so that the video is displayed correctly).
     Same thing as for the CALayer we are not in the main thread so ...*/
    
    /*We release some components*/
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    if (self.beforeLock) {
        
        CGImageRef processCGImageRef = CGImageCreateWithImageInRect(originalCGImage, CGRectMake(width/2 - self.featureWindowWidth/2, height/2 - self.featureWindowHeight/2, self.featureWindowWidth, self.featureWindowHeight));
        // we crop a part of cgimage to uiimage to do feature detect and track.
        UIImage *processUIImage = [UIImage imageWithCGImage:processCGImageRef];
        //UIImage *processUIImage = originalUIImage;
        
        [self.imageProcess setCurrentImageMat:processUIImage];
        
        double var = [self.imageProcess calVariance];
        
        if (self.imageNo >= self.lockDelay) {
            if ((width != 960) && ([self isIphone4])) {
                // show to screen.
                //[self adjustForHighResolution];
                [self.scrollViewLeft setImage:self.highVarImg];
                [self.scrollViewRight setImage:self.highVarImg];
                self.isLocked = true;
                //[self.scrollViewLeft setContentOffset:self.correctContentOffset animated:NO];
                //[self.scrollViewRight setContentOffset:self.correctContentOffset animated:NO];
                self.maxVariance = 0;
            } else {
                self.isLocked = true;
                [self.scrollViewLeft setImage:self.highVarImg];
                [self.scrollViewRight setImage:self.highVarImg];
                self.maxVariance = 0;
            }
        }
        // if not reaching lock delay.
        else {
            if ((self.maxVariance < var)||(self.maxVariance == 0)) {
                self.highVarImg = originalUIImage;
                self.maxVariance = var;
            }
        }
        
        /* release original cgimage */
        CGImageRelease(processCGImageRef);
        
    }
    // normal state that not locked.
    else {
        //  for ip4 resolution may not get changed that fast
        if (false) {//(([self isIphone4]) && (width != 960)) {
            // do nothing
        }
        else {
            // cut a particle of a cgimage to process fast feature detect
            CGImageRef processCGImageRef = CGImageCreateWithImageInRect(originalCGImage, CGRectMake(width/2 - self.featureWindowWidth/2, height/2 - self.featureWindowHeight/2, self.featureWindowWidth, self.featureWindowHeight));
            // we crop a part of cgimage to uiimage to do feature detect and track.
            UIImage *processUIImage = [UIImage imageWithCGImage:processCGImageRef];
            //UIImage *processUIImage = originalUIImage;
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
                /* set up images */
                [self.imageProcess setCurrentImageMat:processUIImage];
                /* calculate motion vector */
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
                //NSLog(@"x = %.05f, y = %.05f", self.motionX, self.motionY);
                //NSLog(@"x = %.05f, y = %.05f, mean_x = %.05f, mean_y = %.05f", motionVector.x, motionVector.y, mean_x, mean_y);
                if (fabs(mean_x) < MEAN_STABLE_THRESHOLD_LEFT_RIGHT && fabs(mean_y) < MEAN_STABLE_THRESHOLD_UP_DOWN && !self.releasing) {
                    if (!self.isStabilizationEnable) {
                        self.isStabilizationEnable = true;
                        //[self displayMessage:@"start stable"];
                        [self reSet];
                    }
                }
                if (fabs(mean_x) > MEAN_NOT_STABLE_THRESHOLD_LEFT_RIGHT || fabs(mean_y) > MEAN_NOT_STABLE_THRESHOLD_UP_DOWN || fabs(motionVector.x) > MOVEMENT_LEFT_RIGHT / sqrt(self.currentZoomScale) || fabs(motionVector.y) > MOVEMENT_UP_DOWN / sqrt(self.currentZoomScale) || fabs(self.motionX) > MOVEMENT_THRESHOLD_LEFT_RIGHT || fabs(self.motionY) > MOVEMENT_THRESHOLD_UP_DOWN) {
                    if (self.isStabilizationEnable) {
                        self.isStabilizationEnable = false;
                        //[self displayMessage:@"end stable"];
                        [self startReleaseStabilization];
                    }
                }
            }
            
            
            //  if stabilization function is disabled
            if (self.releasing) {
                CGRect windowBounds = [[UIScreen mainScreen] bounds];
                ++self.increasing;
                float x = self.move_x * (RELEASE_TIME - self.increasing);
                float y = self.move_y * (RELEASE_TIME - self.increasing);
                CGRect resultRect = [self.imageProcess calculateMyCroppedImage:x ypos:y width:width height:height scale:self.currentZoomScale bounds:CGRectMake(0, 0, windowBounds.size.width / 2, windowBounds.size.height)];
                //NSLog(@"result rect: origin:%f, %f: w:%f,h:%f\n", resultRect.origin.x, resultRect.origin.y, resultRect.size.width, resultRect.size.height);
                //  cut from original to move the image
                CGImageRef finalProcessImage = CGImageCreateWithImageInRect(originalCGImage, resultRect);
                UIImage *finalUIImage;
                if (self.isImageModeOn) {
                    finalUIImage = [self addFilter:finalProcessImage];
                } else {
                    finalUIImage = [UIImage imageWithCGImage:finalProcessImage];
                }
                [self.scrollViewLeft setImage:finalUIImage];
                [self.scrollViewRight setImage:finalUIImage];
                CGImageRelease(finalProcessImage);
                if (self.increasing == RELEASE_TIME) {
                    [self endReleaseStabilization];
                }
            } else {
                if (!self.isStabilizationEnable) {
                    [self.scrollViewLeft setImage:originalUIImage];
                    [self.scrollViewRight setImage:originalUIImage];
                }
                else {
                    if (self.imageNo == 0) {
                        [self.scrollViewLeft setImage:originalUIImage];
                        [self.scrollViewRight setImage:originalUIImage];
                    }
                    else {
                        NSValue *val = [self.offsetArray objectAtIndex:[self.offsetArray count] - 1];
                        CGPoint p = [val CGPointValue];
                        self.motionX += p.x;
                        self.motionY += p.y;
                        
                        CGRect windowBounds = [[UIScreen mainScreen] bounds];
                        CGRect resultRect = [self.imageProcess calculateMyCroppedImage:self.motionX ypos:self.motionY width:width height:height scale:self.currentZoomScale bounds:CGRectMake(0, 0, windowBounds.size.width / 2, windowBounds.size.height)];
                        
                        //NSLog(@"result rect: origin:%f, %f: w:%f,h:%f\n", resultRect.origin.x, resultRect.origin.y, resultRect.size.width, resultRect.size.height);
                        //  cut from original to move the image
                        CGImageRef finalProcessImage = CGImageCreateWithImageInRect(originalCGImage, resultRect);
                        UIImage *finalUIImage;
                        if (self.isImageModeOn) {
                            finalUIImage = [self addFilter:finalProcessImage];
                        } else {
                            finalUIImage = [UIImage imageWithCGImage:finalProcessImage];
                        }
                        [self.scrollViewLeft setImage:finalUIImage];
                        [self.scrollViewRight setImage:finalUIImage];
                        CGImageRelease(finalProcessImage);
                        
                    }
                }
            }
            CGImageRelease(processCGImageRef);
        }
    }
    
    /*We relase the CGImageRef*/
    CGImageRelease(originalCGImage);
    /*We unlock the  image buffer*/
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    self.imageNo++;
    return;
}
//  reSet all settings
- (void) reSet {
    self.motionX = 0;
    self.motionY = 0;
    self.imageNo = 0;
    self.adjustingFocus = NO;
}

#pragma mark -
#pragma mark Basic Controls
- (void) setMinimalZoomScale: (float)minScale {
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
        [self.imageItemLeft setSelected:NO];
        [self.imageItemRight setSelected:NO];
        [self.imageButtonLeft setSelected:NO];
        [self.imageButtonRight setSelected:NO];
        [self displayMessage:@"Color"];
        [self messageChangeColor:[UIColor blackColor]];
    } else {
        [self.imageItemLeft setSelected:YES];
        [self.imageItemRight setSelected:YES];
        [self.imageButtonLeft setSelected:YES];
        [self.imageButtonRight setSelected:YES];
        [self displayMessage:@"Black and white"];
        [self messageChangeColor:[UIColor whiteColor]];
    }
    self.isImageModeOn = !self.isImageModeOn;
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
        self.beforeLock = false;
        self.isLocked = false;
        [self reSet];
        /*if ([self isIphone4]) {
            self.currentResolution = IP4RESOLUTION;
            [self.captureSession beginConfiguration];
            [self.captureSession setSessionPreset:self.currentResolution];
            [self.captureSession commitConfiguration];
            [self recoverFlash];
            //[self adjustForLowResolution];
            self.resolutionWidth = 540;
            self.resolutionHeight = 960;
        }*/
    }
    // lock screen
    else {
        self.isLocked = false;
        self.beforeLock = true;
        [self reSet];
        /*if ([self isIphone4]) {
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
            //self.correctContentOffset = self.scrollView.contentOffset;
        }*/
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


- (void)showMenuExceptZoom {
    // message
    [self showMessage];
    // menu
    [self showMenu];
    // zoom
    [self hideZoom];
}

- (void)hideMenuExceptZoom {
    // message
    [self hideMessage];
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
        if (self.zoomIsSelected) {
            self.zoomIsSelected = false;
            [self stopGyroUpAndDown];
            [self startGyroLeftAndRight];
            [self showMenuExceptZoom];
            [self exitMenu];
        } else {
            self.zoomIsSelected = true;
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

- (void)enterMenu {
    // stop acc
    [self stopAccelerometer];
    // start gyro
    [self startGyro];
    [self resetTargetCursor];
    [self checkTargetCursor];
    self.isMenuHidden = false;
    [self showMenuExceptZoom];
}

- (void)exitMenu {
    self.isMenuHidden = true;
    [self hideMessage];
    [self hideMenu];
    // stop gyro
    [self stopGyro];
    // start acc again
    [self startAccelerometer];
}

- (void) resetTargetCursor {
    // target at zoom
    self.messageLeft.text = @"Zoom";
    self.messageRight.text = @"Zoom";
    self.isZoomTargetted = true;
    self.isFlashTargetted = false;
    self.isImageTargetted = false;
    self.isExitTargetted = false;
    self.targetCursor = 1.0;
}

// notification is in main thread, so this function also run in main thread
- (void)checkTargetCursor {
    if (self.isZoomTargetted) {
        // set message zoom
        self.messageLeft.text = @"Zoom";
        self.messageRight.text = @"Zoom";
        // zoom
        [self.zoomItemLeft setBackgroundColor:[UIColor redColor]];
        [self.zoomItemRight setBackgroundColor:[UIColor redColor]];
        self.zoomItemLeft.layer.borderColor = [[UIColor redColor] CGColor];
        self.zoomItemRight.layer.borderColor = [[UIColor redColor] CGColor];
        // flash
        [self.flashItemLeft setBackgroundColor:nil];
        [self.flashItemRight setBackgroundColor:nil];
        self.flashItemLeft.layer.borderColor = nil;
        self.flashItemRight.layer.borderColor = nil;
        // image
        [self.imageItemLeft setBackgroundColor:nil];
        [self.imageItemRight setBackgroundColor:nil];
        self.imageItemLeft.layer.borderColor = nil;
        self.imageItemRight.layer.borderColor = nil;
        // exit
        [self.exitItemLeft setBackgroundColor:nil];
        [self.exitItemRight setBackgroundColor:nil];
        self.exitItemLeft.layer.borderColor = nil;
        self.exitItemRight.layer.borderColor = nil;
        return;
    }
    if (self.isFlashTargetted) {
        // set message flashlight
        self.messageLeft.text = @"Flashlight";
        self.messageRight.text = @"Flashlight";
        // zoom
        [self.zoomItemLeft setBackgroundColor:nil];
        [self.zoomItemRight setBackgroundColor:nil];
        self.zoomItemLeft.layer.borderColor = nil;
        self.zoomItemRight.layer.borderColor = nil;
        // flash
        [self.flashItemLeft setBackgroundColor:[UIColor redColor]];
        [self.flashItemRight setBackgroundColor:[UIColor redColor]];
        self.flashItemLeft.layer.borderColor = [[UIColor redColor] CGColor];
        self.flashItemRight.layer.borderColor = [[UIColor redColor] CGColor];
        // image
        [self.imageItemLeft setBackgroundColor:nil];
        [self.imageItemRight setBackgroundColor:nil];
        self.imageItemLeft.layer.borderColor = nil;
        self.imageItemRight.layer.borderColor = nil;
        // exit
        [self.exitItemLeft setBackgroundColor:nil];
        [self.exitItemRight setBackgroundColor:nil];
        self.exitItemLeft.layer.borderColor = nil;
        self.exitItemRight.layer.borderColor = nil;
        return;
    }
    if (self.isImageTargetted) {
        // set message Image Mode
        self.messageLeft.text = @"Image Mode";
        self.messageRight.text = @"Image Mode";
        // zoom
        [self.zoomItemLeft setBackgroundColor:nil];
        [self.zoomItemRight setBackgroundColor:nil];
        self.zoomItemLeft.layer.borderColor = nil;
        self.zoomItemRight.layer.borderColor = nil;
        // flash
        [self.flashItemLeft setBackgroundColor:nil];
        [self.flashItemRight setBackgroundColor:nil];
        self.flashItemLeft.layer.borderColor = nil;
        self.flashItemRight.layer.borderColor = nil;
        // image
        [self.imageItemLeft setBackgroundColor:[UIColor redColor]];
        [self.imageItemRight setBackgroundColor:[UIColor redColor]];
        self.imageItemLeft.layer.borderColor = [[UIColor redColor] CGColor];
        self.imageItemRight.layer.borderColor = [[UIColor redColor] CGColor];
        // exit
        [self.exitItemLeft setBackgroundColor:nil];
        [self.exitItemRight setBackgroundColor:nil];
        self.exitItemLeft.layer.borderColor = nil;
        self.exitItemRight.layer.borderColor = nil;
        return;
    }
    if (self.isExitTargetted) {
        // set message Exit
        self.messageLeft.text = @"Exit";
        self.messageRight.text = @"Exit";
        // zoom
        [self.zoomItemLeft setBackgroundColor:nil];
        [self.zoomItemRight setBackgroundColor:nil];
        self.zoomItemLeft.layer.borderColor = nil;
        self.zoomItemRight.layer.borderColor = nil;
        // flash
        [self.flashItemLeft setBackgroundColor:nil];
        [self.flashItemRight setBackgroundColor:nil];
        self.flashItemLeft.layer.borderColor = nil;
        self.flashItemRight.layer.borderColor = nil;
        // image
        [self.imageItemLeft setBackgroundColor:nil];
        [self.imageItemRight setBackgroundColor:nil];
        self.imageItemLeft.layer.borderColor = nil;
        self.imageItemRight.layer.borderColor = nil;
        // exit
        [self.exitItemLeft setBackgroundColor:[UIColor redColor]];
        [self.exitItemRight setBackgroundColor:[UIColor redColor]];
        self.exitItemLeft.layer.borderColor = [[UIColor redColor] CGColor];
        self.exitItemRight.layer.borderColor = [[UIColor redColor] CGColor];
        return;
    }
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
        //[self zoomControl];
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
    float scale = self.currentZoomScale - movement.floatValue * 0.05 * 80;
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
        self.isZoomTargetted = true;
        self.isFlashTargetted = false;
        self.isImageTargetted = false;
        self.isExitTargetted = false;
    } else if (scale >= TARGET_INTERVAL && scale < 2 * TARGET_INTERVAL) {
        self.isZoomTargetted = false;
        self.isFlashTargetted = true;
        self.isImageTargetted = false;
        self.isExitTargetted = false;
    } else if (scale >= 2 * TARGET_INTERVAL && scale < 3 * TARGET_INTERVAL) {
        self.isZoomTargetted = false;
        self.isFlashTargetted = false;
        self.isImageTargetted = true;
        self.isExitTargetted = false;
    } else if (scale >= 3 * TARGET_INTERVAL && scale <= 4 * TARGET_INTERVAL) {
        self.isZoomTargetted = false;
        self.isFlashTargetted = false;
        self.isImageTargetted = false;
        self.isExitTargetted = true;
    }
    self.targetCursor = scale;
    [self checkTargetCursor];
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
    [self setZoomScale:scrollView.zoomScale];
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