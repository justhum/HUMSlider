//
//  HUMSlider.m
//  HUMSliderSample
//
//  Created by Ellen Shapiro on 12/26/14.
//  Copyright (c) 2014 Just Hum, LLC. All rights reserved.
//

#import "HUMSlider.h"

// Animation Durations
static NSTimeInterval const HUMTickAlphaDuration = 0.20;
static NSTimeInterval const HUMTickMovementDuration = 0.5;
static NSTimeInterval const HUMSecondTickDuration = 0.35;
static NSTimeInterval const HUMTickAnimationDelay = 0.025;

// Positions
static CGFloat const HUMTickOutToInDifferential = 8;
static CGFloat const HUMImagePadding = 8;

// Sizes
static CGFloat const HUMTickHeight = 6;
static CGFloat const HUMTickWidth = 1;

// Default Constants
static CGFloat const DefaultThumbPxWidth = 30; //Size of apple's default thumb icon.

@implementation Tick
// Constructor for a tick
- (id)initWithPosition:(CGFloat)position {
    NSAssert(position >= 0 && position <= 1, @"Position must be between 0 and 1");
    self = [super init];
    if (self) {
        self.position = position;
    }
    return self;
}
@end

@interface HUMSlider ()

@property (nonatomic) NSArray *tickViews;
@property (nonatomic) NSArray *allTickBottomConstraints;

//Constraint storage for evenly spaced tick constraints.
@property (nonatomic) NSArray *leftTickRightConstraints; //FUTURE, use the middleTickConstraints strategy for equal spaced ticks
@property (nonatomic) NSArray *rightTickLeftConstraints;

//Constraint storage for dynamically spaced tick constraints.
@property (nonatomic) NSArray *middleTickConstraints;

@property (nonatomic) UIImage *leftTemplate;
@property (nonatomic) UIImage *rightTemplate;

@property (nonatomic) UIImageView *leftSaturatedImageView;
@property (nonatomic) UIColor *leftSaturatedColor;
@property (nonatomic) UIImageView *leftDesaturatedImageView;
@property (nonatomic) UIColor *leftDesaturatedColor;
@property (nonatomic) UIImageView *rightSaturatedImageView;
@property (nonatomic) UIColor *rightSaturatedColor;
@property (nonatomic) UIImageView *rightDesaturatedImageView;
@property (nonatomic) UIColor *rightDesaturatedColor;

@end

@implementation HUMSlider {
    CGFloat thumbImageWidth; // Reference to last computed thumb width.
    CGRect trackRect; // store the track width from the layoutSubviews.
}

#pragma mark - Init

- (void)commonInit
{
    trackRect = CGRectZero;
    [self thumbImageWidth]; // Lazy init of initial calc of thumb image width.
    
    self.lowerTicksOnInactiveTouch = true; //default to lowering them.
    self.customTicksEnabled = false; //default to true
    self.enableTicksTransparencyOnIdle = true; // keep ticks at all times.
    
    // Set default values.
    self.sectionCount = 9;
    self.tickAlphaAnimationDuration = HUMTickAlphaDuration;
    self.tickMovementAnimationDuration = HUMTickMovementDuration;
    self.secondTickMovementAndimationDuration = HUMSecondTickDuration;
    self.nextTickAnimationDelay = HUMTickAnimationDelay;
    
    //Private var init
    self.ticks = [[NSMutableArray alloc] init];
    
    //These will set the side colors.
    self.saturatedColor = [UIColor redColor];
    self.desaturatedColor = [UIColor lightGrayColor];
    
    self.tickColor = [UIColor darkGrayColor];
    
    // Add self as target.
    [self addTarget:self
             action:@selector(sliderAdjusted)
   forControlEvents:UIControlEventValueChanged];
}

- (instancetype)init
{
    if (self = [super init]) {
        [self commonInit];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self commonInit];
    }
    
    return self;
}

#pragma mark - Ticks

- (void)addTick:(Tick*)tick willRefreshView:(BOOL)refreshView {
    
    if ([self.ticks count] == 0) {
        [self.ticks addObject:tick];
    }
    else { // Sorted-ly add the tick in the right sorted order.
        NSUInteger index = [self.ticks count];
        for (Tick *tickItr in [self.ticks reverseObjectEnumerator]) {
            if (tick.position >= tickItr.position) {
                [self.ticks insertObject:tick atIndex:index];
                break;
            }
            index --;
        }
    }
    
    if (refreshView) {
        [self setupTickViews];
        [self updateTickHeights];
    }
}

