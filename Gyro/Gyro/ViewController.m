//
//  ViewController.m
//  Gyro
//
//  Created by 谭鹏飞 on 5/24/15.
//  Copyright (c) 2015 Pengfei Tan. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize manager = _manager;


- (void)viewDidLoad {
    [super viewDidLoad];
    self.manager = [[CMMotionManager alloc] init];
    self.manager.gyroUpdateInterval = 0.05;
    if (self.manager.gyroAvailable) {
        [self.manager startGyroUpdatesToQueue:[[NSOperationQueue alloc] init] withHandler:^(CMGyroData *gyroData, NSError *error) {
            NSLog(@"gyr, %.00f, %.05f, %.05f, %.05f", [[NSDate date] timeIntervalSince1970] * 1000000000, gyroData.rotationRate.x, gyroData.rotationRate.y, gyroData.rotationRate.z);
        }];
    }
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
