//
//  ViewController.m
//  Tap Motion Test
//
//  Created by Pengfei Tan on 5/15/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

#import "ViewController.h"

#define FREQUENCY 100
#define TIME_THRESHOLD 1
#define TAP_WND TIME_THRESHOLD * FREQUENCY
#define FLUC_WND 0.6 * TAP_WND
#define GAP_WND FLUC_WND
#define STABLE_THRESHOLD_ACC 0.015
#define FLUC_THRESHOLD_ACC 0.025
#define HIT_THRESHOLD_ACC 3.5
#define TRIPLE_THRESHOLD_ACC 0.02
#define STABLE_THRESHOLD_GYRO 0.03
#define FLUC_THRESHOLD_GYRO 0.07
#define HIT_THRESHOLD_GYRO 3

@interface ViewController ()

@end

@implementation ViewController

@synthesize motionManager = _motionManager;
@synthesize accelerometer = _accelerometer;
@synthesize accelerometerLock = _accelerometerLock;
@synthesize gyro = _gyro;
@synthesize gyroLock = _gyroLock;
//@synthesize isShown = _isShown;
@synthesize message = _message;
@synthesize messageRight = _messageRight;

- (void) showMessage:(NSString*)s {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.message.text = s;
        self.messageRight.text = s;
        [self.message setHidden:NO];
        [self.messageRight setHidden:NO];
    });
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.message setHidden:YES];
        [self.messageRight setHidden:YES];
    });
}

- (void)checkTaps:(NSArray *)data stable_thre:(float)stableThreshold fluc_thre:(float)flucThreshold hit_thre:(float)hitThreshold  {
    /*NSDate *date = [NSDate date];
    double timePassed_ms = [date timeIntervalSinceNow] * -1000.0;
    NSLog(@"Start time = %.05f", timePassed_ms);*/
    NSInteger number = [self countTaps:data stable_thre:stableThreshold fluc_thre:flucThreshold hit_thre:hitThreshold];
    if (number > 1) {
        [self.accelerometer removeAllObjects];
        // NSString* s = [NSString stringWithFormat:@"Tap number = %ld", (long)number];
        //NSLog(@"number = %ld", (long)number);
        //[self alertWithMessage:s];
        [self showMessage:[NSString stringWithFormat:@"n = %ld", (long)number]];
    }
    /*timePassed_ms = [date timeIntervalSinceNow] * -1000.0;
    NSLog(@"End time = %.05f", timePassed_ms);*/
}

- (NSNumber *)meanOf:(NSArray *)array
{
    double runningTotal = 0.0;
    
    for(NSNumber *number in array)
    {
        runningTotal += [number doubleValue];
    }
    
    return [NSNumber numberWithDouble:(runningTotal / [array count])];
}

- (NSNumber *)std:(NSArray *)array
{
    if(![array count]) return nil;
    
    double mean = [[self meanOf:array] doubleValue];
    double sumOfSquaredDifferences = 0.0;
    
    for(NSNumber *number in array)
    {
        double valueOfNumber = [number doubleValue];
        double difference = valueOfNumber - mean;
        sumOfSquaredDifferences += difference * difference;
    }
    
    return [NSNumber numberWithDouble:sqrt(sumOfSquaredDifferences / ([array count] - 1))];
}