- (void)removeTickAtIndex:(NSUInteger)index refreshView:(BOOL)refreshView {
    [_ticks removeObjectAtIndex:index];
    if (refreshView) {
        [self setupTickViews];
        [self updateTickHeights];
    }
}

- (void)removeAllTicks {
    for (NSUInteger i = [_ticks count] - 1; i > 0 ; i--) {
        [self removeTickAtIndex:i refreshView:NO];
    }
    [self removeTickAtIndex:0 refreshView:YES];
    [self setNeedsLayout];
    [self nukeOldTickViews];
}

- (void)nukeOldTickViews
{
    for (UIView *tick in self.tickViews) {
        [tick removeFromSuperview];
    }
    
    self.tickViews = nil;
    self.leftTickRightConstraints = nil;
    self.allTickBottomConstraints = nil;
    
    [self layoutIfNeeded];
}

- (void)refreshView {
    [self setupTickViews];
}

- (void)setupTickViews
{
    if ([self areCustomTicksSetupAndNonNull]) {
        [self cleanupConstraintsAfterEvenlySpacedTicks];
        [self setupCustomTickViews];
        [self setupTicksAutoLayoutCustomWidths];
        if (!_enableTicksTransparencyOnIdle) {
            [self animateAllTicksInCustomWidths:YES];
        }
    }
    else {
        [self cleanupConstraintsAfterCustomSpacedTicks];
        [self setupSpacedTickViews];
        [self setupTicksAutolayout];
        if (!_enableTicksTransparencyOnIdle) {
            [self animateAllTicksIn:YES];
        }
    }
}

- (void)cleanupConstraintsAfterEvenlySpacedTicks {
    self.tickViews = [NSArray new]; // Make sure these get re-initialized
    [self clearLayoutConstraintList:_leftTickRightConstraints];
    [self clearLayoutConstraintList:_rightTickLeftConstraints];
    [self clearLayoutConstraintList:_allTickBottomConstraints];
}

- (void)cleanupConstraintsAfterCustomSpacedTicks {
    self.tickViews = [NSArray new]; // Make sure these get re-initialized
    [self clearLayoutConstraintList:self.middleTickConstraints];
    [self clearLayoutConstraintList:self.allTickBottomConstraints];
}

// Disassociate all of the NSLayoutConstraints in the list from the parent view.
- (void)clearLayoutConstraintList:(NSArray*)list {
    if (list) {
        for (NSLayoutConstraint *constraint in list) {
            [self removeConstraint:constraint];
        }
    }
}

- (void)setupSpacedTickViews {
    [self createAndAddBlankTickViewsWithCount:(NSUInteger)self.sectionCount];
}

- (void)setupCustomTickViews {
    [self createAndAddBlankTickViewsWithCount:(NSUInteger)[self.ticks count]];
}

- (BOOL)areCustomTicksSetupAndNonNull {
    return (self.customTicksEnabled && self.ticks && [self.ticks count] > 0);
}

- (void)createAndAddBlankTickViewsWithCount:(NSUInteger)count {
    NSMutableArray *tickBuilder = [NSMutableArray array];
    for (NSInteger i = 0; i < count; i++) {
        UIView *tick = [self setupCommonTickViewAndAddToSubview];
        [tickBuilder addObject:tick];
    }
    
    self.tickViews = tickBuilder;
}

- (UIView*)setupCommonTickViewAndAddToSubview {
    UIView *tick = [[UIView alloc] init];
    tick.backgroundColor = self.tickColor;
    tick.alpha = 0;
    tick.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:tick];
    [self sendSubviewToBack:tick];
    return tick;
}

#pragma mark Autolayout

- (void)setupTicksAutoLayoutCustomWidths {
    
    assert([self areCustomTicksSetupAndNonNull]);
    
    //Store the position and bottom constraints for some reason
    NSMutableArray *bottoms = [NSMutableArray array];
    NSMutableArray *middleConstraints = [NSMutableArray array];

    for (NSInteger i = 0; i < [self.tickViews count]; i++) {
        
        UIView *currentItem = self.tickViews[i];

        NSLayoutConstraint *bottomConstraint = [self pinTickBottom:currentItem];
        [self addConstraint:bottomConstraint];
        [bottoms insertObject:bottomConstraint atIndex:i];
        [self pinTickWidthAndHeight:currentItem];
        
        Tick *theTickGuy = _ticks[i];

        double constant = [self tickPixelOffsetFromMiddle:theTickGuy];

        // Pin the middle tick to the middle of the slider.
        NSLayoutConstraint *middle = [NSLayoutConstraint constraintWithItem:currentItem
                                                         attribute:NSLayoutAttributeCenterX
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeCenterX
                                                        multiplier:1
                                                          constant:constant];
        
        [self addConstraint:middle];
        [middleConstraints addObject:middle];
    }

    self.allTickBottomConstraints = bottoms;
    self.middleTickConstraints = middleConstraints;

    [self layoutIfNeeded];
}

