
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

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self initialSettings];
        [self initialImageView];
    }
    return self;
}

- (void)initialSettings {
    self.delegate = self; // events will trigger the overload functions
    [self setScrollEnabled:NO]; // disable scroll
    self.maximumZoomScale = 8;
    // add double tap gesture
    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc]
                                                initWithTarget:self
                                                action:@selector
                                                (scrollViewDoubleTapped:)];
    [doubleTapGesture setNumberOfTapsRequired:2];
    [self addGestureRecognizer:doubleTapGesture];
    // disable pinch and pan
    for (UIGestureRecognizer* recog in self.gestureRecognizers) {
        if ([recog isKindOfClass:[UIPanGestureRecognizer class]])
            [self removeGestureRecognizer:recog];
        if ([recog isKindOfClass:[UIPinchGestureRecognizer class]] )
            [self removeGestureRecognizer:recog];
    }
}

- (void)initialImageView {
    self.imageView = [[UIImageView alloc] init];
    [self.imageView setContentMode:UIViewContentModeCenter];
    [self addSubview:imageView];
}

- (void)changeImageViewFrame:(CGRect) frame {
    self.contentSize = frame.size;
    [self.imageView setFrame:frame];
    [self adjustImageViewCenter];
    [self scrollToCenter];
}

- (void) scrollToCenter {
    CGPoint toCenter = CGPointMake(self.contentSize.width/2 - self.frame.size.width/2, self.contentSize.height/2 - self.frame.size.height/2);
    [self setContentOffset:toCenter animated:NO];
}

- (void)adjustImageViewCenter {
    CGFloat offsetX = (self.bounds.size.width > self.contentSize.width)?
    (self.bounds.size.width - self.contentSize.width) * 0.5 : 0.0;
    CGFloat offsetY = (self.bounds.size.height > self.contentSize.height)?
    (self.bounds.size.height - self.contentSize.height) * 0.5 : 0.0;
    self.imageView.center = CGPointMake(self.contentSize.width * 0.5 + offsetX, self.contentSize.height * 0.5 + offsetY);
}

- (void)setImage:(UIImage *)image {
    [self.imageView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:YES];
}

- (void)scrollViewDoubleTapped:(UIGestureRecognizer *)gesture {
    if (([gesture state] == UIGestureRecognizerStateEnded) || ([gesture state] == UIGestureRecognizerStateFailed))
        [self touchesEnded:nil withEvent:nil];
    [self.touchDelegate scrollViewDoubleTapped:gesture];
}

#pragma mark
#pragma mark - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

@end
