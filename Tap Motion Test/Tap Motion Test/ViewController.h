//
//  ViewController.h
//  Tap Motion Test
//
//  Created by Pengfei Tan on 5/15/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>

@interface ViewController : UIViewController

@property (strong, nonatomic) CMMotionManager* motionManager;
@property (strong, nonatomic) NSMutableArray* accelerometer_z;
@property (strong, nonatomic) NSLock* accelerometer_zLock;
@end

