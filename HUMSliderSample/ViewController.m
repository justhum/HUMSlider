//
//  ViewController.m
//  HUMSliderSample
//
//  Created by Ellen Shapiro on 12/26/14.
//  Copyright (c) 2014 Just Hum, LLC. All rights reserved.
//

#import "ViewController.h"

#import "HUMSlider.h"

@interface ViewController()
@property (nonatomic, weak) IBOutlet HUMSlider *sliderFromNib;
@property (nonatomic, weak) IBOutlet HUMSlider *noImageSliderFromNib;
@property (weak, nonatomic) IBOutlet HUMSlider *sliderFromNibSideColors;
@property (nonatomic) HUMSlider *programmaticSlider;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // This uses default values for everything except max and min images.
    self.sliderFromNib.minimumValueImage = [self sadImage];
    self.sliderFromNib.maximumValueImage = [self happyImage];
    
    // This uses custom clors for min and max images.
    self.sliderFromNibSideColors.minimumValueImage = [self sadImage];
    self.sliderFromNibSideColors.maximumValueImage = [self happyImage];
    [self.sliderFromNibSideColors setSaturatedColor:[UIColor redColor] forSide:HUMSliderSideLeft];
    [self.sliderFromNibSideColors setSaturatedColor:[UIColor greenColor] forSide:HUMSliderSideRight];
    
    [self.sliderFromNibSideColors setDesaturatedColor:[UIColor lightGrayColor] forSide:HUMSliderSideLeft];
    [self.sliderFromNibSideColors setDesaturatedColor:[UIColor darkGrayColor] forSide:HUMSliderSideRight];
    
    // This uses default values for everything except the track color, and
    // does not use any images.
    self.noImageSliderFromNib.tintColor = [UIColor redColor];
    
    [self setupSliderProgrammatically];
}

- (void)setupSliderProgrammatically
{
    self.programmaticSlider = [[HUMSlider alloc] init];
    self.programmaticSlider.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.programmaticSlider];
    
    // Setup autolayout
    
    // Pin left to top slider left
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.programmaticSlider
                                                          attribute:NSLayoutAttributeLeft
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.sliderFromNib
                                                          attribute:NSLayoutAttributeLeft
                                                         multiplier:1
                                                           constant:0]];
    
    // Pin right to top slider right
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.programmaticSlider
                                                          attribute:NSLayoutAttributeRight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.sliderFromNib
                                                          attribute:NSLayoutAttributeRight
                                                         multiplier:1
                                                           constant:0]];
    
    // Pin Top to bottom of different side colors slider.
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.programmaticSlider
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.sliderFromNibSideColors
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1
                                                           constant:0]];
    
    self.programmaticSlider.minimumValueImage = [self sadImage];
    self.programmaticSlider.maximumValueImage = [self happyImage];
    
    self.programmaticSlider.minimumValue = 0;
    self.programmaticSlider.maximumValue = 100;
    self.programmaticSlider.value = 25;
    
    // Custom track/thumb
    [self.programmaticSlider setMinimumTrackImage:[self darkTrack] forState:UIControlStateNormal];
    [self.programmaticSlider setMaximumTrackImage:[self darkTrack] forState:UIControlStateNormal];
    [self.programmaticSlider setThumbImage:[self darkThumb] forState:UIControlStateNormal];
    
    // This thumb has some space at the top to balance out the shadow built into it.
    self.programmaticSlider.pointAdjustmentForCustomThumb = 8;
    
    // Use some crazypants colors to make this obvious
    self.programmaticSlider.saturatedColor = [UIColor blueColor];
    self.programmaticSlider.desaturatedColor = [[UIColor brownColor] colorWithAlphaComponent:0.2f];
    self.programmaticSlider.tickColor = [UIColor orangeColor];
    
    // Also some slower times to make this obvious.
    self.programmaticSlider.tickAlphaAnimationDuration = 0.7;
    self.programmaticSlider.tickMovementAnimationDuration = 1.0;
    self.programmaticSlider.secondTickMovementAndimationDuration = 0.8;
    self.programmaticSlider.nextTickAnimationDelay = 0.1;
}

#pragma mark - Convenience images

- (UIImage *)darkTrack
{
    return [[UIImage imageNamed:@"SliderTrack"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
}

- (UIImage *)darkThumb
{
    return [UIImage imageNamed:@"SliderThumb"];
}

- (UIImage *)sadImage
{
    return [UIImage imageNamed:@"MoodSad"];
}

- (UIImage *)happyImage
{
    return [UIImage imageNamed:@"MoodHappy"];
}

@end
