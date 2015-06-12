//
//  ViewController.m
//  Magnet
//
//  Created by Pengfei Tan on 6/11/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

#import "ViewController.h"
#import "MagnetSensor.h"

@interface ViewController ()

@end

@implementation ViewController
@synthesize message = _message;
@synthesize messageRight = _messageRight;

- (void)viewDidLoad {
    CardboardSDK::MagnetSensor *_magnetSensor;
    _magnetSensor =new CardboardSDK::MagnetSensor();
    _magnetSensor->start();
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(magneticTriggerPressed)
                                                 name:CardboardSDK::CBDTriggerPressedNotification
                                               object:nil];
    [super viewDidLoad];
    [self.message setHidden:YES];
    [self.messageRight setHidden:YES];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

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

- (void)magneticTriggerPressed
{
    [self showMessage:@"trigger"];
}

@end
