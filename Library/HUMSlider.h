//
//  HUMSlider.h
//  HUMSliderSample
//
//  Created by Ellen Shapiro on 12/26/14.
//  Copyright (c) 2014 Just Hum, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * A slider which pops up ticks and saturates/desaturates images when the user adjusts
 * a slider for better feedback to the user about their adjustment.
 *
 * NOTE: This is not using IBDesignable in order to maintain compatibility with
 *       iOS 7. *sad trombone*
 */
@interface HUMSlider : UISlider

#pragma mark - Ticks

///The color of the ticks you wish to pop up. Defaults to dark gray.
@property (nonatomic) UIColor *tickColor;

///How many sections of ticks should be created. NOTE: Needs to be an odd number or math falls apart. Defaults to 9. 
@property (nonatomic) NSUInteger sectionCount;

///How many points the tick popping should be adjusted for a custom thumbnail image to account for any space at the top (for example, to balance out a custom shadow).
@property (nonatomic) CGFloat pointAdjustmentForCustomThumb;

#pragma mark - Images

///The color to use as the fully-saturated color. Defaults to red.
@property (nonatomic) UIColor *saturatedColor;

///The color to use as the desaturated color. Defaults to light gray.
@property (nonatomic) UIColor *desaturatedColor;

@end
