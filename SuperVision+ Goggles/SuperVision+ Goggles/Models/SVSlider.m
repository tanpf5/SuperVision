//
//  SVSlider.m
//  SuperVision+ Goggles
//
//  Created by Pengfei Tan on 6/30/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

#import "SVSlider.h"

NSString * const EMPTY = @"empty.png";
NSString * const SLIDERTHUMB = @"sliderthumb.png";

@implementation SVSlider


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    UIImage *maxImage = [UIImage imageNamed:EMPTY];
    UIImage *minImage = [UIImage imageNamed:EMPTY];
    UIImage *thumbImage = [UIImage imageWithCGImage:[[UIImage imageNamed:SLIDERTHUMB] CGImage] scale:1.5 orientation:UIImageOrientationUp];
    [self setMaximumTrackImage:maxImage forState:UIControlStateNormal];
    [self setMinimumTrackImage:minImage forState:UIControlStateNormal];
    [self setThumbImage:thumbImage forState:UIControlStateNormal];
    CGAffineTransform transformRotate = CGAffineTransformMakeRotation(M_PI * 0.5);
    self.transform = transformRotate;
}


@end
