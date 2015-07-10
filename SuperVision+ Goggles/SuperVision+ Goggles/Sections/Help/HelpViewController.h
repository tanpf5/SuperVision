//
//  HelpViewController.h
//  SuperVision+ Goggles
//
//  Created by Pengfei Tan on 7/8/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVHelpScrollView.h"

@interface HelpViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIButton *backButton;
@property (strong, nonatomic) IBOutlet SVHelpScrollView *scrollView;


- (IBAction)backButtonTapped;
@end
