//
//  SVHelpScrollView.h
//  SuperVision+ Goggles
//
//  Created by Pengfei Tan on 7/9/15.
//  Copyright (c) 2015 Massachusetts Eye and Ear Infirmary. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SVHelpScrollView : UIScrollView<UIScrollViewDelegate>
//  ImageView is used as render for image
@property (strong, nonatomic) UIImageView *imageView;

@end
