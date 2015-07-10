//
//  SVHelpScrollView.m
//  SuperVision+ Goggles
//
//  Created by Pengfei Tan on 7/9/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

#import "SVHelpScrollView.h"

#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

@implementation SVHelpScrollView

@synthesize imageView;


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    [self initialSettings];
    [self initialImageView];
}

- (void)initialSettings {
    self.delegate = self; // events will trigger the overload functions
    self.minimumZoomScale = 1.0;
    self.maximumZoomScale = 8.0;
    [self setZoomScale:1.0];
}

- (void)initialImageView {
    self.imageView = self.subviews[0];
    UIImage * image = [UIImage imageNamed:@"help.png"];
    [self setContentSize:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height).size];
    [self.imageView setFrame:CGRectMake(0, 0, self.bounds.size.width, image.size.height * self.bounds.size.width / image.size.width)];
    NSLog(@"width = %f, height = %f", self.imageView.bounds.size.width, self.imageView.bounds.size.height);
    [self.imageView setContentMode:UIViewContentModeScaleAspectFit];
    self.imageView.image = image;
    
}

#pragma mark
#pragma mark - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

@end
