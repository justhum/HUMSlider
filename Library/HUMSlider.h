//
//  HUMSlider.h
//  HUMSliderSample
//
//  Created by Ellen Shapiro on 12/26/14.
//  Copyright (c) 2014 Just Hum, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, HUMSliderSide) {
    HUMSliderSideLeft,
    HUMSliderSideRight
};

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

///The color to use as the fully-saturated color on both sides. Defaults to red.
@property (nonatomic) UIColor *saturatedColor;

///The color to use as the desaturated color on both sides. Defaults to light gray.
@property (nonatomic) UIColor *desaturatedColor;

#pragma mark - Configurable Animation Durations

///How long it should take to adjust tick alpha. Defaults to .2 seconds.
@property (nonatomic) NSTimeInterval tickAlphaAnimationDuration;

///How long it takes most ticks to pop up from hidden. Defaults to .5 seconds.
@property (nonatomic) NSTimeInterval tickMovementAnimationDuration;

///How long it takes the tick on either side of the middle tick pop up from hidden. Defaults to .35 seconds.
@property (nonatomic) NSTimeInterval secondTickMovementAndimationDuration;

///How long to wait between animating secondary ticks. Defaults to 0.025 seconds.
@property (nonatomic) NSTimeInterval nextTickAnimationDelay;


#pragma mark - Setters/Getters for individual sides

/**
 *  Sets the color to use as the fully-saturated color on selected side.
 *
 *  @param saturatedColor The UIColor to use
 *  @param side The side you wish to set a specific saturated color upon.
 */
- (void)setSaturatedColor:(UIColor *)saturatedColor forSide:(HUMSliderSide)side;

/**
 *  @param side The HUMSliderSide you wish to check.
 *  @return The current color for the selected side
 */
- (UIColor *)saturatedColorForSide:(HUMSliderSide)side;

/**
 *  Sets the color to use as the desaturated color on selected side.
 *
 *  @param saturatedColor The UIColor to use
 *  @param side The side you wish to set a desaturated color upon.
 */
- (void)setDesaturatedColor:(UIColor *)desaturatedColor forSide:(HUMSliderSide)side;

/**
 *  @param side HUMSliderSide (left or right)
 *  @return The current desaturated color for the selected side.
 */
- (UIColor *)desaturatedColorForSide:(HUMSliderSide)side;

@end