- (void)setupTicksAutolayout
{
    assert(![self areCustomTicksSetupAndNonNull]);
    
    NSMutableArray *bottoms = [NSMutableArray array];
    NSMutableArray *lefts = [NSMutableArray array];
    NSMutableArray *rights = [NSMutableArray array];
    
    UIView *middleTick = self.tickViews[self.middleTickIndex];
    [self pinTickWidthAndHeight:middleTick];
    NSLayoutConstraint *midBottom = [self pinTickBottom:middleTick];
    [bottoms addObject:midBottom];
    
    // Pin the middle tick to the middle of the slider.
    [self addConstraint:[NSLayoutConstraint constraintWithItem:middleTick
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1
                                                      constant:0]];
    
    for (NSInteger i = 0; i < self.middleTickIndex; i++) {
        NSInteger previousLowest = self.middleTickIndex - i;
        NSInteger previousHighest = self.middleTickIndex + i;
        
        NSInteger nextLowest = self.middleTickIndex - (i + 1);
        NSInteger nextHighest = self.middleTickIndex + (i + 1);
        
        UIView *nextToLeft = self.tickViews[nextLowest];
        UIView *nextToRight = self.tickViews[nextHighest];
        
        UIView *previousToLeft = self.tickViews[previousLowest];
        UIView *previousToRight = self.tickViews[previousHighest];
        
        // Pin widths, heights, and bottoms.
        [self pinTickWidthAndHeight:nextToLeft];
        NSLayoutConstraint *leftBottom = [self pinTickBottom:nextToLeft];
        [bottoms insertObject:leftBottom atIndex:0];
        
        [self pinTickWidthAndHeight:nextToRight];
        NSLayoutConstraint *rightBottom = [self pinTickBottom:nextToRight];
        [bottoms addObject:rightBottom];
        
        // Pin the right of the next leftwards tick to the previous leftwards tick
        NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:nextToLeft
                                                                attribute:NSLayoutAttributeRight
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:previousToLeft
                                                                attribute:NSLayoutAttributeLeft
                                                               multiplier:1
                                                                 constant:-(self.segmentWidth - HUMTickWidth)];
        [self addConstraint:left];
        [lefts addObject:left];
        
        // Pin the left of the next rightwards tick to the previous rightwards tick.
        NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:nextToRight
                                                                 attribute:NSLayoutAttributeLeft
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:previousToRight
                                                                 attribute:NSLayoutAttributeRight
                                                                multiplier:1
                                                                  constant:(self.segmentWidth - HUMTickWidth)];
        [self addConstraint:right];
        [rights addObject:right];
        
    }
    
    self.allTickBottomConstraints = bottoms;
    self.leftTickRightConstraints = lefts;
    self.rightTickLeftConstraints = rights;
    
    [self layoutIfNeeded];
}

//Size of the tick itself.
- (void)pinTickWidthAndHeight:(UIView *)currentTick
{
    // Pin width of tick
    [self addConstraint:[NSLayoutConstraint constraintWithItem:currentTick
                                                     attribute:NSLayoutAttributeWidth
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:nil
                                                     attribute:0
                                                    multiplier:1
                                                      constant:HUMTickWidth]];
    // Pin height of tick
    [self addConstraint:[NSLayoutConstraint constraintWithItem:currentTick
                                                     attribute:NSLayoutAttributeHeight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:nil
                                                     attribute:0
                                                    multiplier:1
                                                      constant:HUMTickHeight]];
}

- (NSLayoutConstraint *)pinTickBottom:(UIView *)currentTick
{
    // Pin bottom of tick to top of track.
    NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:currentTick
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1
                                                               constant:[self tickOutPosition]];
    [self addConstraint:bottom];
    return bottom;
}

#pragma mark - Images

