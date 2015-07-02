//
//  ViewController.h
//  Menu Control
//
//  Created by Pengfei Tan on 5/27/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>

@interface ViewController : UIViewController
@property (strong, nonatomic) IBOutlet UIButton *zoom;
@property (strong, nonatomic) IBOutlet UIButton *flash;
@property (strong, nonatomic) IBOutlet UIButton *image;
@property (strong, nonatomic) IBOutlet UIButton *exit;
@property (strong, nonatomic) IBOutlet UIButton *zoomRight;
@property (strong, nonatomic) IBOutlet UIButton *flashRight;
@property (strong, nonatomic) IBOutlet UIButton *imageRight;
@property (strong, nonatomic) IBOutlet UIButton *exitRight;

//  zoom
@property (strong, nonatomic) IBOutlet UIImageView *sliderBackground;
@property (strong, nonatomic) IBOutlet UIImageView *sliderBackgroundRight;
@property (strong, nonatomic) IBOutlet UISlider *zoomSlider;
@property (strong, nonatomic) IBOutlet UISlider *zoomSliderRight;


@end

