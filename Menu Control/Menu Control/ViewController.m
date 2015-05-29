//
//  ViewController.m
//  Menu Control
//
//  Created by Pengfei Tan on 5/27/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

#import "ViewController.h"

//  Motion
//  doubleTap
#define TAP_WND 20
#define GAP_WND TAP_WND * 0.8
#define FREQUENCY 20
#define STABLE_THRESHOLD 0.03
#define FLUC_THRESHOLD 0.07
#define HIT_THRESHOLD 3
//  zoom in/out ratio
#define RATIO 50
#define OFFSET 0.015
//  menu target
#define TARGETRATIO 50
#define TARGETOFFSET 0.014
//  view postion
#define SLIDERWIDTH 44
#define SLIDERHEIGHT 250
#define degreeToRadians(x) (M_PI * x / 180.0)
#define SLIDERTHUMB "sliderthumb2.png"

@interface ViewController ()

//  Setting
@property (assign, nonatomic) bool isHidden;
@property (assign, nonatomic) bool isZoomTargetted;
@property (assign, nonatomic) bool isFlashTargetted;
@property (assign, nonatomic) bool isImageTargetted;
@property (assign, nonatomic) bool isExitTargetted;
@property (assign, nonatomic) bool zoomIsSelected;
// zoom: [0, 2)
// flash: [2, 4)
// image: [4, 6)
// exit: [6, 8]
@property (assign, nonatomic) float targetCursor;

//  Motion
@property (strong, nonatomic) CMMotionManager* motionManager;
@property (strong, nonatomic) NSMutableArray* gyro;
@property (strong, nonatomic) NSLock* gyroLock;

@property (assign, nonatomic) float currentZoomRate;

@property (assign, nonatomic) float x_offset;
@property (assign, nonatomic) NSInteger x_number;
@property (assign, nonatomic) float y_offset;
@property (assign, nonatomic) NSInteger y_number;

@end

@implementation ViewController

@synthesize zoom = _zoom;
@synthesize flash = _flash;
@synthesize image = _image;
@synthesize exit = _exit;
@synthesize zoomRight = _zoomRight;
@synthesize flashRight = _flashRight;
@synthesize imageRight = _imageRight;
@synthesize exitRight = _exitRight;

@synthesize sliderBackground = _sliderBackground;
@synthesize sliderBackgroundRight = _sliderBackgroundRight;
@synthesize zoomSlider = _zoomSlider;
@synthesize zoomSliderRight = _zoomSliderRight;
@synthesize currentZoomRate = _currentZoomRate;

#pragma mark -
#pragma mark Initial Function

- (void)initialViewPosition {
    CGRect bounds = [[UIScreen mainScreen] bounds];
    [self.sliderBackground setFrame:CGRectMake(bounds.size.height - SLIDERWIDTH + 4 - 240,
                                               bounds.size.width/2 - SLIDERHEIGHT/2 + 14,
                                               SLIDERWIDTH - 10,
                                               SLIDERHEIGHT - 27)];
    [self.sliderBackgroundRight setFrame:CGRectMake(bounds.size.height - SLIDERWIDTH + 4,
                                                    bounds.size.width/2 - SLIDERHEIGHT/2 + 14,
                                                    SLIDERWIDTH - 10,
                                                    SLIDERHEIGHT - 27)];
    [self.zoomSlider setFrame:CGRectMake(bounds.size.height - SLIDERWIDTH - 240,
                                         bounds.size.width/2 - SLIDERHEIGHT / 2,
                                         SLIDERWIDTH,
                                         SLIDERHEIGHT)];
    [self.zoomSliderRight setFrame:CGRectMake(bounds.size.height - SLIDERWIDTH,
                                              bounds.size.width/2 - SLIDERHEIGHT / 2,
                                              SLIDERWIDTH,
                                              SLIDERHEIGHT)];
}


- (void) initialSetting {
    // hide all
    self.isHidden = true;
    [self hideAllControls];
    // target at zoom
    self.isZoomTargetted = true;
    self.isFlashTargetted = false;
    self.isImageTargetted = false;
    self.isExitTargetted = false;
    self.zoomIsSelected = false;
    self.targetCursor = 1.0;
    
    self.currentZoomRate = 1;
}