- (void)setupSaturatedAndDesaturatedImageViews
{
    // Left
    self.leftDesaturatedImageView = [[UIImageView alloc] init];
    self.leftDesaturatedImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.leftDesaturatedImageView];
    
    self.leftSaturatedImageView = [[UIImageView alloc] init];
    self.leftSaturatedImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.leftSaturatedImageView.alpha = 0.0f;
    [self addSubview:self.leftSaturatedImageView];
    
    // Right
    self.rightDesaturatedImageView = [[UIImageView alloc] init];
    self.rightDesaturatedImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.rightDesaturatedImageView];
    
    self.rightSaturatedImageView = [[UIImageView alloc] init];
    self.rightSaturatedImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.rightSaturatedImageView.alpha = 0;
    [self addSubview:self.rightSaturatedImageView];
    
    // Pin desaturated image views.
    [self pinView:self.leftDesaturatedImageView toSuperViewAttribute:NSLayoutAttributeLeft];
    [self pinView:self.leftDesaturatedImageView toSuperViewAttribute:NSLayoutAttributeCenterY constant:HUMTickOutToInDifferential];
    [self pinView:self.rightDesaturatedImageView toSuperViewAttribute:NSLayoutAttributeRight];
    [self pinView:self.rightDesaturatedImageView toSuperViewAttribute:NSLayoutAttributeCenterY constant:HUMTickOutToInDifferential];
    
    // Pin saturated image views to desaturated image views.
    [self pinView1Center:self.leftSaturatedImageView toView2Center:self.leftDesaturatedImageView];
    [self pinView1Center:self.rightSaturatedImageView toView2Center:self.rightDesaturatedImageView];
    
    // Reset colors
    self.saturatedColor = self.saturatedColor;
    self.desaturatedColor = self.desaturatedColor;
}

- (void)sliderAdjusted
{
    CGFloat halfValue = (self.minimumValue + self.maximumValue) / 2.0f;
    
    if (self.value > halfValue) {
        self.rightSaturatedImageView.alpha = (self.value - halfValue) / halfValue;
        self.leftSaturatedImageView.alpha = 0;
    } else {
        self.leftSaturatedImageView.alpha = (halfValue - self.value) / halfValue;
        self.rightSaturatedImageView.alpha = 0;
    }
}

