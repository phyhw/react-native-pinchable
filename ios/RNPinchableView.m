//
//  RNPinchableView.m
//  RNPinchable
//
//  Created by Joel Arvidsson on 2019-01-06.
//  Copyright © 2019 Joel Arvidsson. All rights reserved.
//

#import "RNPinchableView.h"
@interface RNPinchableView ()

@property (weak ) UIView *initialSuperView;
@property (weak ) UIView *backgroundView;
@end
@implementation RNPinchableView {
    BOOL isActive;
    NSUInteger lastNumberOfTouches;
    NSUInteger initialIndex;
    CGRect initialFrame;
    CGPoint initialTouchPoint;
    CGPoint initialAnchorPoint;
    CGPoint lastTouchPoint;
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if ((self = [super initWithFrame:frame])) {
    _minimumZoomScale = 1.0;
    _maximumZoomScale = 3.0;
    [self resetGestureState];
    [self setupGesture];
  }
  return self;
}

- (void)resetGestureState
{
  isActive = NO;
  lastNumberOfTouches = 0;
  self.initialSuperView = nil;
  initialIndex = -1;
  initialFrame = CGRectZero;
  initialTouchPoint = CGPointZero;
  initialAnchorPoint = CGPointZero;
  lastTouchPoint = CGPointZero;
  self.backgroundView = nil;
}

- (void)setupGesture
{
  UIPinchGestureRecognizer *gestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
  gestureRecognizer.delegate = self;
  [self addGestureRecognizer:gestureRecognizer];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
  if (isActive) {
    return NO;
  }
  UIView *view = gestureRecognizer.view;
  UIWindow *window = UIApplication.sharedApplication.keyWindow;
  CGPoint absoluteOrigin = [view.superview convertPoint:view.frame.origin toView:window];
  if (isnan(absoluteOrigin.x) || isnan(absoluteOrigin.y)) {
    return NO;
  }
  return YES;
}

-(UIWindow*)keyWindow
{
    UIWindow        *foundWindow = nil;
    NSArray         *windows = [[UIApplication sharedApplication]windows];
    for (UIWindow   *window in windows) {
        if (window.isKeyWindow) {
            foundWindow = window;
            break;
        }
    }
    return foundWindow;
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)gestureRecognizer
{
  UIView *view = gestureRecognizer.view;
  UIWindow * window = [self keyWindow];
  if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
    lastNumberOfTouches = gestureRecognizer.numberOfTouches;
    initialFrame = view.frame;
    initialTouchPoint = [gestureRecognizer locationInView:window];
    isActive = YES;
    self.initialSuperView = view.superview;
    initialIndex = [self.initialSuperView.subviews indexOfObject:view];
    initialAnchorPoint = view.layer.anchorPoint;
    
    CGPoint center = [gestureRecognizer locationInView:view];
    CGPoint absoluteOrigin = [view.superview convertPoint:view.frame.origin toView:window];
    CGPoint anchorPoint = CGPointMake(center.x/initialFrame.size.width, center.y/initialFrame.size.height);

    UIView * temp = [UIView new];
    self.backgroundView = temp;
    self.backgroundView.backgroundColor = UIColor.blackColor;
    self.backgroundView.frame = window.frame;
    [window addSubview:self.backgroundView];
    [window addSubview:view];
    
    view.layer.anchorPoint = anchorPoint;
    view.center = center;
    view.frame = CGRectMake(absoluteOrigin.x, absoluteOrigin.y, initialFrame.size.width, initialFrame.size.height);
    [self.initialSuperView setNeedsLayout];
    [view setNeedsLayout];
  }
  
  if (gestureRecognizer.state == UIGestureRecognizerStateBegan ||
      gestureRecognizer.state == UIGestureRecognizerStateChanged) {
    
    CGPoint currentTouchPoint = [gestureRecognizer locationInView:window];
    
    if (lastNumberOfTouches != gestureRecognizer.numberOfTouches) {
      lastNumberOfTouches = gestureRecognizer.numberOfTouches;
      CGFloat deltaX = currentTouchPoint.x - lastTouchPoint.x;
      CGFloat deltaY = currentTouchPoint.y - lastTouchPoint.y;
      initialTouchPoint = CGPointMake(initialTouchPoint.x + deltaX, initialTouchPoint.y + deltaY);
    }

    CGFloat scale = MAX(MIN(gestureRecognizer.scale, _maximumZoomScale), _minimumZoomScale);
    CGPoint translate = CGPointMake(currentTouchPoint.x - initialTouchPoint.x, currentTouchPoint.y - initialTouchPoint.y);

    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, translate.x, translate.y);
    transform = CGAffineTransformScale(transform, scale, scale);
    view.transform = transform;
    
    self.backgroundView.layer.opacity = MIN(scale - 1., .7);
    lastTouchPoint = currentTouchPoint;
  }

  if (gestureRecognizer.state == UIGestureRecognizerStateEnded ||
      gestureRecognizer.state == UIGestureRecognizerStateCancelled) {
    [UIView animateWithDuration:0.4 delay:0. usingSpringWithDamping:1 initialSpringVelocity:.6 options:0 animations:^{
      gestureRecognizer.view.transform = CGAffineTransformIdentity;
      self.backgroundView.layer.opacity = 0.;
    } completion:^(BOOL finished) {
      [self.backgroundView removeFromSuperview];
      [self.initialSuperView insertSubview:view atIndex:initialIndex];
      view.layer.anchorPoint = initialAnchorPoint;
      view.frame = initialFrame;
      [self resetGestureState];
    }];
  }
}

@end
