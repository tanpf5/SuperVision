//
//  ViewController.m
//  Tap Motion Test
//
//  Created by Pengfei Tan on 5/15/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

#import "ViewController.h"

#define FRENQUENCY 20

@interface ViewController ()

@end

@implementation ViewController

@synthesize motionManager = _motionManager;
@synthesize accelerometer_z = _accelerometer_z;
@synthesize accelerometer_zLock = _accelerometer_zLock;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.accelerometer_z = [[NSMutableArray alloc] init];
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.accelerometerUpdateInterval = 1 / FRENQUENCY;
    self.accelerometer_zLock = [[NSLock alloc] init];
    if ([self.motionManager isAccelerometerAvailable]){
        NSLog(@"Accelerometer is available.");
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        [self.motionManager
            startAccelerometerUpdatesToQueue: queue
            withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
                [self.accelerometer_zLock lock];
                NSLog(@"X = %.04f, Y = %.04f, Z = %.04f",accelerometerData.acceleration.x, accelerometerData.acceleration.y, accelerometerData.acceleration.z);
                if ([self.accelerometer_z count] < FRENQUENCY) {
                    [self.accelerometer_z addObject:accelerometerData];
                }
                else {
                    for (int i = 1; i < FRENQUENCY; i++) {
                        NSLog(@"i = %d", i);
                        //NSLog(@"i = %d, X = %.04f, Y = %.04f, Z = %.04f", i, accelerometerData.acceleration.x, accelerometerData.acceleration.y, accelerometerData.acceleration.z);
                        [self.accelerometer_z replaceObjectAtIndex:i - 1 withObject:[self.accelerometer_z objectAtIndex:i]];
                    }
                    [self.accelerometer_z replaceObjectAtIndex:FRENQUENCY - 1 withObject:accelerometerData];
                }
                [self.accelerometer_zLock unlock];
            }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
