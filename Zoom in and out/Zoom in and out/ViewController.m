//
//  ViewController.m
//  Zoom in and out
//
//  Created by Pengfei Tan on 5/26/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

#import "ViewController.h"

#define SLIDERWIDTH 44
#define SLIDERHEIGHT 250
#define degreeToRadians(x) (M_PI * x / 180.0)
#define SLIDERTHUMB "sliderthumb2.png"

//doubleTaps
#define TAP_WND 20
#define GAP_WND TAP_WND * 0.8
#define FREQUENCY 20
#define STABLE_THRESHOLD 0.03
#define FLUC_THRESHOLD 0.05
#define HIT_THRESHOLD 3

@interface ViewController ()

@end

@implementation ViewController

@synthesize sliderBackground = _sliderBackground;
@synthesize sliderBackgroundRight = _sliderBackgroundRight;
@synthesize zoomSlider = _zoomSlider;
@synthesize zoomSliderRight = _zoomSliderRight;
@synthesize currentZoomRate = _currentZoomRate;
@synthesize isHidden = _isHidden;

@synthesize motionManager = _motionManager;
@synthesize gyro = _gyro;
@synthesize gyroLock = _gyroLock;

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
                [self showAllcontrols];
            } else {
                [self hideAllControls];
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
            for (int i = n + 1; i < [x_coodinate count]; i++) {
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


- (void) zoomSliderChangedByMotion:(float)y {
    // zoom in -y, zoom out +y
    float scale = self.currentZoomRate - y * 0.05 * 10;
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
              NSLog(@"gyr, %.00f, %.05f, %.05f, %.05f", CFAbsoluteTimeGetCurrent() * 100000000, gyroData.rotationRate.x, gyroData.rotationRate.y, gyroData.rotationRate.z);
             if (!self.isHidden) {
                 [self zoomSliderChangedByMotion:gyroData.rotationRate.y];
             }
             [self.gyroLock lock];
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
             [self.gyroLock unlock];
         }];
    }
    
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
    self.currentZoomRate = 1;
    
    [self hideAllControls];
}

- (void)hideAllControls {
    self.isHidden = true;
    [self.zoomSlider setHidden:YES];
    [self.zoomSliderRight setHidden:YES];
    [self.sliderBackground setHidden:YES];
    [self.sliderBackgroundRight setHidden:YES];
}

//  show all interface controls
- (void)showAllcontrols {
    self.isHidden = false;
    [self.zoomSlider setHidden:NO];
    [self.zoomSliderRight setHidden:NO];
    [self.sliderBackground setHidden:NO];
    [self.sliderBackgroundRight setHidden:NO];
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

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initialControls];
    [self initialViewPosition];
    [self initialMotion];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