- (void)initialControls {
    //  Customizing the UISlider
    UIImage *maxImage = [UIImage imageNamed:@"empty.png"];
    UIImage *minImage = [UIImage imageNamed:@"empty.png"];
    UIImage *thumbImage = [UIImage imageWithCGImage:[[UIImage imageNamed:@SLIDERTHUMB] CGImage] scale:2 orientation:UIImageOrientationUp];
    [[UISlider appearance] setMaximumTrackImage:maxImage
                                       forState:UIControlStateNormal];
    [[UISlider appearance] setMinimumTrackImage:minImage
                                       forState:UIControlStateNormal];
    [[UISlider appearance] setThumbImage:thumbImage
                                forState:UIControlStateNormal];
    
    //  set the slider vertical on screen
    CGAffineTransform transformRotate = CGAffineTransformMakeRotation(degreeToRadians(-90));
    self.zoomSlider.transform = transformRotate;
    self.zoomSliderRight.transform = transformRotate;
    
}


- (void) initialMotion {
    self.gyro = [[NSMutableArray alloc] init];
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.gyroUpdateInterval = 1.0 / TAP_WND;
    self.gyroLock = [[NSLock alloc] init];
    //float a = CGRectGetHeight([[UIScreen mainScreen] bounds]) / 2;
    //float b = CGRectGetWidth([[UIScreen mainScreen] bounds]) / 2;
    if ([self.motionManager isAccelerometerAvailable] && [self.motionManager isGyroAvailable]){
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        [self.motionManager
         startGyroUpdatesToQueue:queue withHandler:^(CMGyroData *gyroData, NSError *error) {
             //NSLog(@"gyr, %.00f, %.05f, %.05f, %.05f", CFAbsoluteTimeGetCurrent() * 100000000, gyroData.rotationRate.x, gyroData.rotationRate.y, gyroData.rotationRate.z);
             [self.gyroLock lock];
             // update offset
             [self updateOffset];
             // save data in buffer
             if ([self.gyro count] < GAP_WND + TAP_WND) {
                 [self.gyro addObject:gyroData];
                 if ([self.gyro count] == GAP_WND + TAP_WND) {
                     [self checkTaps];
                 }
             }
             else {
                 for (int i = 1; i < GAP_WND + TAP_WND; i++) {
                     [self.gyro replaceObjectAtIndex:i - 1 withObject:[self.gyro objectAtIndex:i]];
                 }
                 [self.gyro replaceObjectAtIndex:GAP_WND + TAP_WND - 1 withObject:gyroData];
                 [self checkTaps];
             }
             if (!self.isHidden) {
                 if (self.zoomIsSelected) {
                     [self zoomSliderChangedByMotion];
                 } else {
                     [self targetCursorChangedByMotion];
                     [self checkTargetCursor];
                 }
                 //[self zoomSliderChangedByMotion:gyroData.rotationRate.y];
             }
             [self.gyroLock unlock];
         }];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initialSetting];
    [self initialControls];
    [self initialViewPosition];
    [self initialMotion];
    // Do any additional setup after loading the view, typically from a nib.
}

#pragma mark -
#pragma mark Control Function

- (void) updateOffset {
    if ([self.gyro count] < 2) {
        return ;
    }
    CMGyroData *gyroData1 = self.gyro[[self.gyro count] - 2];
    float x1 = gyroData1.rotationRate.x;
    float y1 = gyroData1.rotationRate.y;
    CMGyroData *gyroData2 = self.gyro[[self.gyro count] - 1];
    float x2 = gyroData2.rotationRate.x;
    float y2 = gyroData2.rotationRate.y;
    // update offset
    if (fabs(x2 - x1) < 0.001) {
        self.x_offset = (self.x_offset * self.x_number + x1 + x2) / (self.x_number + 2);
        self.x_number = self.x_number + 2;
    }
    if (fabs(y2 - y1) < 0.001) {
        self.y_offset = (self.y_offset * self.y_number + y1 + y2) / (self.y_number + 2);
        self.y_number = self.y_number + 2;
    }
}

- (IBAction)zoomSliderChanged:(id)sender {
    float scale;
    if (self.zoomSlider.value != self.currentZoomRate) {
        scale = self.zoomSlider.value;
    } else {
        scale = self.zoomSliderRight.value;
    }
    self.currentZoomRate = scale;
    [self.zoomSlider setValue:self.currentZoomRate animated:YES];
    [self.zoomSliderRight setValue:self.currentZoomRate animated:YES];
}

//  hide all interface controls
- (void)hideAllControls {
    [self.zoom setHidden:YES];
    [self.flash setHidden:YES];
    [self.image setHidden:YES];
    [self.exit setHidden:YES];
    [self.zoomRight setHidden:YES];
    [self.flashRight setHidden:YES];
    [self.imageRight setHidden:YES];
    [self.exitRight setHidden:YES];
    
    // zoom
    
    [self.zoomSlider setHidden:YES];
    [self.zoomSliderRight setHidden:YES];
    [self.sliderBackground setHidden:YES];
    [self.sliderBackgroundRight setHidden:YES];
}

