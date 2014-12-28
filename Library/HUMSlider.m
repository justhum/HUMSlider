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

@interface HUMSlider ()
@property (nonatomic) NSArray *tickViews;
@property (nonatomic) NSArray *tickBottomConstraints;
@property (nonatomic) NSArray *tickLeftConstraints;

@property (nonatomic) UIImage *leftTemplate;
@property (nonatomic) UIImage *rightTemplate;

@property (nonatomic) UIImageView *leftSaturatedImageView;
@property (nonatomic) UIImageView *leftDesaturatedImageView;
@property (nonatomic) UIImageView *rightSaturatedImageView;
@property (nonatomic) UIImageView *rightDesaturatedImageView;

@end

@implementation HUMSlider

#pragma mark - Init

- (void)commonInit
{
    //Set default values.
    self.sectionCount = 9;
    
    self.saturatedColor = [UIColor redColor];
    self.desaturatedColor = [UIColor lightGrayColor];
    self.tickColor = [UIColor darkGrayColor];
    
    //Add self as target.
    [self addTarget:self
             action:@selector(sliderAdjusted)
   forControlEvents:UIControlEventValueChanged];
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

#pragma mark - Ticks

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
        [self sendSubviewToBack:tick];
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
                                                          constant:HUMTickWidth]];
        // Pin height of tick
        [self addConstraint:[NSLayoutConstraint constraintWithItem:currentTick
                                                         attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:0
                                                        multiplier:1
                                                          constant:HUMTickHeight]];
        
        // Pin bottom of tick to top of track.
        NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:currentTick
                                                                  attribute:NSLayoutAttributeBottom
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self
                                                                  attribute:NSLayoutAttributeBottom
                                                                 multiplier:1
                                                                   constant:[self tickOutPosition]];
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
                                                 constant:self.segmentWidth - HUMTickWidth];
        } else {
            left = [NSLayoutConstraint constraintWithItem:currentTick
                                                attribute:NSLayoutAttributeLeading
                                                relatedBy:NSLayoutRelationEqual
                                                   toItem:self
                                                attribute:NSLayoutAttributeLeading
                                               multiplier:1
                                                 constant:self.halfSegment - HUMTickWidth];
        }
        
        [self addConstraint:left];
        [lefts addObject:left];
    }
    
    self.tickBottomConstraints = bottoms;
    self.tickLeftConstraints = lefts;
    [self layoutIfNeeded];
}

#pragma mark - Images

- (void)setupSaturatedAndDesaturatedImageViews
{
    //Left
    self.leftDesaturatedImageView = [[UIImageView alloc] init];
    self.leftDesaturatedImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.leftDesaturatedImageView];
    
    self.leftSaturatedImageView = [[UIImageView alloc] init];
    self.leftSaturatedImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.leftSaturatedImageView.alpha = 0.0f;
    [self addSubview:self.leftSaturatedImageView];

    //Right
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
    
    //Reset colors
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
    [super layoutSubviews];
    [self updateLeftTickConstraintsIfNeeded];
}

- (void)updateLeftTickConstraintsIfNeeded
{
    NSLayoutConstraint *firstLeft = self.tickLeftConstraints.firstObject;
    if (firstLeft.constant != (self.trackXOrigin + self.halfSegment - HUMTickWidth)) {
        // Need to be relaid out
        for (NSInteger i = 0; i < self.tickLeftConstraints.count; i++) {
            NSLayoutConstraint *left = self.tickLeftConstraints[i];
            if (i == 0) {
                left.constant = self.trackXOrigin + self.halfSegment - HUMTickWidth;
            } else {
                left.constant = self.segmentWidth - HUMTickWidth;
            }
            
            [self layoutIfNeeded];
        }
    } // else good to go.
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
    
    [self nukeOldTicks];
    [self setupTicks];
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
    
    [self layoutIfNeeded];
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
    
    [self layoutIfNeeded];
}

- (void)setSaturatedColor:(UIColor *)saturatedColor
{
    _saturatedColor = saturatedColor;
    self.leftSaturatedImageView.tintColor = _saturatedColor;
    self.rightSaturatedImageView.tintColor = _saturatedColor;
}

- (void)setDesaturatedColor:(UIColor *)desaturatedColor
{
    _desaturatedColor = desaturatedColor;
    self.leftDesaturatedImageView.tintColor = _desaturatedColor;
    self.rightDesaturatedImageView.tintColor = _desaturatedColor;
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
    // Update the width
    [self updateLeftTickConstraintsIfNeeded];
    [self animateAllTicksIn:YES];
    [self popTickIfNeededFromTouch:touch];
    
    return [super beginTrackingWithTouch:touch withEvent:event];
}

- (void)animateTickIfNeededAtIndex:(NSInteger)tickIndex forTouchX:(CGFloat)touchX
{
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
                    withDuration:HUMTickMovementDuration
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
    CGFloat origin;
    CGFloat alpha;
    
    if (inPosition) { // ticks are out, coming in
        alpha = 1;
        origin = [self tickInNotPoppedPositon];
    } else { // Ticks are in, coming out.
        alpha = 0;
        origin = [self tickOutPosition];
    }
    
    [UIView animateWithDuration:HUMTickAlphaDuration
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
                        withDuration:HUMTickMovementDuration
                               delay:0];
        } else if (nextHighest - nextLowest == 2) {
            // Second tick
            [self animateTickAtIndex:nextHighest
                           toYOrigin:origin
                        withDuration:HUMSecondTickDuration
                               delay:HUMTickAnimationDelay * i];
            [self animateTickAtIndex:nextLowest
                           toYOrigin:origin
                        withDuration:HUMSecondTickDuration
                               delay:HUMTickAnimationDelay * i];
        } else {
            // Rest of ticks
            [self animateTickAtIndex:nextHighest
                           toYOrigin:origin
                        withDuration:HUMTickMovementDuration
                               delay:HUMTickAnimationDelay * i];
            [self animateTickAtIndex:nextLowest
                           toYOrigin:origin
                        withDuration:HUMTickMovementDuration
                               delay:HUMTickAnimationDelay * i];
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

- (CGFloat)halfSegment
{
    return self.segmentWidth / 2.0f;
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
    return [self tickInNotPoppedPositon] - [self tickInToPoppedDifferential];
}

@end
