//
//  HUMSlider.m
//  HUMSliderSample
//
//  Created by Ellen Shapiro on 12/26/14.
//  Edited by Jeffrey Blayney 6/26/18
//

#import "HUMSlider.h"

#define ROUNDF(f, c) (((float)((int)((f) * (c))) / (c)))

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
static CGFloat const DefaultThumbPxWidth = 31; //Size of apple's default thumb icon.

@implementation Tick
// Constructor for a tick
- (id)initWithPosition:(CGFloat)position {
    position = ROUNDF(position, 1000); // Round to three decimal places to eliminate chances of float inprecision on comparisons.
    NSAssert(position >= 0 && position <= 1, @"Position must be between 0 and 1");
    self = [super init];
    if (self) {
        self.position = position;
    }
    return self;
}
@end

@interface HUMSlider ()

@property (atomic) NSMutableArray *tickViews;
@property (atomic) NSMutableArray *allTickBottomConstraints;

//Constraint storage for dynamically spaced tick constraints.
@property (atomic) NSMutableArray *middleTickConstraints;

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
    
    self.allTickBottomConstraints = [NSMutableArray array];
    self.middleTickConstraints = [NSMutableArray array];
    
    self.lowerTicksOnInactiveTouch = true; //default to lowering them.
    self.customTicksEnabled = false; //default to true
    self.enableTicksTransparencyOnIdle = true; // keep ticks at all times.
    
    // Set default values.
    self.sectionCount = 9;
    self.tickAlphaAnimationDuration = HUMTickAlphaDuration;
    self.tickMovementAnimationDuration = HUMTickMovementDuration;
    self.secondTickMovementAndimationDuration = HUMSecondTickDuration;
    self.nextTickAnimationDelay = HUMTickAnimationDelay;
    
    // Private var init
    if (self.ticks == nil) {
        self.ticks = [NSMutableArray new];
    }
    
    // These will set the side colors.
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

- (void)setCustomTicksEnabled:(BOOL)customTicksEnabled {
    if (customTicksEnabled != self.customTicksEnabled) {
        _customTicksEnabled = customTicksEnabled;
        [self removeAllTicks];
        NSLog(@"INFO: Slider mode changed to customTicksEnabled: %@, all ticks removed", self.customTicksEnabled ? @"true" : @"false");
    }
    else {
        NSLog(@"Slider mode unchanged, customTicksEnabled was already set to %@", self.customTicksEnabled ? @"true" : @"false");
    }
}

#pragma mark - Ticks

- (void)addTick:(Tick*)tick willRefreshView:(BOOL)refreshView {
    
    NSAssert(self.customTicksEnabled, @"Custom ticks must be enabled to use the add Tick API method.");
    
    if ([self.ticks count] == 0) {
        [self.ticks addObject:tick];
        [self setupTickAutoLayoutForIndex:0 withTick:tick refreshView:refreshView];
    }
    else { // Sorted-ly add the tick in the right sorted order.
        NSUInteger index = [self.ticks count];
        for (Tick *tickItr in [self.ticks reverseObjectEnumerator]) {
            if (tick.position >= tickItr.position) {
                [self.ticks insertObject:tick atIndex:index];
                [self setupTickAutoLayoutForIndex:index withTick:tick refreshView:refreshView];
                break;
            }
            index --;
        }
    }
    
    [self checkIntegrity];
    
    if (refreshView) {
        [self layoutIfNeeded];
        [self updateTickHeights];
    }
}

- (void)removeTickAtIndex:(NSUInteger)index refreshView:(BOOL)refreshView {
    
    // Remove the tick object itself
    [self.ticks removeObjectAtIndex:index];
    
    // Remove the view and remove tracked constraints, the view removes constraints as part of "removeFromSuperview"
    [self removeConstraintFromList:self.middleTickConstraints constraintAtIndex:index];
    [self removeConstraintFromList:self.allTickBottomConstraints constraintAtIndex:index];
    UIView *tickView = [self.tickViews objectAtIndex:index];
    [self.tickViews removeObjectAtIndex:index];
    [tickView removeFromSuperview];
    
    [self checkIntegrity];
    
    if (refreshView) {
        [self updateTickHeights];
        [self setNeedsLayout];
    }
}

- (void)removeAllTicks {
    for (NSUInteger i = [self.ticks count] - 1; i > 0 ; i--) {
        [self removeTickAtIndex:i refreshView:NO];
    }
    [self removeTickAtIndex:0 refreshView:YES]; // Refresh on last one.
    [self layoutIfNeeded];
}

