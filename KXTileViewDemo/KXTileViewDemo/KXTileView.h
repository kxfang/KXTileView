//
//  KXTileView.h
//  Test1
//
//  Created by Kevin Fang on 12-9-19.
//  Copyright (c) 2012年 Kevin Fang. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    kTileColumnWidth1 = 1,
    kTileColumnWidth2
} KXTileColumnWidth;  //enum representing how many columns a tile takes up. width1 == 1 tile

@protocol KXTileViewDataSource;
@protocol KXTileViewDelegate;

@interface KXTileView : UIView <UIScrollViewDelegate>

@property (nonatomic, assign) CGFloat pageWidth;
@property (nonatomic, assign) CGFloat rowsPerPage;
@property (nonatomic, assign) CGFloat columnsPerPage;
@property (nonatomic, assign) CGFloat marginHeight;   //height of horizontal margins between tiles; default is 5
@property (nonatomic, assign) CGFloat marginWidth;     //width of vertical margins between tiles; default is 5

@property (nonatomic, assign) id<KXTileViewDelegate>delegate;
@property (nonatomic, assign) id<KXTileViewDataSource>dataSource;

@property (nonatomic, assign) BOOL swipeActionEnabled;

- (CGFloat)tileWidthForTileColumnWidth:(KXTileColumnWidth)tileColumnWidth;
- (CGFloat)tileHeight;

- (void)resetLayout;
- (void)zoomIntoTileAtIndex:(NSInteger)index;
- (void)zoomOutOfTile;


//scroll view delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView;

@end

@protocol KXTileViewDataSource <NSObject>

- (NSInteger)numberOfTilesInTileView:(KXTileView *)tileView;
- (UIView *)tileView:(KXTileView *)tileView contentViewForTileAtIndex:(NSInteger)index withFrame:(CGRect)frame;

@optional

- (BOOL)tileView:(KXTileView *)tileView canShowTileWithWidthLessEqualTo:(KXTileColumnWidth)width atIndex:(NSInteger)index;
- (CGFloat)tileView:(KXTileView *)tileView heightForViewForSwipedTileAtIndex:(NSInteger)index;
- (UIView *)tileView:(KXTileView *)tileView contextViewForSwipedTileAtIndex:(NSInteger)index;

@end

@protocol KXTileViewDelegate <NSObject>

@optional

- (void)tileView:(KXTileView *)tileView didSelectTileAtIndex:(NSInteger)index;
- (void)tileView:(KXTileView *)tileView didFinishZoomInTileAtIndex:(NSInteger)index;
- (void)tileView:(KXTileView *)tileView didFinishZoomOutTileAtIndex:(NSInteger)index;

@end