//
//  KXTile.h
//  KXTileViewDemo
//
//  Created by Kevin Fang on 12-9-23.
//  Copyright (c) 2012年 Kevin Fang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KXTile : UIView

@property (nonatomic, retain) UIView *contentView;
@property (nonatomic, retain) UIView *clippingView;
@property (nonatomic, assign) BOOL shouldBounceOnTouch;

- (void)addTarget:(id)target action:(SEL)action;
- (void)resetShadow;

@end
