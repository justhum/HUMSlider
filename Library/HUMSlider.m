//
//  HUMSlider.m
//  HUMSliderSample
//
//  Created by Ellen Shapiro on 12/26/14.
//  Copyright (c) 2014 Just Hum, LLC. All rights reserved.
//

#import "HUMSlider.h"

// Animation Durations
static NSTimeInterval const kAlphaDuration = 0.20;
static NSTimeInterval const kMainTickDuration = 0.5;
static NSTimeInterval const kSecondTickDuration = 0.35;
static NSTimeInterval const kAnimationDelay = 0.025;

// Positions
static CGFloat const kTickOutToInDifferential = 8;
static CGFloat const kTickInToPoppedDifferential = 4;

// Sizes
static CGFloat const kTickHeight = 6;
static CGFloat const kTickWidth = 1;

@interface HUMSlider ()

@property (nonatomic, strong) NSArray *tickViews;
@property (nonatomic, strong) NSArray *tickBottomConstraints;
@property (nonatomic, strong) NSArray *tickLeftConstraints;

@end

@implementation HUMSlider

#pragma mark - Init

- (void)commonInit
{
    //Set default value.
    self.sectionCount = 9;
    
}

- (id)init
{
    if (self = [super init]) {
        [self commonInit];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self commonInit];
    }
    
    return self;
}

#pragma mark - Setup

- (void)nukeOldTicks
{
    for (UIView *tick in self.tickViews) {
        [tick removeFromSuperview];
    }
    
    self.tickViews = nil;
    self.tickLeftConstraints = nil;
    self.tickBottomConstraints = nil;
    
    [self layoutIfNeeded];
}

- (void)setupTicks
{
    NSMutableArray *tickBuilder = [NSMutableArray array];
    for (NSInteger i = 0; i < self.sectionCount; i++) {
        UIView *tick = [[UIView alloc] init];
        tick.backgroundColor = self.tickColor;
        tick.alpha = 0;
        [self addSubview:tick];
        [tickBuilder addObject:tick];
    }
    
    self.tickViews = tickBuilder;
    [self setupTicksAutolayout];
}

- (void)setupTicksAutolayout
{
    NSMutableArray *bottoms = [NSMutableArray array];
    NSMutableArray *lefts = [NSMutableArray array];
    for (NSInteger i = 0; i < self.tickViews.count; i++) {
        UIView *currentTick = self.tickViews[i];
        currentTick.translatesAutoresizingMaskIntoConstraints = NO;
        
        UIView *previousTick;
        if (i != 0) {
            previousTick = self.tickViews[i - 1];
        }
        
        // Pin width of tick
        [self addConstraint:[NSLayoutConstraint constraintWithItem:currentTick
                                                         attribute:NSLayoutAttributeWidth
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:0
                                                        multiplier:1
                                                          constant:kTickWidth]];
        // Pin height of tick
        [self addConstraint:[NSLayoutConstraint constraintWithItem:currentTick
                                                         attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:0
                                                        multiplier:1
                                                          constant:kTickHeight]];
        
        CGFloat pinningConstant;
        if ([self isRunningLessThaniOS8]) {
            pinningConstant = 0;
        } else {
            pinningConstant = kTickHeight * 3;
        }
        
        NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:currentTick
                                                                  attribute:NSLayoutAttributeBottom
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self
                                                                  attribute:NSLayoutAttributeTop
                                                                 multiplier:1
                                                                   constant:pinningConstant];
        [self addConstraint:bottom];
        [bottoms addObject:bottom];
        
        NSLayoutConstraint *left;
        
        if (previousTick) {
            left = [NSLayoutConstraint constraintWithItem:currentTick
                                                attribute:NSLayoutAttributeLeading
                                                relatedBy:NSLayoutRelationEqual
                                                   toItem:previousTick
                                                attribute:NSLayoutAttributeTrailing
                                               multiplier:1
                                                 constant:self.segmentWidth - kTickWidth];
        } else {
            left = [NSLayoutConstraint constraintWithItem:currentTick
                                                attribute:NSLayoutAttributeLeading
                                                relatedBy:NSLayoutRelationEqual
                                                   toItem:self
                                                attribute:NSLayoutAttributeLeading
                                               multiplier:1
                                                 constant:self.halfSegment - kTickWidth];
        }
        
        [self addConstraint:left];
        [lefts addObject:left];
    }
    
    self.tickBottomConstraints = bottoms;
    self.tickLeftConstraints = lefts;
    [self layoutIfNeeded];
}

- (BOOL)isRunningLessThaniOS8
{
    if ([[NSProcessInfo processInfo] respondsToSelector:@selector(isOperatingSystemAtLeastVersion:)]) {
        // This is at least iOS 8 if it responds to this selector.
        return NO;
    } else {
        return YES;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self updateLeftConstraintsIfNeeded];
}

- (void)updateLeftConstraintsIfNeeded
{
    NSLayoutConstraint *firstLeft = self.tickLeftConstraints.firstObject;
    if (firstLeft.constant != (self.halfSegment - kTickWidth)) {
        // Need to be relaid out
        for (NSInteger i = 0; i < self.tickLeftConstraints.count; i++) {
            NSLayoutConstraint *left = self.tickLeftConstraints[i];
            if (i == 0) {
                left.constant = self.halfSegment - kTickWidth;
            } else {
                left.constant = self.segmentWidth - kTickWidth;
            }
            
            [self layoutIfNeeded];
        }
    } // else good to go.
}

