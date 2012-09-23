//
//  KXTile.m
//  KXTileViewDemo
//
//  Created by Kevin Fang on 12-9-23.
//  Copyright (c) 2012年 Kevin Fang. All rights reserved.
//

#import "KXTile.h"
#import <QuartzCore/QuartzCore.h>


@implementation KXTile

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}


- (void)drawRect:(CGRect)rect
{
    CALayer *layer = self.layer;
    CGPathRef path = CGPathCreateWithRect(rect, NULL);
    layer.shadowPath = path;
    CFRelease(path);
    
    layer.shouldRasterize = YES;
    layer.shadowOffset = CGSizeMake(0.0, 3.0);
    layer.shadowColor = [UIColor blackColor].CGColor;
    layer.shadowOpacity = 0.7;
    layer.shadowRadius = 0.2;
    self.clipsToBounds = NO;
}


@end
