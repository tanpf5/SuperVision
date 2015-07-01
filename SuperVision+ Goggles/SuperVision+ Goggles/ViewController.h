//
//  ViewController.h
//  SuperVision+ Goggles
//
//  Created by Pengfei Tan on 6/2/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVScrollView.h"
#import "SVSlider.h"

@interface ViewController : UIViewController

//  User Interface
// scroll views
@property (strong, nonatomic) IBOutlet SVScrollView *scrollViewLeft;
@property (strong, nonatomic) IBOutlet SVScrollView *scrollViewRight;

// menu items
@property (strong, nonatomic) IBOutlet UIButton *zoomItemLeft;
@property (strong, nonatomic) IBOutlet UIButton *zoomItemRight;
@property (strong, nonatomic) IBOutlet UIButton *flashItemLeft;
@property (strong, nonatomic) IBOutlet UIButton *flashItemRight;
@property (strong, nonatomic) IBOutlet UIButton *imageItemLeft;
@property (strong, nonatomic) IBOutlet UIButton *imageItemRight;
@property (strong, nonatomic) IBOutlet UIButton *exitItemLeft;
@property (strong, nonatomic) IBOutlet UIButton *exitItemRight;

// buttons
@property (strong, nonatomic) IBOutlet UIButton *flashButtonLeft;
@property (strong, nonatomic) IBOutlet UIButton *flashButtonRight;
@property (strong, nonatomic) IBOutlet UIButton *imageButtonLeft;
@property (strong, nonatomic) IBOutlet UIButton *imageButtonRight;
@property (strong, nonatomic) IBOutlet UIButton *infoButtonLeft;
@property (strong, nonatomic) IBOutlet UIButton *infoButtonRight;

// zoom sliders
@property (strong, nonatomic) IBOutlet SVSlider *zoomSliderLeft;
@property (strong, nonatomic) IBOutlet SVSlider *zoomSliderRight;

// messages
@property (strong, nonatomic) IBOutlet UILabel *messageLeft;
@property (strong, nonatomic) IBOutlet UILabel *messageRight;




@end

