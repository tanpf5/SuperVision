//
//  SVScrollView.h
//  SuperVision+ Goggles
//
//  Created by Pengfei Tan on 7/1/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol SVScrollViewTouchDelegate
- (void)scrollViewDoubleTapped:(UIGestureRecognizer *)gesture;
- (void)scrollViewDidZoom:(UIScrollView *)scrollView;
@end

@interface SVScrollView : UIScrollView<UIScrollViewDelegate>
//  ImageView is used as render for image
@property (strong, nonatomic) UIImageView *imageView;
//  delegate to the view controller
@property (assign, nonatomic) id<SVScrollViewTouchDelegate> touchDelegate;
@end
