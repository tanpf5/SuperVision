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

- (void)viewDidLoad {

}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    [self initalSettings];
    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc]
                                                initWithTarget:self
                                                action:@selector
                                                (scrollViewDoubleTapped:)];
    [doubleTapGesture setNumberOfTapsRequired:2];
    [self addGestureRecognizer:doubleTapGesture];
    [self initImageView];
}

- (void)initalSettings {
    self.delegate = self; // events will trigger the overload functions
    [self setScrollEnabled:NO]; // disable scroll
    self.minimumZoomScale = 0.5;
    self.maximumZoomScale = 8;
    [self setZoomScale:1];
}

- (void)initImageView {
    self.imageView = self.subviews[0];
    self.imageView.image = [UIImage imageNamed:@"SV_GoggleIcon-60@3x.png"];
    [self.imageView setContentMode:UIViewContentModeCenter];
}

- (void)scrollViewDoubleTapped:(UIGestureRecognizer *)gesture {
    if (([gesture state] == UIGestureRecognizerStateEnded) || ([gesture state] == UIGestureRecognizerStateFailed))
        [self touchesEnded:nil withEvent:nil];
    [self.touchDelegate scrollViewDoubleTapped:gesture];
}
- (void) scrollToCenter {
    CGPoint toCenter = CGPointMake(self.contentSize.width/2 - self.frame.size.width/2, self.contentSize.height/2 - self.frame.size.height/2);
    [self setContentOffset:toCenter animated:NO];
}

#pragma mark
#pragma mark - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self scrollToCenter];
    [self.touchDelegate scrollViewDidZoom:scrollView];
}
@end
