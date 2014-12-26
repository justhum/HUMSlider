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
    
    self.sliderFromNib.minimumValueImage = [UIImage imageNamed:@"MoodSad"];
    self.sliderFromNib.maximumValueImage = [UIImage imageNamed:@"MoodHappy"];
    self.sliderFromNib.sectionCount = 11;
}

@end
