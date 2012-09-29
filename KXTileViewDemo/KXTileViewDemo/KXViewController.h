//
//  KXViewController.h
//  Test1
//
//  Created by Kevin Fang on 12-9-19.
//  Copyright (c) 2012年 Kevin Fang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KXTileView.h"

@interface KXViewController : UIViewController <KXTileViewDataSource, KXTileViewDelegate>

- (NSInteger)numberOfTilesInTileView:(KXTileView *)tileView;
- (UIView *)tileView:(KXTileView *)tileView contentViewForTileAtIndex:(NSInteger)index withFrame:(CGRect)frame;

- (BOOL)tileView:(KXTileView *)tileView canShowTileWithWidthLessEqualTo:(KXTileColumnWidth) width atIndex:(NSInteger)index;

- (void)tileView:(KXTileView *)tileView didSwipeTileAtIndex:(NSInteger)index;

@end
