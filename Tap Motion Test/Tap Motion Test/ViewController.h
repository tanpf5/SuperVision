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
// y-coodinate
@property (strong, nonatomic) NSMutableArray* accelerometer;
@property (strong, nonatomic) NSLock* accelerometerLock;
// x-coodinate
@property (strong, nonatomic) NSMutableArray* gyro;
@property (strong, nonatomic) NSLock* gyroLock;
//@property (assign, nonatomic) BOOL isShown;
@property (strong, nonatomic) IBOutlet UILabel *menu;
@property (strong, nonatomic) IBOutlet UILabel *menuRight;

@end

