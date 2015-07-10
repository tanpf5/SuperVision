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

@synthesize backButton;
@synthesize scrollView;

- (void)viewDidLoad {
    [super viewDidLoad];
    //[self initialView];
}

- (void)initialView {
    //[self.scrollView setInitialImageView:[UIImage imageNamed:@"help.png"]];
    //[self.scrollView.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.scrollView setMinimumZoomScale:1];
    [self.scrollView setMinimumZoomScale:8];
    [self.scrollView setZoomScale:1];
    [self.scrollView setBounces:YES];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)backButtonTapped {
    [self willMoveToParentViewController:nil];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}
@end