//  show all interface controls
- (void)showAllcontrols {
    [self.zoom setHidden:NO];
    [self.flash setHidden:NO];
    [self.image setHidden:NO];
    [self.exit setHidden:NO];
    [self.zoomRight setHidden:NO];
    [self.flashRight setHidden:NO];
    [self.imageRight setHidden:NO];
    [self.exitRight setHidden:NO];
    
    // zoom
    [self.zoomSlider setHidden:NO];
    [self.zoomSliderRight setHidden:NO];
    [self.sliderBackground setHidden:NO];
    [self.sliderBackgroundRight setHidden:NO];

}

//  hide all interface controls except zoom
- (void)hideAllControlsExceptZoom {
    [self.zoom setHidden:YES];
    [self.flash setHidden:YES];
    [self.image setHidden:YES];
    [self.exit setHidden:YES];
    [self.zoomRight setHidden:YES];
    [self.flashRight setHidden:YES];
    [self.imageRight setHidden:YES];
    [self.exitRight setHidden:YES];
    
    // zoom
    [self.zoomSlider setHidden:NO];
    [self.zoomSliderRight setHidden:NO];
    [self.sliderBackground setHidden:NO];
    [self.sliderBackgroundRight setHidden:NO];
}

//  show all interface controls except zoom
- (void)showAllcontrolsExceptZoom {
    [self.zoom setHidden:NO];
    [self.flash setHidden:NO];
    [self.image setHidden:NO];
    [self.exit setHidden:NO];
    [self.zoomRight setHidden:NO];
    [self.flashRight setHidden:NO];
    [self.imageRight setHidden:NO];
    [self.exitRight setHidden:NO];
    
    // zoom
    [self.zoomSlider setHidden:YES];
    [self.zoomSliderRight setHidden:YES];
    [self.sliderBackground setHidden:YES];
    [self.sliderBackgroundRight setHidden:YES];
    
}



- (void) resetTargetCursor {
    // target at zoom
    self.isZoomTargetted = true;
    self.isFlashTargetted = false;
    self.isImageTargetted = false;
    self.isExitTargetted = false;
    self.targetCursor = 1.0;
}

- (void)checkTargetCursor {
    if (self.isZoomTargetted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.zoom setBackgroundColor:[UIColor redColor]];
            [self.flash setBackgroundColor:[UIColor whiteColor]];
            [self.image setBackgroundColor:[UIColor whiteColor]];
            [self.exit setBackgroundColor:[UIColor whiteColor]];
            [self.zoomRight setBackgroundColor:[UIColor redColor]];
            [self.flashRight setBackgroundColor:[UIColor whiteColor]];
            [self.imageRight setBackgroundColor:[UIColor whiteColor]];
            [self.exitRight setBackgroundColor:[UIColor whiteColor]];
        });
        return;
    }
    if (self.isFlashTargetted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.zoom setBackgroundColor:[UIColor whiteColor]];
            [self.flash setBackgroundColor:[UIColor redColor]];
            [self.image setBackgroundColor:[UIColor whiteColor]];
            [self.exit setBackgroundColor:[UIColor whiteColor]];
            [self.zoomRight setBackgroundColor:[UIColor whiteColor]];
            [self.flashRight setBackgroundColor:[UIColor redColor]];
            [self.imageRight setBackgroundColor:[UIColor whiteColor]];
            [self.exitRight setBackgroundColor:[UIColor whiteColor]];
        });
        return;
    }
    if (self.isImageTargetted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.zoom setBackgroundColor:[UIColor whiteColor]];
            [self.flash setBackgroundColor:[UIColor whiteColor]];
            [self.image setBackgroundColor:[UIColor redColor]];
            [self.exit setBackgroundColor:[UIColor whiteColor]];
            [self.zoomRight setBackgroundColor:[UIColor whiteColor]];
            [self.flashRight setBackgroundColor:[UIColor whiteColor]];
            [self.imageRight setBackgroundColor:[UIColor redColor]];
            [self.exitRight setBackgroundColor:[UIColor whiteColor]];
        });
        return;
    }
    if (self.isExitTargetted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.zoom setBackgroundColor:[UIColor whiteColor]];
            [self.flash setBackgroundColor:[UIColor whiteColor]];
            [self.image setBackgroundColor:[UIColor whiteColor]];
            [self.exit setBackgroundColor:[UIColor redColor]];
            [self.zoomRight setBackgroundColor:[UIColor whiteColor]];
            [self.flashRight setBackgroundColor:[UIColor whiteColor]];
            [self.imageRight setBackgroundColor:[UIColor whiteColor]];
            [self.exitRight setBackgroundColor:[UIColor redColor]];
        });
        return;
    }
}

