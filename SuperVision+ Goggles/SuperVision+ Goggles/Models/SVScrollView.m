//
//  SVScrollView.m
//  SuperVision+ Goggles
//
//  Created by Pengfei Tan on 7/1/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

#import "SVScrollView.h"

@implementation SVScrollView

@synthesize imageView;
@synthesize touchDelegate;


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc]
                                                initWithTarget:self
                                                action:@selector
                                                (handleDoubleTap:)];
    [doubleTapGesture setNumberOfTapsRequired:2];
    [self addGestureRecognizer:doubleTapGesture];
}

- (void)handleDoubleTap:(UIGestureRecognizer *)gesture {
    if (([gesture state] == UIGestureRecognizerStateEnded) || ([gesture state] == UIGestureRecognizerStateFailed))
        [self touchesEnded:nil withEvent:nil];
    [self.touchDelegate handleDoubleTap:gesture];
}

#pragma mark
#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self.touchDelegate scrollViewDidZoom:scrollView];
}
@end
