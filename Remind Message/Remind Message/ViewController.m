//
//  ViewController.m
//  Remind Message
//
//  Created by Pengfei Tan on 5/29/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize button = _button;
@synthesize message = _message;

- (void)initailSetting {
    [self.message setHidden:YES];
}

- (void)viewDidLoad {
    [self initailSetting];
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) displayMessage:(NSString*)s {
    self.message.text = s;
    [self.message setHidden:NO];
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.message setHidden:YES];
    });
}

- (IBAction)buttonTapped:(id)sender {
    [self displayMessage:@"Successful"];

}
@end