#pragma mark - Overridden Setters

- (void)setSectionCount:(NSInteger)sectionCount
{
    // Warn the developer that they need to use an odd number of sections.
    NSAssert(sectionCount % 2 != 0, @"Must use an odd number of sections!");
    
    _sectionCount = sectionCount;
    
    [self nukeOldTicks];
    [self setupTicks];
}

#pragma mark - UIControl touch event tracking

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    // Update the width
    [self updateLeftConstraintsIfNeeded];
    [self animateAllTicksIn:YES];
    [self popTickIfNeededFromTouch:touch];
    
    return [super beginTrackingWithTouch:touch withEvent:event];
}

- (void)animateTickIfNeededAtIndex:(NSInteger)tickIndex forTouchX:(CGFloat)touchX
{
    UIView *tick = self.tickViews[tickIndex];
    CGFloat startSegmentX = tickIndex * self.segmentWidth;
    CGFloat endSegmentX = startSegmentX + self.segmentWidth;
    
    CGFloat desiredOrigin;
    if (startSegmentX <= touchX && endSegmentX > touchX) {
        // Pop up.
        desiredOrigin = kTickInToPoppedDifferential;
    } else {
        // Bring down.
        desiredOrigin = kTickOutToInDifferential;
    }
    
    if (CGRectGetMinY(tick.frame) != desiredOrigin) {
        [self animateTickAtIndex:tickIndex
                       toYOrigin:desiredOrigin
                    withDuration:kMainTickDuration
                           delay:0];
    } // else tick is already where it needs to be.
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [self popTickIfNeededFromTouch:touch];
    return [super continueTrackingWithTouch:touch withEvent:event];
}

- (void)popTickIfNeededFromTouch:(UITouch *)touch
{
    // Figure out where the hell the thumb is.
    CGRect trackRect = [self trackRectForBounds:self.bounds];
    CGRect thumbRect = [self thumbRectForBounds:self.bounds
                                      trackRect:trackRect
                                          value:self.value];
    CGFloat sliderLoc = CGRectGetMidX(thumbRect);
    
    // Animate tick based on the thumb location
    for (NSInteger i = 0; i < self.tickViews.count; i++) {
        [self animateTickIfNeededAtIndex:i forTouchX:sliderLoc];
    }
}

#pragma mark Animate Out

- (void)cancelTrackingWithEvent:(UIEvent *)event
{
    [self returnPosition];
    
    [super cancelTrackingWithEvent:event];
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [self returnPosition];
    
    [super endTrackingWithTouch:touch withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self returnPosition];
    
    [super touchesEnded:touches withEvent:event];
}

- (void)returnPosition
{
    [self animateAllTicksIn:NO];
}

#pragma mark - Tick Animation

- (void)animateAllTicksIn:(BOOL)inPosition
{
    CGFloat origin = kTickInToPoppedDifferential + kTickOutToInDifferential + kTickHeight;
    CGFloat alpha;
    
    if (inPosition) { // ticks are out, coming in
        alpha = 1;
    } else { // Ticks are in, coming out.
        alpha = 0;
    }
    
    [UIView animateWithDuration:kAlphaDuration
                     animations:^{
                         for (UIView *tick in self.tickViews) {
                             tick.alpha = alpha;
                         }
                     } completion:nil];
    
    for (NSInteger i = 0; i <= self.middleTickIndex; i++) {
        NSInteger nextHighest = self.middleTickIndex + i;
        NSInteger nextLowest = self.middleTickIndex - i;
        if (nextHighest == nextLowest) {
            // Middle tick
            [self animateTickAtIndex:nextHighest toYOrigin:origin withDuration:kMainTickDuration delay:0];
        } else if (nextHighest - nextLowest == 2) {
            // Second tick
            [self animateTickAtIndex:nextHighest toYOrigin:origin withDuration:kSecondTickDuration delay:kAnimationDelay * i];
            [self animateTickAtIndex:nextLowest toYOrigin:origin withDuration:kSecondTickDuration delay:kAnimationDelay * i];
        } else {
            // Rest of ticks
            [self animateTickAtIndex:nextHighest toYOrigin:origin withDuration:kMainTickDuration delay:kAnimationDelay * i];
            [self animateTickAtIndex:nextLowest toYOrigin:origin withDuration:kMainTickDuration delay:kAnimationDelay * i];
        }
    }
}

- (void)animateTickAtIndex:(NSInteger)index
                 toYOrigin:(CGFloat)yOrigin
              withDuration:(NSTimeInterval)duration
                     delay:(NSTimeInterval)delay
{
    
    
    NSLayoutConstraint *constraint = self.tickBottomConstraints[index];
    constraint.constant = yOrigin;
    
    
    [UIView animateWithDuration:duration
                          delay:delay
         usingSpringWithDamping:0.6f
          initialSpringVelocity:0.0f
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         [self layoutIfNeeded];
                     }
                     completion:nil];
}

#pragma mark - Calculation helpers

- (CGFloat)segmentWidth
{
    return floorf(CGRectGetWidth(self.frame) / self.sectionCount);
}

- (CGFloat)halfSegment
{
    return self.segmentWidth / 2.0f;
}

- (NSInteger)middleTickIndex
{
    return floor(self.tickViews.count / 2);
}

@end
