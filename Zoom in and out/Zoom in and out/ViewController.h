//
//  ViewController.h
//  Zoom in and out
//
//  Created by Pengfei Tan on 5/26/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>

@interface ViewController : UIViewController
@property (strong, nonatomic) IBOutlet UIImageView *sliderBackground;
@property (strong, nonatomic) IBOutlet UIImageView *sliderBackgroundRight;
@property (strong, nonatomic) IBOutlet UISlider *zoomSlider;
@property (strong, nonatomic) IBOutlet UISlider *zoomSliderRight;
@property (assign, nonatomic) float currentZoomRate;
@property (assign, nonatomic) bool isHidden;

//doubleTaps
@property (strong, nonatomic) CMMotionManager* motionManager;
@property (strong, nonatomic) NSMutableArray* gyro;
@property (strong, nonatomic) NSLock* gyroLock;


- (IBAction)zoomSliderChanged:(id)sender;
- (void)zoomSliderChangedByMotion:(float)y;


@end