- (NSInteger)countTaps:(NSArray *)data stable_thre:(float)stableThreshold fluc_thre:(float)flucThreshold hit_thre:(float)hitThreshold {
    NSInteger filter_wnd_t = 100;
    NSInteger filter_wnd = ceil((filter_wnd_t * FREQUENCY) / 1000);
    // filter
    NSInteger tapwidth_threshold = filter_wnd * 2.5;
    NSInteger n = GAP_WND - 1; // int
//    NSExpression *expression = [NSExpression expressionForFunction:@"stddev:" arguments:@[[NSExpression expressionForConstantValue:[data subarrayWithRange:NSMakeRange(0, GAP_WND)]]]];
//    NSNumber* fluc = [expression expressionValueWithObject:nil context:nil]; // float
    NSNumber* fluc = [self std:[data subarrayWithRange:NSMakeRange(0, GAP_WND)]];
    if ([fluc floatValue] < stableThreshold) {
        double stable_mean = [[[data subarrayWithRange:NSMakeRange(0, GAP_WND)] valueForKeyPath:@"@avg.floatValue"] floatValue]; // float
        //expression = [NSExpression expressionForFunction:@"stddev:" arguments:@[[NSExpression expressionForConstantValue:[data subarrayWithRange:NSMakeRange(n + 1, TAP_WND)]]]];
        //NSNumber* std = [expression expressionValueWithObject:nil context:nil];
        NSNumber* std = [self std:[data subarrayWithRange:NSMakeRange(n + 1, FLUC_WND)]];
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
        if (fabs([data[n + 1] floatValue] - stable_mean) > hitThreshold * [fluc floatValue] && [std floatValue] > flucThreshold) {
            // probedata0 = (sensor(n:n+tap_wnd)-stable_mean);
            // fnd=find(probedata0<0);
            // probedata0(fnd)=0;
            NSMutableArray* probedata0 = [[NSMutableArray alloc] init];
            for (int i = n + 1; i < [data count]; i++) {
                NSNumber* number = [NSNumber numberWithFloat:[data[i] floatValue] - stable_mean > 0? [data[i] floatValue] - stable_mean: 0];
                [probedata0 addObject:number];
            }
            // probedata = conv(probedata0,filter);
            NSMutableArray* probedata = [[NSMutableArray alloc] init];
            for (int i = 0; i < [probedata0 count]; i++) {
                NSNumber* number;
                if (i == 0 || i == [probedata0 count] - 1) {
                    number = [NSNumber numberWithFloat:[probedata0[i] floatValue]];
                } else {
                    number = [NSNumber numberWithFloat:[probedata0[i - 1] floatValue] * 0.25 + [probedata0[i] floatValue] * 0.5 + [probedata0[i + 1] floatValue] * 0.25];
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
                if (!started && [probedata[i] floatValue] > hitThreshold * [fluc floatValue]) {
                    started = true;
                    start = i;
                }
                if (started && [probedata[i] floatValue] <= hitThreshold * [fluc floatValue]) {
                    started = false;
                    end = i;
                    if (end - start > tapwidth_threshold)
                        return 0;
                    else {
                        count++;
                    }
                }
            }
            float a = [[self std:[data subarrayWithRange:NSMakeRange(n + 1 + FLUC_WND - 2, TAP_WND - FLUC_WND)]] floatValue];
            if (count >= 3 && [[self std:[data subarrayWithRange:NSMakeRange(n + 1 + FLUC_WND - 2, TAP_WND - FLUC_WND)]] floatValue] < TRIPLE_THRESHOLD_ACC) {
                count--;
            }
            return count;
        }
    }
    return 0;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.accelerometer = [[NSMutableArray alloc] init];
    self.gyro = [[NSMutableArray alloc] init];
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.accelerometerUpdateInterval = 1.0 / FREQUENCY;
    self.motionManager.gyroUpdateInterval = 1.0 / FREQUENCY;
    self.accelerometerLock = [[NSLock alloc] init];
    self.gyroLock = [[NSLock alloc] init];
    [self.message setHidden:YES];
    [self.messageRight setHidden:YES];
    //float a = CGRectGetHeight([[UIScreen mainScreen] bounds]) / 2;
    //float b = CGRectGetWidth([[UIScreen mainScreen] bounds]) / 2;
    if ([self.motionManager isAccelerometerAvailable] && [self.motionManager isGyroAvailable]){
        //NSLog(@"Accelerometer is available.");
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        [self.motionManager
            startAccelerometerUpdatesToQueue: queue
            withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
                 NSLog(@"acc, %.00f, %.10f, %.10f, %.10f", CFAbsoluteTimeGetCurrent() * 1000000000, accelerometerData.acceleration.x, accelerometerData.acceleration.y, accelerometerData.acceleration.z);
                [self.accelerometerLock lock];
                if ([self.accelerometer count] < GAP_WND + TAP_WND) {
                    [self.accelerometer addObject:[[NSNumber alloc] initWithDouble:accelerometerData.acceleration.y]];
                    if ([self.accelerometer count] == GAP_WND + TAP_WND) {
                        if (fabs(accelerometerData.acceleration.x) > 0.5 && fabs(accelerometerData.acceleration.y) < 0.5 && fabs(accelerometerData.acceleration.z) < 0.5) {
                            [self checkTaps:self.accelerometer stable_thre:STABLE_THRESHOLD_ACC fluc_thre:FLUC_THRESHOLD_ACC hit_thre:HIT_THRESHOLD_ACC];
                        }
                    }
                }
                else {
                    for (int i = 1; i < GAP_WND + TAP_WND; i++) {
                        [self.accelerometer replaceObjectAtIndex:i - 1 withObject:[self.accelerometer objectAtIndex:i]];
                    }
                    [self.accelerometer replaceObjectAtIndex:GAP_WND + TAP_WND - 1 withObject:[[NSNumber alloc] initWithDouble:accelerometerData.acceleration.y]];
                    if (fabs(accelerometerData.acceleration.x) > 0.5 && fabs(accelerometerData.acceleration.y) < 0.5 && fabs(accelerometerData.acceleration.z) < 0.5) {
                        [self checkTaps:self.accelerometer stable_thre:STABLE_THRESHOLD_ACC fluc_thre:FLUC_THRESHOLD_ACC hit_thre:HIT_THRESHOLD_ACC];
                    }
                }
                [self.accelerometerLock unlock];
            }];
        [self.motionManager
            startGyroUpdatesToQueue:queue withHandler:^(CMGyroData *gyroData, NSError *error) {
                //NSLog(@"gyr, %.00f, %.10f, %.10f, %.10f", CFAbsoluteTimeGetCurrent() * 100000000, gyroData.rotationRate.x, gyroData.rotationRate.y, gyroData.rotationRate.z);
                /*[self.gyroLock lock];
                if ([self.gyro count] < GAP_WND + TAP_WND) {
                    [self.gyro addObject:gyroData];
                    if ([self.gyro count] == GAP_WND + TAP_WND) {
                        [self checkTaps:STABLE_THRESHOLD_GYRO fluc_thre:FLUC_THRESHOLD_GYRO hit_thre:HIT_THRESHOLD_GYRO];
                    }
                 }
                 else {
                     for (int i = 1; i < GAP_WND + TAP_WND; i++) {
                         [self.gyro replaceObjectAtIndex:i - 1 withObject:[self.gyro objectAtIndex:i]];
                     }
                     [self.gyro replaceObjectAtIndex:GAP_WND + TAP_WND - 1 withObject:gyroData];
                     [self checkTaps:STABLE_THRESHOLD_GYRO fluc_thre:FLUC_THRESHOLD_GYRO hit_thre:HIT_THRESHOLD_GYRO];
                 }
                [self.gyroLock unlock];*/
            }];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