- (void)targetCursorChangedByMotion {
    if ([self.gyro count] < 2) {
        return ;
    }
    CMGyroData *gyroData1 = self.gyro[[self.gyro count] - 2];
    float x1 = gyroData1.rotationRate.x;
    CMGyroData *gyroData2 = self.gyro[[self.gyro count] - 1];
    float x2 = gyroData2.rotationRate.x;
    if (fabs(x2 - x1) < 0.015 || fabs(x2 - x1) > 0.3) {
        return ;
    }
    // left +x, right -x
    float scale = self.targetCursor - (x2 - self.x_offset) * 0.05 * TARGETRATIO;
    //NSLog(@"x = %.05f", x + OFFSET);
    if (scale >= 8) {
        scale = 8;
    } else if (scale < 0) {
        scale = 0;
    }
    
    if (scale >= 0 && scale < 2) {
        self.isZoomTargetted = true;
        self.isFlashTargetted = false;
        self.isImageTargetted = false;
        self.isExitTargetted = false;
    } else if (scale >= 2 && scale < 4) {
        self.isZoomTargetted = false;
        self.isFlashTargetted = true;
        self.isImageTargetted = false;
        self.isExitTargetted = false;
    } else if (scale >= 4 && scale < 6) {
        self.isZoomTargetted = false;
        self.isFlashTargetted = false;
        self.isImageTargetted = true;
        self.isExitTargetted = false;
    } else if (scale >= 6 && scale <= 8) {
        self.isZoomTargetted = false;
        self.isFlashTargetted = false;
        self.isImageTargetted = false;
        self.isExitTargetted = true;
    }
    self.targetCursor = scale;
 }

- (void)zoomSliderChangedByMotion {
    // zoom in -y, zoom out +y
    if ([self.gyro count] < 2) {
        return ;
    }
    CMGyroData *gyroData1 = self.gyro[[self.gyro count] - 2];
    float y1 = gyroData1.rotationRate.y;
    CMGyroData *gyroData2 = self.gyro[[self.gyro count] - 1];
    float y2 = gyroData2.rotationRate.y;
    if (fabs(y2 - y1) < 0.015 || fabs(y2 - y1) > 0.3) {
        return ;
    }
    float scale = self.currentZoomRate - (y2 - self.y_offset) * 0.05 * 80;
    if (scale > 8) {
        scale = 8;
    } else if (scale < 0.5) {
        scale = 0.5;
    }
    self.currentZoomRate = scale;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.zoomSlider setValue:self.currentZoomRate animated:YES];
        [self.zoomSliderRight setValue:self.currentZoomRate animated:YES];
    });
}

- (void)checkTaps {
    /*NSDate *date = [NSDate date];
     double timePassed_ms = [date timeIntervalSinceNow] * -1000.0;
     NSLog(@"Start time = %.05f", timePassed_ms);*/
    NSInteger number = [self countTaps];
    if (number > 1) {
        [self.gyro removeAllObjects];
        // NSString* s = [NSString stringWithFormat:@"Tap number = %ld", (long)number];
        NSLog(@"number = %ld", (long)number);
        //[self alertWithMessage:s];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.isHidden) {
                self.isHidden = false;
                [self resetTargetCursor];
                [self showAllcontrolsExceptZoom];
                return ;
            }
            if (self.isZoomTargetted) {
                if (self.zoomIsSelected) {
                    self.zoomIsSelected = false;
                    [self showAllcontrolsExceptZoom];
                } else {
                    self.zoomIsSelected = true;
                    [self hideAllControlsExceptZoom];
                }
                return ;
            }
            if (self.isFlashTargetted) {
                return ;
            }
            if (self.isImageTargetted) {
                return ;
            }
            if (self.isExitTargetted) {
                self.isHidden = true;
                [self hideAllControls];
                return ;
            }
        });
    }
    /*timePassed_ms = [date timeIntervalSinceNow] * -1000.0;
     NSLog(@"End time = %.05f", timePassed_ms);*/
}

