//
//  HUMSlider.h
//  HUMSliderSample
//
//  Created by Ellen Shapiro on 12/26/14.
//  Copyright (c) 2014 Just Hum, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HUMSlider : UISlider

#pragma mark - Section data

///The color of the ticks you wish to pop up.
@property (nonatomic) UIColor *tickColor;

///How many sections of ticks should be created. NOTE: Needs to be an odd number or math falls apart. Defaults to 9. 
@property (nonatomic) NSInteger sectionCount;

@end