- (UIImage *)transparentImageOfSize:(CGSize)size
{
    if (CGSizeEqualToSize(size, CGSizeZero)) {
        return nil;
    }
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

#pragma mark - Superclass Overrides

- (CGSize)intrinsicContentSize
{
    CGFloat maxPoppedHeight = CGRectGetHeight([self thumbRectForBounds:self.bounds trackRect:[self trackRectForBounds:self.bounds] value:self.value]) + HUMTickHeight;
    
    CGFloat largestHeight = MAX(CGRectGetMaxY(self.rightSaturatedImageView.frame),
                                MAX(CGRectGetMaxY(self.leftSaturatedImageView.frame), maxPoppedHeight));
    return CGSizeMake(CGRectGetWidth(self.frame), largestHeight);
}

- (CGRect)minimumValueImageRectForBounds:(CGRect)bounds
{
    return self.leftDesaturatedImageView.frame;
}

- (CGRect)maximumValueImageRectForBounds:(CGRect)bounds
{
    return self.rightDesaturatedImageView.frame;
}

- (CGRect)trackRectForBounds:(CGRect)bounds
{
    CGRect superRect = [super trackRectForBounds:bounds];
    superRect.origin.y += HUMTickHeight;
    
    // Adjust the track rect so images are always a consistent padding.
    
    if (self.leftDesaturatedImageView) {
        CGFloat leftImageViewToTrackOrigin = CGRectGetMinX(superRect) - CGRectGetMaxX(self.leftDesaturatedImageView.frame);
        
        if (leftImageViewToTrackOrigin != HUMImagePadding) {
            CGFloat leftAdjust = leftImageViewToTrackOrigin - HUMImagePadding;
            superRect.origin.x -= leftAdjust;
            superRect.size.width += leftAdjust;
        }
    }
    
    if (self.rightDesaturatedImageView) {
        CGFloat endOfTrack = CGRectGetMaxX(superRect);
        CGFloat startOfRight = CGRectGetMinX(self.rightDesaturatedImageView.frame);
        CGFloat trackEndToRightImageView = startOfRight - endOfTrack;
        
        if (trackEndToRightImageView != HUMImagePadding) {
            CGFloat rightAdjust = trackEndToRightImageView - HUMImagePadding;
            superRect.size.width += rightAdjust;
        }
    }
    
    return superRect;
}

#pragma mark - Convenience

- (void)pinView:(UIView *)view toSuperViewAttribute:(NSLayoutAttribute)attribute
{
    [self pinView:view toSuperViewAttribute:attribute constant:0];
}

- (void)pinView:(UIView *)view toSuperViewAttribute:(NSLayoutAttribute)attribute constant:(CGFloat)constant
{
    [view.superview addConstraint:[NSLayoutConstraint constraintWithItem:view
                                                               attribute:attribute
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:view.superview
                                                               attribute:attribute
                                                              multiplier:1
                                                                constant:constant]];
}

- (void)pinView1Center:(UIView *)view1 toView2Center:(UIView *)view2
{
    [self addConstraint:[NSLayoutConstraint constraintWithItem:view1
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:view2
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1
                                                      constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:view1
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:view2
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1
                                                      constant:0]];
    
}

#pragma mark - General layout

- (void)layoutSubviews
{
    trackRect = [self trackRectForBounds:self.bounds];
    
    [super layoutSubviews];
    if ([self areCustomTicksSetupAndNonNull]) {
        [self updateCustomTickConstraintsIfNeeded];
    }
    else {
        [self updateLeftTickConstraintsIfNeeded];
    }
}

// First method that is called when animating ticks in.
- (void)updateLeftTickConstraintsIfNeeded
{
    assert(![self areCustomTicksSetupAndNonNull]);
    
    NSLayoutConstraint *firstLeft = self.leftTickRightConstraints.firstObject;
    
    if (firstLeft.constant != (self.segmentWidth - HUMTickWidth)) {
        for (NSInteger i = 0; i < self.middleTickIndex; i++) {
            NSLayoutConstraint *leftConstraint = self.rightTickLeftConstraints[i];
            NSLayoutConstraint *rightConstraint = self.leftTickRightConstraints[i];
            leftConstraint.constant = (self.segmentWidth - HUMTickWidth);
            rightConstraint.constant = -(self.segmentWidth - HUMTickWidth);
        }
        
        [self layoutIfNeeded];
    } // else good to go.
}

- (void)updateCustomTickConstraintsIfNeeded
{
    assert([self areCustomTicksSetupAndNonNull]);
    
    NSUInteger tickCount = [self.tickViews count];
    
    NSLayoutConstraint *firstLeft = self.middleTickConstraints.firstObject;
    
    Tick *firstTick = self.ticks[0];
    
    CGFloat constant = [self tickPixelOffsetFromMiddle:firstTick];
    
    if (firstLeft.constant != constant) {

        //This is the new code to start at the first one.
        for (NSInteger i = 0; i < tickCount; i++) {
            NSLayoutConstraint *middleConstraint = self.middleTickConstraints[i];
            Tick *theTick = self.ticks[i];
            middleConstraint.constant = [self tickPixelOffsetFromMiddle:theTick];
        }
    
        [self layoutIfNeeded];
    }
}

#pragma mark - Overridden Setters

- (void)setValue:(float)value
{
    [super setValue:value];
    [self sliderAdjusted];
}

- (void)setSectionCount:(NSUInteger)sectionCount
{
    // Warn the developer that they need to use an odd number of sections.
    NSAssert(sectionCount % 2 != 0, @"Must use an odd number of sections!");
    
    _sectionCount = sectionCount;
    
    [self nukeOldTickViews];
    [self setupTickViews];
}

- (void)setMinimumValueImage:(UIImage *)minimumValueImage
{
    if (!self.leftDesaturatedImageView) {
        [self setupSaturatedAndDesaturatedImageViews];
    }
    
    [super setMinimumValueImage:[self transparentImageOfSize:minimumValueImage.size]];
    self.leftTemplate = [minimumValueImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.leftSaturatedImageView.image = self.leftTemplate;
    self.leftDesaturatedImageView.image = self.leftTemplate;
    
    // Bring to the front or they'll get covered by the minimum value image.
    [self bringSubviewToFront:self.leftDesaturatedImageView];
    [self bringSubviewToFront:self.leftSaturatedImageView];
}

- (void)setMaximumValueImage:(UIImage *)maximumValueImage
{
    if (!self.leftDesaturatedImageView) {
        [self setupSaturatedAndDesaturatedImageViews];
    }
    
    [super setMaximumValueImage:[self transparentImageOfSize:maximumValueImage.size]];
    self.rightTemplate = [maximumValueImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.rightSaturatedImageView.image = self.rightTemplate;
    self.rightDesaturatedImageView.image = self.rightTemplate;
    
    // Bring to the front or they'll get covered by the minimum value image.
    [self bringSubviewToFront:self.rightDesaturatedImageView];
    [self bringSubviewToFront:self.rightSaturatedImageView];
}

- (void)setSaturatedColor:(UIColor *)saturatedColor
{
    _saturatedColor = saturatedColor;
    [self setSaturatedColor:saturatedColor forSide:HUMSliderSideLeft];
    [self setSaturatedColor:saturatedColor forSide:HUMSliderSideRight];
}

- (void)setDesaturatedColor:(UIColor *)desaturatedColor
{
    _desaturatedColor = desaturatedColor;
    [self setDesaturatedColor:desaturatedColor forSide:HUMSliderSideLeft];
    [self setDesaturatedColor:desaturatedColor forSide:HUMSliderSideRight];
}

#pragma mark - Setters for colors on different sides. 

- (void)setSaturatedColor:(UIColor *)saturatedColor forSide:(HUMSliderSide)side
{
    switch (side) {
        case HUMSliderSideLeft:
            self.leftSaturatedColor = saturatedColor;
            break;
        case HUMSliderSideRight:
            self.rightSaturatedColor = saturatedColor;
            break;
    }
    
    [self imageViewForSide:side saturated:YES].tintColor = saturatedColor;
}

- (UIColor *)saturatedColorForSide:(HUMSliderSide)side
{
    switch (side) {
        case HUMSliderSideLeft:
            return self.leftSaturatedColor;
            break;
        case HUMSliderSideRight:
            return self.rightSaturatedColor;
            break;
    }
}

- (void)setDesaturatedColor:(UIColor *)desaturatedColor forSide:(HUMSliderSide)side
{
    switch (side) {
        case HUMSliderSideLeft:
            self.leftDesaturatedColor = desaturatedColor;
            break;
        case HUMSliderSideRight:
            self.rightDesaturatedColor = desaturatedColor;
            break;
    }

    [self imageViewForSide:side saturated:NO].tintColor = desaturatedColor;
}

- (UIColor *)desaturatedColorForSide:(HUMSliderSide)side
{
    switch (side) {
        case HUMSliderSideLeft:
            return self.leftDesaturatedColor;
            break;
        case HUMSliderSideRight:
            return self.rightDesaturatedColor;
            break;
    }
}

- (UIImageView *)imageViewForSide:(HUMSliderSide)side saturated:(BOOL)saturated
{
    switch (side) {
        case HUMSliderSideLeft:
            if (saturated) {
                return self.leftSaturatedImageView;
            } else {
                return self.leftDesaturatedImageView;
            }
            break;
        case HUMSliderSideRight:
            if (saturated) {
                return self.rightSaturatedImageView;
            } else {
                return self.rightDesaturatedImageView;
            }
            break;
    }
}

- (void)setTickColor:(UIColor *)tickColor
{
    _tickColor = tickColor;
    if (self.tickViews) {
        for (UIView *tick in self.tickViews) {
            tick.backgroundColor = _tickColor;
        }
    }
}

#pragma mark - UIControl touch event tracking
#pragma mark Animate In

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    if ([self areCustomTicksSetupAndNonNull]) {
        [self updateCustomTickConstraintsIfNeeded];
        [self animateAllTicksInCustomWidths:YES];
    }
    else {
        [self updateLeftTickConstraintsIfNeeded];
        [self animateAllTicksIn:YES];
    }
    
    [self popTickIfNeededFromTouch:touch];
    
    return [super beginTrackingWithTouch:touch withEvent:event];
}

- (void)updateTickHeights {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateTickHeights];
            return;
        });
    }

    CGRect trackRect = [self trackRectForBounds:self.bounds];
    CGRect thumbRect = [self thumbRectForBounds:self.bounds
                                      trackRect:trackRect
                                          value:self.value];

    CGFloat sliderLoc = CGRectGetMidX(thumbRect);
    
    // Animate tick based on the thumb location
    for (NSInteger i = 0; i < self.tickViews.count; i++) {
        if ([self areCustomTicksSetupAndNonNull]) {
            [self animateCustomTickIfNeededAtIndex:i forTouchX:sliderLoc];
        }
        else {
            [self animateTickIfNeededAtIndex:i forTouchX:sliderLoc];
        }
    }
}

