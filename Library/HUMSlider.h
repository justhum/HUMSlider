//
//  HUMSlider.h
//  HUMSliderSample
//
//  Created by Ellen Shapiro on 12/26/14.
//  Copyright (c) 2014 Just Hum, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HUMSlider : UISlider

#pragma mark - Ticks

///The color of the ticks you wish to pop up. Defaults to dark gray.
@property (nonatomic) UIColor *tickColor;

///How many sections of ticks should be created. NOTE: Needs to be an odd number or math falls apart. Defaults to 9. 
@property (nonatomic) NSInteger sectionCount;

#pragma mark - Images

///The image to be displayed to the left of the slider.
@property (nonatomic) UIImage *leftSideImage;

///The image to be displayed to the right side of the slider.
@property (nonatomic) UIImage *rightSideImage;

///The color to use as the fully-saturated color. Defaults to red.
@property (nonatomic) UIColor *saturatedColor;

///The color to use as the desaturated color. Defaults to light gray.
@property (nonatomic) UIColor *desaturatedColor;

@end
