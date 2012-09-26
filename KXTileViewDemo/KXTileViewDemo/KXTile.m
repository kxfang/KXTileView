//
//  KXTile.m
//  KXTileViewDemo
//
//  Created by Kevin Fang on 12-9-23.
//  Copyright (c) 2012年 Kevin Fang. All rights reserved.
//

#import "KXTile.h"
#import <QuartzCore/QuartzCore.h>

#define KXTILE_TOUCH_TRANSFORM_SCALE 0.97

typedef enum {
    KXTileTouchStatePressed,
    KXTileTouchStateDefault
} KXTileTouchState;

@interface KXTile ()

@property (nonatomic, assign) KXTileTouchState touchState;
@property (nonatomic, assign) id target;
@property (nonatomic, assign) SEL touchAction;

@end


@implementation KXTile

@synthesize shouldBounceOnTouch = _shouldBounceOnTouch;

@synthesize touchState = _touchState;
@synthesize target = _target;
@synthesize touchAction = _touchAction;

@synthesize contentView = _contentView;
@synthesize clippingView = _clippingView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.touchState = KXTileTouchStateDefault;
        
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
        [self addGestureRecognizer:tapRecognizer];
        [tapRecognizer release];
        
        CALayer *layer = self.layer;        
        layer.shouldRasterize = YES;
        layer.shadowOffset = CGSizeMake(0.0, 2.0);
        layer.shadowColor = [UIColor blackColor].CGColor;
        layer.shadowOpacity = 1.0;
        layer.shadowRadius = 0.0;
        self.clipsToBounds = NO;
        
        UIView *clippingView = [[UIView alloc] initWithFrame:self.bounds];
        clippingView.clipsToBounds = YES;
        clippingView.alpha = 1.0;
        [self addSubview:clippingView];
        [self sendSubviewToBack:clippingView];
        self.clippingView = clippingView;
        [clippingView release];
        
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        self.clippingView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;

        self.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.bounds].CGPath;
        
        self.contentView = nil;
        self.shouldBounceOnTouch = YES;
    }
    return self;
}

- (void)dealloc
{
    self.clippingView = nil;
    [super dealloc];
}

- (void)transformOnTouch
{
    if (self.shouldBounceOnTouch) {
        self.transform = CGAffineTransformMakeScale(KXTILE_TOUCH_TRANSFORM_SCALE, KXTILE_TOUCH_TRANSFORM_SCALE);
    }
}

- (void)transformOnTouchEnded
{
    if (self.shouldBounceOnTouch) {
        self.transform = CGAffineTransformMakeScale(1.0, 1.0);
    }
}

- (void)handleGesture:(UIGestureRecognizer *)recognizer
{
    [UIView animateWithDuration:0.1 animations:^{
        [self transformOnTouch];
    } completion:^(BOOL finished){
        [UIView animateWithDuration:0.1 animations:^{
            [self transformOnTouchEnded];
        } completion:^(BOOL finished){
            [self.target performSelector:self.touchAction withObject:self];
        }];
    }];
}

- (void)setTouchState:(KXTileTouchState)touchState
{
    if (_touchState != touchState) {
        _touchState = touchState;
        
        [UIView animateWithDuration:0.2 animations:^{
        switch (touchState) {
            case KXTileTouchStatePressed:
                [self transformOnTouch];
                break;
                
            case KXTileTouchStateDefault:
                [self transformOnTouchEnded];
                break;
        }}];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.touchState = KXTileTouchStatePressed;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([touches count] > 1) {
        self.touchState = KXTileTouchStateDefault;
    }
    else if (CGRectContainsPoint(self.bounds, [[touches anyObject] locationInView:self])) {
        self.touchState = KXTileTouchStateDefault;
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.touchState = KXTileTouchStateDefault;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.touchState = KXTileTouchStateDefault;
}

- (void)addTarget:(id)target action:(SEL)action {
    self.target = target;
    self.touchAction = action;
}

- (void)setContentView:(UIView *)contentView {
    if (self.contentView.superview != nil) {
        [self.contentView removeFromSuperview];
    }
    [_contentView release];
    _contentView = contentView;
    [self.clippingView addSubview:contentView];
}


@end