#warning - thumbHeight method may do the same thing as self thumbImageWidth.

- (void)animateCustomTickIfNeededAtIndex:(NSInteger)tickIndex forTouchX:(CGFloat)touchX
{
    assert ([self areCustomTicksSetupAndNonNull]);
    
    UIView *tick = self.tickViews[tickIndex];

    NSLayoutConstraint *constraint = self.middleTickConstraints[tickIndex];
    
    CGFloat tickDistanceFromLeft = (trackRect.size.width / 2) + (constraint.constant) + trackRect.origin.x;
    CGFloat thumbSliderRadius = [self thumbImageWidth] / 2;
    
    CGFloat startSegmentX = tickDistanceFromLeft - thumbSliderRadius; //TODO: Make a constant for the interval - from AdjustedThumbSlider subclass.
    CGFloat endSegmentX = tickDistanceFromLeft + thumbSliderRadius;
    
    CGFloat desiredOrigin;
    if (startSegmentX <= touchX && endSegmentX > touchX) {
        // Pop up.
        desiredOrigin = [self tickPoppedPosition];
        CGFloat Xdiff = fabs(touchX - tickDistanceFromLeft);//fmin(fabs(touchX - startSegmentX), fabs(touchX - endSegmentX));
        CGFloat zeroBased = Xdiff / ([self thumbImageWidth] / 2);
        CGFloat diffZeroBased = tan(acos(zeroBased)) * zeroBased;
        CGFloat diff = (1 - diffZeroBased) * ([self thumbImageWidth] / 2);
        desiredOrigin += diff; // Add because the desired origin is negative the higher it pops.
    } else{
        // Bring down.
        desiredOrigin = [self tickInNotPoppedPositon];
    }

    if (CGRectGetMinY(tick.frame) != desiredOrigin) {
        [self animateTickAtIndex:tickIndex
                       toYOrigin:desiredOrigin
                    withDuration:self.tickMovementAnimationDuration
                           delay:0];
    } // else tick is already where it needs to be.
}

