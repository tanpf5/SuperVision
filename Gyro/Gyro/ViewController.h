//
//  ViewController.h
//  Gyro
//
//  Created by 谭鹏飞 on 5/24/15.
//  Copyright (c) 2015 Pengfei Tan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>

@interface ViewController : UIViewController

@property (strong, nonatomic) CMMotionManager *manager;

@end