- (NSInteger)countTaps {
    NSMutableArray* x_coodinate = [[NSMutableArray alloc] init];
    for (int i = 0; i < [self.gyro count]; i++) {
        CMGyroData *gyroData = self.gyro[i];
        NSNumber* x = [NSNumber numberWithFloat:gyroData.rotationRate.x];
        [x_coodinate addObject:x];
    }
    NSNumber* filter_wnd_t = [NSNumber numberWithInt:100]; //int
    NSNumber* filter_wnd = [NSNumber numberWithFloat:ceil(([filter_wnd_t intValue]* FREQUENCY) / 1000)]; //float
    // filter
    NSNumber* tapwidth_threshold = [NSNumber numberWithFloat:[filter_wnd floatValue] * 2]; // float
    NSInteger n = GAP_WND - 1; // int
    NSExpression *expression = [NSExpression expressionForFunction:@"stddev:" arguments:@[[NSExpression expressionForConstantValue:[x_coodinate subarrayWithRange:NSMakeRange(0, GAP_WND)]]]];
    NSNumber* fluc = [expression expressionValueWithObject:nil context:nil]; // float
    if ([fluc floatValue] < STABLE_THRESHOLD) {
        float stable_mean = [[[x_coodinate subarrayWithRange:NSMakeRange(0, GAP_WND)] valueForKeyPath:@"@avg.floatValue"] floatValue]; // float
        expression = [NSExpression expressionForFunction:@"stddev:" arguments:@[[NSExpression expressionForConstantValue:[x_coodinate subarrayWithRange:NSMakeRange(n + 1, TAP_WND)]]]];
        NSNumber* std = [expression expressionValueWithObject:nil context:nil];
        // test part
        /*if (fabs([y_coodinate[n + 1] floatValue] - stable_mean) > HIT_THRESHOLD * [fluc floatValue]) {
         NSLog(@"fabs = %f, hit = %f", fabs([y_coodinate[n + 1] floatValue] - stable_mean), HIT_THRESHOLD * [fluc floatValue]);
         if ([y_coodinate[n + 1] floatValue] > 0.05) {
         NSLog(@"std = %f, fluc = %f", [std floatValue], FLUC_THRESHOLD);
         } else {
         NSLog(@"std = %f, fluc = %f", [std floatValue], FLUC_THRESHOLD);
         }
         if ([std floatValue] > FLUC_THRESHOLD) {
         NSLog(@"std = %f, fluc = %f", [std floatValue], FLUC_THRESHOLD);
         }
         }*/
        if (fabs([x_coodinate[n + 1] floatValue] - stable_mean) > HIT_THRESHOLD * [fluc floatValue] && [std floatValue] > FLUC_THRESHOLD) {
            // probedata0 = (sensor(n:n+tap_wnd)-stable_mean);
            // fnd=find(probedata0<0);
            // probedata0(fnd)=0;
            NSMutableArray* probedata0 = [[NSMutableArray alloc] init];
            for (NSInteger i = n + 1; i < [x_coodinate count]; i++) {
                NSNumber* number = [NSNumber numberWithFloat:[x_coodinate[i] floatValue] - stable_mean > 0? [x_coodinate[i] floatValue] - stable_mean: 0];
                [probedata0 addObject:number];
            }
            // probedata = conv(probedata0,filter);
            NSMutableArray* probedata = [[NSMutableArray alloc] init];
            for (int i = 0; i < [probedata0 count]; i++) {
                NSNumber* number;
                if (i == 0 || i == [probedata0 count] - 1) {
                    number = [NSNumber numberWithFloat:[probedata0[i] floatValue]];
                } else {
                    number = [NSNumber numberWithFloat:[probedata0[i - 1] floatValue] * 0.1 + [probedata0[i] floatValue] * 0.8 + [probedata0[i + 1] floatValue] * 0.1];
                }
                [probedata addObject:number];
            }
            // probe = probedata>hit_threshold * fluc;
            // difprobe = diff(probe);
            // tapnum1=find(difprobe==1);
            // tapnum2=find(difprobe==-1);
            // if length(tapnum1)==length(tapnum2)                         % rising edge should equal falling edge
            //     tapwidth = tapnum2-tapnum1;
            //     if max(tapwidth)<=tapwidth_threshold                    % peak should not be too wide
            //         results(n+1:n+tap_wnd) = length(tapnum1);
            //     end
            // end
            bool started = false;
            NSInteger start = 0, end = 0, count = 0;
            for (int i = 0; i < [probedata count]; i++) {
                if (!started && [probedata[i] floatValue] > HIT_THRESHOLD * [fluc floatValue]) {
                    started = true;
                    start = i;
                }
                if (started && [probedata[i] floatValue] <= HIT_THRESHOLD * [fluc floatValue]) {
                    started = false;
                    end = i;
                    if (end - start > [tapwidth_threshold intValue])
                        return 0;
                    else {
                        count++;
                    }
                }
            }
            return count;
        }
    }
    return 0;
}

@end
