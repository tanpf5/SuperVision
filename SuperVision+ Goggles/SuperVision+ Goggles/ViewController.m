//
//  ViewController.m
//  SuperVision+ Goggles
//
//  Created by Pengfei Tan on 6/2/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
//  User Interface Control
@property (assign, nonatomic) BOOL isMenuHidden;
@property (assign, nonatomic) BOOL isButtonHidden;


@end

@implementation ViewController
//  User Interface
// scroll views
@synthesize scrollViewLeft;
@synthesize scrollViewRight;

// menu items
@synthesize zoomItemLeft;
@synthesize zoomItemRight;
@synthesize flashItemLeft;
@synthesize flashItemRight;
@synthesize imageItemLeft;
@synthesize imageItemRight;
@synthesize exitItemLeft;
@synthesize exitItemRight;
@synthesize isMenuHidden; // all menu items

// buttons
@synthesize flashButtonLeft;
@synthesize flashButtonRight;
@synthesize imageButtonLeft;
@synthesize imageButtonRight;
@synthesize infoButtonLeft;
@synthesize infoButtonRight;
@synthesize isButtonHidden; // all buttons

// messages
@synthesize messageLeft;
@synthesize messageRight;

#pragma mark -
#pragma mark Initial Functions

- (void)viewDidLoad {
    [self initialView];
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)initialView {
    self.isMenuHidden = true;
    self.isButtonHidden = true;
    [self hideAllControls];
}

- (void)hideAllControls {
    //  Menu
    [self.zoomItemLeft setHidden:YES];
    [self.zoomItemRight setHidden:YES];
    [self.flashItemLeft setHidden:YES];
    [self.flashItemRight setHidden:YES];
    [self.imageItemLeft setHidden:YES];
    [self.imageItemRight setHidden:YES];
    [self.exitItemLeft setHidden:YES];
    [self.exitItemRight setHidden:YES];
    //  Buttons
    [self.flashButtonLeft setHidden:YES];
    [self.flashButtonRight setHidden:YES];
    [self.imageButtonLeft setHidden:YES];
    [self.imageButtonRight setHidden:YES];
    [self.infoButtonLeft setHidden:YES];
    [self.infoButtonRight setHidden:YES];
    //  Zoom sliders
    [self.zoomSliderLeft setHidden:YES];
    [self.zoomSliderRight setHidden:YES];
    //  Messages
    [self.messageLeft setHidden:YES];
    [self.messageRight setHidden:YES];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