- (void)nukeOldTicksAndViews
{
    for (UIView *tick in self.tickViews) {
        [tick removeFromSuperview];
    }
    
    self.ticks = [NSMutableArray new];
    self.tickViews = [NSMutableArray new];
    self.middleTickConstraints = [NSMutableArray new];
    self.allTickBottomConstraints = [NSMutableArray new];
    
    [self checkIntegrity];
    
    [self layoutIfNeeded];
}

// Setup evenly spaced ticks per sectionCount
- (void)setupConsitentlySpacedTickMarks {
    NSAssert(!self.customTicksEnabled, @"Internal Consistency - should not be setting up consistently spaced tick marks here.");
    self.ticks = [NSMutableArray new];
    CGFloat tickDistances = 1.0 / (self.sectionCount + 1);
    CGFloat spacingSoFar = 0;
    for (NSUInteger i = 0 ; i < self.sectionCount; i++) {
        Tick *newTick = [[Tick alloc] initWithPosition:spacingSoFar + tickDistances];
        [self.ticks addObject:newTick];
        [self setupTickAutoLayoutForIndex:i withTick:newTick refreshView:NO];
        spacingSoFar += tickDistances;
    }
    [self checkIntegrity];
    [self layoutIfNeeded];
}

// Helper method to remove a constraint from our tracked constraint lists and our view.
- (void)removeConstraintFromList:(NSMutableArray*)constraintList constraintAtIndex:(CGFloat)index{
    NSLayoutConstraint *constraint = [constraintList objectAtIndex:index];
    [self removeConstraint:constraint];
    [constraintList removeObjectAtIndex:index];
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

- (void)setupTickAutoLayoutForIndex:(CGFloat)index withTick:(Tick*)newlyAddedTick refreshView:(BOOL)refreshView  {

    UIView *currentItem = [self setupCommonTickViewAndAddToSubview];
    
    [self.tickViews insertObject:currentItem atIndex:index];

    NSLayoutConstraint *bottomConstraint = [self pinTickBottom:currentItem];
    [self addConstraint:bottomConstraint];
    [self.allTickBottomConstraints insertObject:bottomConstraint atIndex:index];
    [self pinTickWidthAndHeight:currentItem];
    
    CGFloat constant = [self tickPixelOffsetFromMiddle:newlyAddedTick];
    
    // Pin the middle tick to the middle of the slider.
    NSLayoutConstraint *middle = [NSLayoutConstraint constraintWithItem:currentItem
                                                              attribute:NSLayoutAttributeCenterX
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self
                                                              attribute:NSLayoutAttributeCenterX
                                                             multiplier:1
                                                               constant:constant];
    
    [self addConstraint:middle];
    [self.middleTickConstraints addObject:middle];
    
    [self checkIntegrity];
    
    if (refreshView)
        [self layoutIfNeeded];
}

// Size of the tick itself.
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

- (void)checkIntegrity {
    // Transitivity
    NSAssert([self.middleTickConstraints count] == [self.allTickBottomConstraints count], @"Internal Consistency Error");
    NSAssert([self.allTickBottomConstraints count] == [self.tickViews count], @"Internal Consistency Error");
    NSAssert([self.tickViews count] == [self.ticks count], @"Internal Consistency Error");
}

#pragma mark - General layout

- (void)layoutSubviews
{
    trackRect = [self trackRectForBounds:self.bounds];
    
    [super layoutSubviews];

    [self updateCustomTickConstraintsIfNeeded];
}

- (void)updateCustomTickConstraintsIfNeeded
{
    if ([self.tickViews count] == 0) {
        return;
    }
    
    NSLayoutConstraint *firstLeft = self.middleTickConstraints.firstObject;
    
    Tick *firstTick = self.ticks[0];
    
    CGFloat constant = [self tickPixelOffsetFromMiddle:firstTick];
    
    if (firstLeft.constant != constant) {

        for (NSInteger i = 0; i < [self.tickViews count]; i++) {
            NSLayoutConstraint *middleConstraint = self.middleTickConstraints[i];
            Tick *theTick = self.ticks[i];
            middleConstraint.constant = [self tickPixelOffsetFromMiddle:theTick];
        }
    
        [self layoutIfNeeded];
    }
}

- (void)refreshView {
    if (!self.enableTicksTransparencyOnIdle) {
        [self animateAllTicksIn:YES];
    }
    [self updateTickHeights];
    [self layoutIfNeeded];
}

#pragma mark - Overridden Setters

- (void)setValue:(float)value
{
    [super setValue:value];
    [self sliderAdjusted];
}

- (void)setSectionCount:(NSUInteger)sectionCount
{
    _sectionCount = sectionCount;
    
    if (self.customTicksEnabled) {
        NSLog(@"WARNING: Custom ticks are enabled so sectionCount won't work");
    }
    else {
        [self nukeOldTicksAndViews];
        if (!self.customTicksEnabled) {
            [self setupConsitentlySpacedTickMarks];
        }
    }
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
            tick.backgroundColor = self.tickColor;
        }
    }
}