- (void)animateTickIfNeededAtIndex:(NSInteger)tickIndex forTouchX:(CGFloat)touchX
{
    assert (![self areCustomTicksSetupAndNonNull]);
    
    UIView *tick = self.tickViews[tickIndex];
    
    CGFloat startSegmentX = (tickIndex * self.segmentWidth) + self.trackXOrigin;
    CGFloat endSegmentX = startSegmentX + self.segmentWidth;
    
    CGFloat desiredOrigin;
    if (startSegmentX <= touchX && endSegmentX > touchX) {
        // Pop up.
        desiredOrigin = [self tickPoppedPosition];
    } else {
        // Bring down.
        desiredOrigin = [self tickInNotPoppedPositon];
    }
    
    if (CGRectGetMinY(tick.frame) != desiredOrigin) {
        [self animateTickAtIndex:tickIndex
                       toYOrigin:desiredOrigin
                    withDuration:self.tickMovementAnimationDuration
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
    CGRect trackRect = [self trackRectForBounds:self.bounds];
    CGRect thumbRect = [self thumbRectForBounds:self.bounds
                                      trackRect:trackRect
                                          value:self.value];
    
    CGFloat sliderLoc = CGRectGetMidX(thumbRect);
    
    // Animate tick based on the thumb location
    for (NSInteger i = 0; i < self.tickViews.count; i++) {
        if ([self areCustomTicksSetupAndNonNull]) {
            [self animateCustomTickIfNeededAtIndex:i forTouchX:sliderLoc];
        }
        else {
            [self animateTickIfNeededAtIndex:i forTouchX:sliderLoc];
        }
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
    if (self.lowerTicksOnInactiveTouch == NO) {
        return;
    }

    if ([self areCustomTicksSetupAndNonNull]) {
        [self animateAllTicksInCustomWidths:NO];
    }
    else {
        [self animateAllTicksIn:NO];
    }
}

// To Remove - my method for custom widths
- (void)animateAllTicksInCustomWidths:(BOOL)inPosition
{
    assert([self areCustomTicksSetupAndNonNull] == true);
    
    CGFloat origin;
    CGFloat alpha;
    
    if (inPosition) { // Ticks are out, coming in
        alpha = 1;
        origin = [self tickInNotPoppedPositon];
    } else { // Ticks are in, coming out.
        alpha = _enableTicksTransparencyOnIdle ? 0 : 1; // Transparent if setting is enabed.
        origin = [self tickOutPosition];
    }

    [UIView animateWithDuration:self.tickAlphaAnimationDuration
                     animations:^{
                         for (UIView *tick in self.tickViews) {
                             tick.alpha = alpha;
                         }
                     } completion:nil];
    
    for (NSInteger i = 0; i < [self.tickViews count]; i++) {
        
        [self animateTickAtIndex:i
                       toYOrigin:origin
                    withDuration:self.tickMovementAnimationDuration
                           delay:self.nextTickAnimationDelay * i];
    }
}

#pragma mark - Tick Animation

- (void)animateAllTicksIn:(BOOL)inPosition
{
    assert([self areCustomTicksSetupAndNonNull] == false);
    
    CGFloat origin;
    CGFloat alpha;
    
    if (inPosition) { // Ticks are out, coming in
        alpha = 1;
        origin = [self tickInNotPoppedPositon];
    } else { // Ticks are in, coming out.
        alpha = _enableTicksTransparencyOnIdle ? 0 : 1;
        origin = [self tickOutPosition];
    }
    
    [UIView animateWithDuration:self.tickAlphaAnimationDuration
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
            [self animateTickAtIndex:nextHighest
                           toYOrigin:origin
                        withDuration:self.tickMovementAnimationDuration
                               delay:0];
        } else if (nextHighest - nextLowest == 2) {
            // Second tick
            [self animateTickAtIndex:nextHighest
                           toYOrigin:origin
                        withDuration:self.secondTickMovementAndimationDuration
                               delay:self.nextTickAnimationDelay * i];
            [self animateTickAtIndex:nextLowest
                           toYOrigin:origin
                        withDuration:self.secondTickMovementAndimationDuration
                               delay:self.nextTickAnimationDelay * i];
        } else {
            // Rest of ticks
            [self animateTickAtIndex:nextHighest
                           toYOrigin:origin
                        withDuration:self.tickMovementAnimationDuration
                               delay:self.nextTickAnimationDelay * i];
            [self animateTickAtIndex:nextLowest
                           toYOrigin:origin
                        withDuration:self.tickMovementAnimationDuration
                               delay:self.nextTickAnimationDelay * i];
        }
    }
}

- (void)animateTickAtIndex:(NSInteger)index
                 toYOrigin:(CGFloat)yOrigin
              withDuration:(NSTimeInterval)duration
                     delay:(NSTimeInterval)delay
{
    NSLayoutConstraint *constraint = self.allTickBottomConstraints[index];
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

- (CGFloat)trackXOrigin
{
    CGRect trackRect = [self trackRectForBounds:self.bounds];
    return CGRectGetMinX(trackRect);
}

- (CGFloat)trackYOrigin
{
    CGRect trackRect = [self trackRectForBounds:self.bounds];
    return CGRectGetMinY(trackRect);
}

- (CGFloat)segmentWidth
{
    CGRect trackRect = [self trackRectForBounds:self.bounds];
    return floorf(CGRectGetWidth(trackRect) / self.sectionCount);
}

- (NSInteger)middleTickIndex
{
    return floor(self.tickViews.count / 2);
}

- (CGFloat)thumbHeight
{
    CGRect thumbRect = [self thumbRectForBounds:self.bounds
                                      trackRect:[self trackRectForBounds:self.bounds]
                                          value:self.value];
    return CGRectGetHeight(thumbRect);
}

- (CGFloat)tickInToPoppedDifferential
{
    CGFloat halfThumb = [self thumbHeight] / 2.0f;
    CGFloat inToUp = halfThumb - HUMTickOutToInDifferential;
    
    return inToUp;
}

- (CGFloat)tickOutPosition
{
    return -(CGRectGetMaxY(self.bounds) - [self trackYOrigin]);
}

- (CGFloat)tickInNotPoppedPositon
{
    return [self tickOutPosition] - HUMTickOutToInDifferential + HUMTickHeight / 2;
}

- (CGFloat)tickPoppedPosition
{
    return [self tickInNotPoppedPositon] - [self tickInToPoppedDifferential] - self.pointAdjustmentForCustomThumb;
}

- (CGFloat)tickPixelOffsetFromMiddle:(Tick*)tick {
    double trackWidth = trackRect.size.width - [self thumbImageWidth] + trackRect.origin.x; // :)
    double constant = (tick.position * trackWidth) - (trackWidth / 2);
    return constant;
}

- (CGFloat)thumbImageWidth // default thumb image is 30 px,
{
    double imgThumbImageWidth = self.currentThumbImage.size.width;
    if (imgThumbImageWidth && imgThumbImageWidth != 0 && imgThumbImageWidth != thumbImageWidth) {
        thumbImageWidth = imgThumbImageWidth;
    }
    else if (!thumbImageWidth || thumbImageWidth == 0) { // No custom image set, use 30
        thumbImageWidth = DefaultThumbPxWidth;
    }
    return thumbImageWidth;
}

@end
