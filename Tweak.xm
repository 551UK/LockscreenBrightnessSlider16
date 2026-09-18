#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>\n#import <math.h>

@interface CSQuickActionsView : UIView
@property (nonatomic, retain) UIView *cameraButton;
@property (nonatomic, retain) UIView *flashlightButton;
- (BOOL)interpretsLocationAsContent:(CGPoint)location inView:(UIView *)view;
@end

@interface LSBSBrightnessSlider : UIControl {
    UIView *_trackView;
    UIView *_fillView;
    UIView *_thumbView;
}
@property (nonatomic, assign) CGFloat brightnessValue;
@end

@implementation LSBSBrightnessSlider

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }

    self.backgroundColor = UIColor.clearColor;
    self.clipsToBounds = NO;
    self.exclusiveTouch = YES;
    self.accessibilityLabel = @"Brightness";
    self.accessibilityTraits = UIAccessibilityTraitAdjustable;

    _trackView = [[UIView alloc] initWithFrame:CGRectZero];
    _trackView.userInteractionEnabled = NO;
    _trackView.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.58];
    _trackView.layer.borderWidth = 0.5;
    _trackView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.22].CGColor;
    [self addSubview:_trackView];

    _fillView = [[UIView alloc] initWithFrame:CGRectZero];
    _fillView.userInteractionEnabled = NO;
    _fillView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.92];
    [_trackView addSubview:_fillView];

    _thumbView = [[UIView alloc] initWithFrame:CGRectZero];
    _thumbView.userInteractionEnabled = NO;
    _thumbView.backgroundColor = UIColor.whiteColor;
    _thumbView.layer.shadowColor = UIColor.blackColor.CGColor;
    _thumbView.layer.shadowOpacity = 0.22;
    _thumbView.layer.shadowRadius = 2.0;
    _thumbView.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    [self addSubview:_thumbView];

    _brightnessValue = UIScreen.mainScreen.brightness;
    [self updateAccessibilityValue];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(screenBrightnessDidChange:)
                                                 name:UIScreenBrightnessDidChangeNotification
                                               object:nil];

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    const CGFloat thumbDiameter = 22.0;
    const CGFloat trackHeight = 7.0;
    const CGFloat trackInset = thumbDiameter * 0.5;

    CGFloat usableWidth = MAX(0.0, CGRectGetWidth(self.bounds) - (trackInset * 2.0));
    CGFloat centerY = CGRectGetMidY(self.bounds);

    _trackView.frame = CGRectMake(trackInset,
                                  centerY - (trackHeight * 0.5),
                                  usableWidth,
                                  trackHeight);
    _trackView.layer.cornerRadius = trackHeight * 0.5;

    CGFloat fillWidth = usableWidth * self.brightnessValue;
    _fillView.frame = CGRectMake(0.0, 0.0, fillWidth, trackHeight);
    _fillView.layer.cornerRadius = trackHeight * 0.5;

    CGFloat thumbX = trackInset + fillWidth;
    _thumbView.bounds = CGRectMake(0.0, 0.0, thumbDiameter, thumbDiameter);
    _thumbView.center = CGPointMake(thumbX, centerY);
    _thumbView.layer.cornerRadius = thumbDiameter * 0.5;
    _thumbView.layer.shadowPath = [UIBezierPath bezierPathWithOvalInRect:_thumbView.bounds].CGPath;
}

- (void)setBrightnessValue:(CGFloat)brightnessValue {
    brightnessValue = MIN(1.0, MAX(0.0, brightnessValue));

    if (fabs(_brightnessValue - brightnessValue) < 0.0001) {
        return;
    }

    _brightnessValue = brightnessValue;
    [self updateAccessibilityValue];
    [self setNeedsLayout];
}

- (void)updateAccessibilityValue {
    self.accessibilityValue = [NSString stringWithFormat:@"%ld%%", (long)lrint(self.brightnessValue * 100.0)];
}

- (void)screenBrightnessDidChange:(NSNotification *)notification {
    self.brightnessValue = UIScreen.mainScreen.brightness;
}

