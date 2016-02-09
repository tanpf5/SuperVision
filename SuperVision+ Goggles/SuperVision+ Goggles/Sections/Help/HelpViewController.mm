//
//  HelpViewController.mm
//  SuperVision+ Goggles
//
//  Created by Pengfei Tan on 7/8/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

#import "HelpViewController.h"

@interface HelpViewController ()

@end

@implementation HelpViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"HelperPage"];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [MobClick endLogPageView:@"HelperPage"];
}

- (IBAction)backButtonTapped {
    CGRect screenBounds = self.view.bounds;
    CGRect toFrame = CGRectMake(0.0f, screenBounds.size.height, screenBounds.size.width, screenBounds.size.height);
    [self willMoveToParentViewController:nil];
    [UIView animateWithDuration:0.3f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.view.frame = toFrame;
                     }
                     completion:^(BOOL finished) {
                         [self.view removeFromSuperview];
                     }];
    [self removeFromParentViewController];
}
@end
