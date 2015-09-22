//
//  SVHelpScrollView.m
//  SuperVision+ Goggles
//
//  Created by Pengfei Tan on 7/9/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

#import "SVHelpScrollView.h"

#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

@interface SVHelpScrollView ()

@property (nonatomic) float width;
@property (nonatomic) float height;

@end

@implementation SVHelpScrollView

@synthesize imageView;

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self initialBound];
        [self initialImageView];
        [self initialSettings];
    }
    return self;
}
- (void)initialBound {
    CGRect bounds = [[UIScreen mainScreen] bounds];
    if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        self.width = bounds.size.height;
        self.height = bounds.size.width;
    } else {
        self.width = bounds.size.width;
        self.height = bounds.size.height;
    }
}

- (void)initialSettings {
    self.delegate = self; // events will trigger the overload functions
    self.minimumZoomScale = 1.0;
    self.maximumZoomScale = 8.0;
    [self setZoomScale:1.0];
}

- (void)initialImageView {
    self.imageView = [[UIImageView alloc] init];
    UIImage *image = [UIImage imageNamed:@"help.png"];
    [self setContentSize:CGRectMake(0, 0, self.width, self.height).size];
    [self.imageView setFrame:CGRectMake(0, 0, self.width, image.size.height * self.width / image.size.width)];
    [self.imageView setContentMode:UIViewContentModeScaleAspectFit];
    self.imageView.image = image;
    [self addSubview:imageView];
}

#pragma mark
#pragma mark - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

@end
