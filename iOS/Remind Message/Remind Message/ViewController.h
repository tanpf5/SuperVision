//
//  ViewController.h
//  Remind Message
//
//  Created by Pengfei Tan on 5/29/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (strong, nonatomic) IBOutlet UIButton *button;
@property (strong, nonatomic) IBOutlet UILabel *message;

- (IBAction)buttonTapped:(id)sender;

@end

