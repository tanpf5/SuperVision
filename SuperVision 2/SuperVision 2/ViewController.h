//
//  ViewController.h
//  SuperVision 2
//
//  Created by 谭鹏飞 on 5/11/15.
//
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface ViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate>

//  display on screen to slide to change |currentZoomRate|
@property (strong, nonatomic) IBOutlet UISlider *zoomSlider;
@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) NSString *currentResolution;

- (void) initialSettings;
- (void) initialControls;
- (void) initialCapture;

@end

