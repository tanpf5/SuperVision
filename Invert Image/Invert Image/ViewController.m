//
//  ViewController.m
//  Invert Image
//
//  Created by Pengfei Tan on 6/9/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initialCapture];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    dispatch_release(queue);
    // Set the video output to store frame in BGRA (It is supposed to be faster)
    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
    [captureOutput setVideoSettings:videoSettings];
    /*And we create a capture session*/
    self.captureSession = [[AVCaptureSession alloc] init];
    
    // for ios 5.0  However, it does not work
    AVCaptureConnection *conn = [captureOutput connectionWithMediaType:AVMediaTypeVideo];
    conn.videoMinFrameDuration = CMTimeMake(1, self.minFrameRate);
    conn.videoMaxFrameDuration = CMTimeMake(1, self.maxFrameRate);
    [conn release];
    
    /*We add input and output*/
    [self.captureSession addInput:captureInput];
    [self.captureSession addOutput:captureOutput];
    /*We use medium quality, ont the iPhone 4 this demo would be laging too much, the conversion in UIImage and CGImage demands too much ressources for a 720p resolution.*/
    [self.captureSession setSessionPreset:self.currentResolution];
    /*We start the capture*/
    [self.captureSession startRunning];
    
    // initial date time.
    self.lastDate = [[NSDate date] retain];
    
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    /*
     NSLog(@"imageview size: w:%f, h:%f, scrollview size:%f, %f\n", self.scrollView.imageView.frame.size.width, self.scrollView.imageView.frame.size.height, self.scrollView.frame.size.width, self.scrollView.frame.size.height);
     NSLog(@"window: w %f, h %f\n", [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
     */
    if (self.isLocked) {
        return;
    }
    
    // zewen li
    //[self performSelectorOnMainThread:@selector(adjustCurrentOrientation) withObject:nil waitUntilDone:YES];
    [self performSelectorOnMainThread:@selector(setupControlsPosition) withObject:nil waitUntilDone:YES];
    
    
    /* time statics
     NSDate *captureOutputStartTime = [NSDate date];
     double intervalBetweenTwoFrames = [captureOutputStartTime timeIntervalSinceDate:self.lastDate];
     self.avgTimeForOneFrame += intervalBetweenTwoFrames;
     self.lastDate = [[NSDate date] retain];
     int currentFrameRate = 1 / intervalBetweenTwoFrames;
     NSString *frameRateString = [NSString stringWithFormat:@"%d",currentFrameRate];
     [self.frameRateLabel performSelectorOnMainThread:@selector(setText:) withObject:frameRateString waitUntilDone:YES];
     [self systemOutput:@"Total Time for one frame is:%f\n" variable:intervalBetweenTwoFrames];
     */
    
    /*We create an autorelease pool because as we are not in the main_queue our code is
     not executed in the main thread. So we have to create an autorelease pool for the thread we are in*/
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
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
    
    /*We display the result on the image view (We need to change the orientation of the image so that the video is displayed correctly).
     Same thing as for the CALayer we are not in the main thread so ...*/
    // just change orientation for image rendering, its width and height does not change!!
    UIImage *originalUIImage = [UIImage imageWithCGImage:originalCGImage scale:1 orientation:self.imageOrientation];
    
    /*We release some components*/
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    
    if (self.beforeLock) {
        
        CGImageRef processCGImageRef = CGImageCreateWithImageInRect(originalCGImage, CGRectMake(width/2 - self.featureWindowWidth/2, height/2 - self.featureWindowHeight/2, self.featureWindowWidth, self.featureWindowHeight));
        // we crop a part of cgimage to uiimage to do feature detect and track.
        UIImage *processUIImage = [UIImage imageWithCGImage:processCGImageRef];
        [self.imageProcess setCurrentImageMat:processUIImage];
        
        double var = [self.imageProcess calVariance];
        
        if (self.imageNo >= self.lockDelay) {
            
            if ([self isIphone5] || ([self isIpad])) {
                self.isLocked = true;
                [self.scrollView setImage:self.highVarImg];
                [self.scrollViewRight setImage:self.highVarImg];
                self.maxVariance = 0;
            }
            
            if ((width != 960) && ([self isIphone4] || [self isIphone4S])) {
                // show to screen.
                [self adjustForHighResolution];
                [self.scrollView setImage:self.highVarImg];
                [self.scrollViewRight setImage:self.highVarImg];
                self.isLocked = true;
                [self.scrollView setContentOffset:self.correctContentOffset animated:NO];
                [self.scrollViewRight setContentOffset:self.correctContentOffset animated:NO];
                self.maxVariance = 0;
            }
        }
        // if not reaching lock delay.
        else {
            if ((self.maxVariance < var)||(self.maxVariance == 0)) {
                self.highVarImg = [UIImage imageWithCGImage:originalCGImage scale:1 orientation:self.imageOrientation];
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
            
            //  if stabilization function is disabled
            if (!self.isStabilizationEnable) {
                [self.scrollView setImage:originalUIImage];
                [self.scrollViewRight setImage:originalUIImage];
            }
            else {
                if (self.imageNo == 0) {
                    [self.imageProcess setLastImageMat:processUIImage];
                    [self.scrollView setImage:originalUIImage];
                    [self.scrollViewRight setImage:originalUIImage];
                }
                else {
                    /* set up images */
                    [self.imageProcess setCurrentImageMat:processUIImage];
                    /* calculate motion vector */
                    CGPoint motionVector = [self.imageProcess motionEstimation];
                    
                    self.motionX += motionVector.x;
                    self.motionY += motionVector.y;
                    //  there is no feature points or either no feature tracking points
                    if (self.isHorizontalStable) {
                        if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
                            self.motionY = 0;
                        }
                        else
                            self.motionX = 0;
                    }
                    CGRect windowBounds = [[UIScreen mainScreen] bounds];
                    CGRect resultRect = [self.imageProcess calculateMyCroppedImage:self.motionX ypos:self.motionY width:width height:height scale:self.currentZoomRate bounds:windowBounds];
                    
                    //NSLog(@"result rect: origin:%f, %f: w:%f,h:%f\n", resultRect.origin.x, resultRect.origin.y, resultRect.size.width, resultRect.size.height);
                    //  cut from original to move the image
                    CGImageRef finalProcessImage = CGImageCreateWithImageInRect(originalCGImage, resultRect);
                    UIImage *finalUIImage = [UIImage imageWithCGImage:finalProcessImage scale:1 orientation:self.imageOrientation];
                    [self.scrollView setImage:finalUIImage];
                    [self.scrollViewRight setImage:finalUIImage];
                    CGImageRelease(finalProcessImage);
                    
                }
            }
            CGImageRelease(processCGImageRef);
        }
    }
    
    /*We relase the CGImageRef*/
    CGImageRelease(originalCGImage);
    /*We unlock the  image buffer*/
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    [pool drain];
    self.imageNo++;
    return;
}

@end
