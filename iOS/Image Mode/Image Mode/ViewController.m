//
//  ViewController.m
//  Image Mode
//
//  Created by Pengfei Tan on 6/9/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

// ViewController.m
#import "ViewController.h"

@implementation ViewController

@synthesize context;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    coreImageContext = [CIContext contextWithEAGLContext:self.context];
    
    glGenRenderbuffers(1, &_renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    
    NSError *error;
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    AVCaptureVideoDataOutput *dataOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    [dataOutput setAlwaysDiscardsLateVideoFrames:YES];
    [dataOutput setVideoSettings:[NSDictionary  dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                                                              forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    [dataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    avCaptureSession = [[AVCaptureSession alloc] init];
    [avCaptureSession beginConfiguration];
    [avCaptureSession setSessionPreset:AVCaptureSessionPreset1280x720];
    [avCaptureSession addInput:input];
    [avCaptureSession addOutput:dataOutput];
    [avCaptureSession commitConfiguration];
    [avCaptureSession startRunning];
    
    [self setupCGContext];
    CGImageRef cgImg = CGBitmapContextCreateImage(cgContext);
    maskImage = [CIImage imageWithCGImage:cgImg];
    CGImageRelease(cgImg);
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *image = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    /*image = [CIFilter   filterWithName:@"CISepiaTone" keysAndValues:kCIInputImageKey,
             image, @"inputIntensity",
             [NSNumber numberWithFloat:0.8],
             nil].outputImage;*/
    //image = [CIFilter filterWithName:@"CIColorInvert"].outputImage;
    CIFilter* filter = [CIFilter filterWithName:@"CIPhotoEffectMono"];
    [filter setDefaults];
    [filter setValue:image forKey:@"inputImage"];
    image = [filter valueForKey:@"outputImage"];
    
    CIFilter* filter2 = [CIFilter filterWithName:@"CIColorInvert"];
    [filter2 setDefaults];
    [filter2 setValue:image forKey:@"inputImage"];
    image = [filter2 valueForKey:@"outputImage"];
    
    CIFilter* filter3 = [CIFilter filterWithName:@"CIColorControls"];
    [filter3 setDefaults];
    [filter3 setValue:@2 forKey:@"inputContrast"];
    [filter3 setValue:image forKey:@"inputImage"];
    image = [filter3 valueForKey:@"outputImage"];
    
    [coreImageContext drawImage:image atPoint:CGPointZero fromRect:[image extent] ];
    //CGRect bounds = [[UIScreen mainScreen] bounds];
    //[coreImageContext drawImage:image inRect:CGRectMake(0, 0, 568, 320) fromRect:[image extent]];
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

-(void)setupCGContext {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * screenSize.width;
    NSUInteger bitsPerComponent = 8;
    cgContext = CGBitmapContextCreate(NULL, screenSize.width, screenSize.height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast);
    
    CGColorSpaceRelease(colorSpace);
}
@end