#pragma mark - UIControl touch event tracking

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [self updateCustomTickConstraintsIfNeeded];
    [self animateAllTicksIn:YES];
    
    [self popTickIfNeededFromTouch:touch];
    
    return [super beginTrackingWithTouch:touch withEvent:event];
}

- (void)updateTickHeights {
    if (![NSThread isMainThread]) { // Available to the dev for playback type development, can be called from bg thread.
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateTickHeights];
        });
        return;
    }

    CGRect trackRect = [self trackRectForBounds:self.bounds];
    CGRect thumbRect = [self thumbRectForBounds:self.bounds
                                      trackRect:trackRect
                                          value:self.value];

    CGFloat sliderLoc = CGRectGetMidX(thumbRect);
    
    // Animate tick based on the thumb location
    for (NSInteger i = 0; i < self.tickViews.count; i++) {
        [self animateCustomTickIfNeededAtIndex:i forTouchX:sliderLoc];
    }
}

#pragma mark Animate In

- (void)animateCustomTickIfNeededAtIndex:(NSInteger)tickIndex forTouchX:(CGFloat)touchX
{
    UIView *tick = self.tickViews[tickIndex];

    NSLayoutConstraint *constraint = self.middleTickConstraints[tickIndex];
    
    CGFloat tickDistanceFromLeft = (trackRect.size.width / 2) + (constraint.constant) + trackRect.origin.x;
    CGFloat thumbSliderRadius = [self thumbImageWidth] / 2;
    
    CGFloat startSegmentX = tickDistanceFromLeft - thumbSliderRadius;
    CGFloat endSegmentX = tickDistanceFromLeft + thumbSliderRadius;
    
    CGFloat desiredOrigin;
    if (startSegmentX <= touchX && endSegmentX > touchX) {
        // Pop up and meld tick to slide over the thumb image as it passes by, which can be slow on playback.
        desiredOrigin = [self tickPoppedPosition];
        CGFloat Xdiff = fabs(touchX - tickDistanceFromLeft);
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
    for (NSUInteger i = 0; i < self.tickViews.count; i++) {
        [self animateCustomTickIfNeededAtIndex:i forTouchX:sliderLoc];
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

    [self animateAllTicksIn:NO];
}

#pragma mark - Tick Animation

// To Remove - my method for custom widths
- (void)animateAllTicksIn:(BOOL)inPosition
{
    CGFloat origin;
    CGFloat alpha;
    
    if (inPosition) { // Ticks are out, coming in
        alpha = 1;
        origin = [self tickInNotPoppedPositon];
    } else { // Ticks are in, coming out.
        alpha = self.enableTicksTransparencyOnIdle ? 0 : 1; // Transparent if setting is enabed.
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

- (void)animateTickAtIndex:(NSInteger)index
                 toYOrigin:(CGFloat)yOrigin
              withDuration:(NSTimeInterval)duration
                     delay:(NSTimeInterval)delay
{
    
    if (![NSThread isMainThread]) { // This can be called by the updateTickHeights method by the dev on the background thread.
        dispatch_async(dispatch_get_main_queue(), ^{
            [self animateTickAtIndex:index toYOrigin:yOrigin withDuration:duration delay:delay];
        });
        return;
    }
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
    CGFloat trackWidth = trackRect.size.width - [self thumbImageWidth] + trackRect.origin.x; // :)
    CGFloat constant = (tick.position * trackWidth) - (trackWidth / 2);
    return constant;
}

- (CGFloat)thumbImageWidth
{
    CGFloat imgThumbImageWidth = self.currentThumbImage.size.width;
    // CASE if the thumb image width is set, is nonzero and doesn't match our current var, set the var to the correct value.
    if (imgThumbImageWidth && imgThumbImageWidth != 0 && imgThumbImageWidth != thumbImageWidth) {
        thumbImageWidth = imgThumbImageWidth;
    }
    // CASE: if it isn't set or is 0, it is wrong - it will use apple's default thumb image size.
    else if (!thumbImageWidth || thumbImageWidth == 0) { // No custom image set, use apple's default
        thumbImageWidth = DefaultThumbPxWidth;
    }
    return thumbImageWidth;
}

@end
