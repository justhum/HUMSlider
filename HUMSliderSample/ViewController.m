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
@property (nonatomic) HUMSlider *programmaticSlider;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.sliderFromNib.minimumValueImage = [self sadImage];
    self.sliderFromNib.maximumValueImage = [self happyImage];
    self.sliderFromNib.sectionCount = 9;
    
    self.sliderFromNib.layer.borderColor = [UIColor orangeColor].CGColor;
    self.sliderFromNib.layer.borderWidth = 1;
    
    [self setupSliderProgrammatically];
}

- (void)setupSliderProgrammatically
{
    self.programmaticSlider = [[HUMSlider alloc] init];
    self.programmaticSlider.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.programmaticSlider];
    
    //Setup autolayout
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.programmaticSlider
                                                         attribute:NSLayoutAttributeLeft
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.sliderFromNib
                                                         attribute:NSLayoutAttributeLeft
                                                        multiplier:1
                                                          constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.programmaticSlider
                                                          attribute:NSLayoutAttributeRight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.sliderFromNib
                                                          attribute:NSLayoutAttributeRight
                                                         multiplier:1
                                                           constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.programmaticSlider
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.sliderFromNib
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1
                                                           constant:0]];
    
    self.programmaticSlider.minimumValueImage = [self sadImage];
    self.programmaticSlider.maximumValueImage = [self happyImage];
    
    self.programmaticSlider.saturatedColor = [UIColor blueColor];
    self.programmaticSlider.desaturatedColor = [UIColor brownColor];
}

#pragma mark - Convenience images

- (UIImage *)sadImage
{
    return [UIImage imageNamed:@"MoodSad"];
}

- (UIImage *)happyImage
{
    return [UIImage imageNamed:@"MoodHappy"];
}

@end