- (void)applyTouch:(UITouch *)touch {
    const CGFloat thumbRadius = 11.0;
    CGFloat usableWidth = MAX(1.0, CGRectGetWidth(self.bounds) - (thumbRadius * 2.0));
    CGFloat x = [touch locationInView:self].x;
    CGFloat value = (x - thumbRadius) / usableWidth;
    value = MIN(1.0, MAX(0.0, value));

    self.brightnessValue = value;
    UIScreen.mainScreen.brightness = value;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (BOOL)beginTracking:(UITouch *)touch withEvent:(UIEvent *)event {
    [self applyTouch:touch];
    return YES;
}

- (BOOL)continueTracking:(UITouch *)touch withEvent:(UIEvent *)event {
    [self applyTouch:touch];
    return YES;
}

- (void)endTracking:(UITouch *)touch withEvent:(UIEvent *)event {
    if (touch) {
        [self applyTouch:touch];
    }
}

- (void)accessibilityIncrement {
    CGFloat value = MIN(1.0, self.brightnessValue + 0.05);
    self.brightnessValue = value;
    UIScreen.mainScreen.brightness = value;
}

- (void)accessibilityDecrement {
    CGFloat value = MAX(0.0, self.brightnessValue - 0.05);
    self.brightnessValue = value;
    UIScreen.mainScreen.brightness = value;
}

@end

static void *LSBSSliderAssociationKey = &LSBSSliderAssociationKey;

static LSBSBrightnessSlider *LSBSSliderForQuickActionsView(CSQuickActionsView *view, BOOL createIfNeeded) {
    LSBSBrightnessSlider *slider = objc_getAssociatedObject(view, LSBSSliderAssociationKey);

    if (!slider && createIfNeeded) {
        slider = [[LSBSBrightnessSlider alloc] initWithFrame:CGRectZero];
        slider.alpha = 1.0;
        [view addSubview:slider];
        objc_setAssociatedObject(view, LSBSSliderAssociationKey, slider, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    return slider;
}

static CGRect LSBSRectForViewInsideHost(UIView *child, UIView *host) {
    if (!child || !host) {
        return CGRectZero;
    }

    return [child convertRect:child.bounds toView:host];
}

static void LSBSLayoutBrightnessSlider(CSQuickActionsView *host) {
    UIView *flashlight = host.flashlightButton;
    UIView *camera = host.cameraButton;
    LSBSBrightnessSlider *slider = LSBSSliderForQuickActionsView(host, YES);

    if (!flashlight || !camera ||
        flashlight.hidden || camera.hidden ||
        flashlight.alpha < 0.01 || camera.alpha < 0.01) {
        slider.hidden = YES;
        return;
    }

    CGRect flashlightRect = LSBSRectForViewInsideHost(flashlight, host);
    CGRect cameraRect = LSBSRectForViewInsideHost(camera, host);

    if (CGRectIsEmpty(flashlightRect) || CGRectIsEmpty(cameraRect)) {
        slider.hidden = YES;
        return;
    }

    CGRect leftRect = flashlightRect;
    CGRect rightRect = cameraRect;

    if (CGRectGetMidX(leftRect) > CGRectGetMidX(rightRect)) {
        CGRect temporary = leftRect;
        leftRect = rightRect;
        rightRect = temporary;
    }

    /*
     * The visible track begins 24 pt from each quick-action circle.
     * The slider's touch frame extends another 11 pt at each end so the
     * 22 pt thumb can move through the full range without clipping.
     */
    const CGFloat visualGap = 24.0;
    const CGFloat thumbRadius = 11.0;
    const CGFloat sliderHeight = 44.0;

    CGFloat leftEdge = CGRectGetMaxX(leftRect);
    CGFloat rightEdge = CGRectGetMinX(rightRect);

    CGFloat sliderX = leftEdge + visualGap - thumbRadius;
    CGFloat sliderRight = rightEdge - visualGap + thumbRadius;
    CGFloat sliderWidth = sliderRight - sliderX;

    if (sliderWidth < 90.0) {
        slider.hidden = YES;
        return;
    }

    CGFloat buttonsCenterY = (CGRectGetMidY(leftRect) + CGRectGetMidY(rightRect)) * 0.5;
    slider.frame = CGRectIntegral(CGRectMake(sliderX,
                                             buttonsCenterY - (sliderHeight * 0.5),
                                             sliderWidth,
                                             sliderHeight));

    slider.hidden = NO;
    slider.brightnessValue = UIScreen.mainScreen.brightness;

    // Keep the slider above the quick-actions background but do not disturb the buttons.
    [host bringSubviewToFront:slider];
    [host bringSubviewToFront:flashlight];
    [host bringSubviewToFront:camera];
}

%hook CSQuickActionsView

- (void)layoutSubviews {
    %orig;
    LSBSLayoutBrightnessSlider(self);
}

- (BOOL)interpretsLocationAsContent:(CGPoint)location inView:(UIView *)view {
    LSBSBrightnessSlider *slider = LSBSSliderForQuickActionsView(self, NO);

    if (slider && !slider.hidden && slider.alpha > 0.01) {
        UIView *sourceView = view ?: self;
        CGPoint pointInSlider = [sourceView convertPoint:location toView:slider];

        if ([slider pointInside:pointInSlider withEvent:nil]) {
            return YES;
        }
    }

    return %orig;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    LSBSBrightnessSlider *slider = LSBSSliderForQuickActionsView(self, NO);

    if (slider && !slider.hidden && slider.userInteractionEnabled && slider.alpha > 0.01) {
        CGPoint pointInSlider = [self convertPoint:point toView:slider];

        if ([slider pointInside:pointInSlider withEvent:event]) {
            UIView *hitView = [slider hitTest:pointInSlider withEvent:event];
            if (hitView) {
                return hitView;
            }
        }
    }

    return %orig;
}

%end
