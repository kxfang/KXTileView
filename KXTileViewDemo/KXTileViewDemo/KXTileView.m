//
//  KXTileView.m
//  Test1
//
//  Created by Kevin Fang on 12-9-19.
//  Copyright (c) 2012年 Kevin Fang. All rights reserved.
//


#import "KXTileView.h"
#import "KXTile.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

@interface KXTileSlot : NSObject
@property (nonatomic, assign) NSInteger page;
@property (nonatomic, assign) NSInteger row;
@property (nonatomic, assign) NSInteger column;
@property (nonatomic, readonly) NSInteger maxRows;
@property (nonatomic, readonly) NSInteger maxColumns;

- (id)initWithMaxRow:(NSInteger)maxRow maxColumn:(NSInteger)maxColumn;
- (void)increment;

@end

@implementation KXTileSlot
@synthesize page, row, column, maxRows, maxColumns;

- (id)initWithMaxRow:(NSInteger)maxRow maxColumn:(NSInteger)maxColumn
{
    self = [super init];
    if (self) {
        maxRows = maxRow;
        maxColumns = maxColumn;
    }
    return self;
}


- (void)increment
{
    if (self.column >= maxColumns - 1) {
        if (self.row >= self.maxRows -1) {
            self.page++;
            self.row = 0;
            self.column = 0;
        }
        else {
            self.row++;
            self.column = 0;
        }
    }
    else {
        self.column++;
    }
}
@end

@interface KXTileView ()

@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) NSMutableArray *tiles;

//Internal state stuff
@property (nonatomic, assign) NSInteger nextIndexToLoad;
@property (nonatomic, assign) KXTileSlot *nextSlotToLoad;
@property (nonatomic, assign) KXTileSlot *nextEmptySlot;

//Scrolling state stuff
@property (nonatomic, assign) NSInteger previousScrollPage;

- (void)initializeLayout;
- (void)intiializeTiles;
- (void)loadNextPage;

- (CGFloat)originXForTileAtColumn:(NSInteger)column;
- (NSInteger)currentPageIndex;

@end

@implementation KXTileView

//Public properties
@synthesize pageWidth = _pageWidth;
@synthesize rowsPerPage = _rowsPerPage;
@synthesize columnsPerPage = _columnsPerPage;
@synthesize marginHeight = _marginHeight;
@synthesize marginWidth = _verticalMarginWidth;

@synthesize delegate = _delegate;
@synthesize dataSource = _dataSource;

@synthesize nextSlotToLoad = _nextSlotToLoad;
@synthesize nextEmptySlot = _nextEmptySlot;

@synthesize scrollView = _scrollView;

#pragma mark - init methods

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        self.scrollView.backgroundColor = [UIColor blueColor];
        self.scrollView.contentSize = self.bounds.size;
        self.scrollView.delegate = self;
        [self addSubview:self.scrollView];
        
        //intialize properties with default values
        self.pageWidth = self.frame.size.width - 50;
        self.rowsPerPage = 4;
        self.columnsPerPage = 3;
        self.marginHeight = 20;
        self.marginWidth = 20;
        
    }
    return self;
}

- (void)dealloc
{
    self.scrollView = nil;
    self.tiles = nil;
    self.nextEmptySlot = nil;
    self.nextSlotToLoad = nil;
    [super dealloc];
}

- (void)resetLayout
{
    self.nextEmptySlot = nil;
    self.nextSlotToLoad = nil;
    
    for (UIView *tile in self.tiles) {
        [tile removeFromSuperview];
    }
    self.tiles = nil;
    
    _nextEmptySlot = [[KXTileSlot alloc] initWithMaxRow:self.rowsPerPage maxColumn:self.columnsPerPage];
    self.nextEmptySlot.page = 0;
    self.nextEmptySlot.row = 0;
    self.nextEmptySlot.column = 0;
    
    _nextSlotToLoad = [[KXTileSlot alloc] initWithMaxRow:self.rowsPerPage maxColumn:self.columnsPerPage];
    self.nextSlotToLoad.page = 0;
    self.nextSlotToLoad.row = 0;
    self.nextSlotToLoad.column = 0;
    
    //intialize internal store of tiles;
    _tiles = [[NSMutableArray alloc] init];
    
    self.nextIndexToLoad = 0;
    
    [self initializeLayout];
    [self intiializeTiles];
}

#pragma mark - setter/getter overrides

- (void)setDataSource:(id<KXTileViewDataSource>)dataSource
{
    if (_dataSource != dataSource) {
        _dataSource = dataSource;
        [self resetLayout];
    }
}

#pragma mark - convenience methods for returning sizes of rows and cols

- (CGFloat)tileHeight
{
    return (self.frame.size.height - self.marginHeight * (self.rowsPerPage + 1)) / self.rowsPerPage;
}

- (CGFloat)tileWidthForTileColumnWidth:(KXTileColumnWidth)tileColumnWidth
{
    CGFloat singleTileWidth = (self.pageWidth - self.marginWidth * (self.columnsPerPage + 1)) / self.columnsPerPage;
    switch (tileColumnWidth) {
        case kTileColumnWidth1:
            //width per column minus margin
            return singleTileWidth;
            
        case kTileColumnWidth2:
            //width as above multiplied by 2 and add margin between tiles
            return singleTileWidth * 2 + self.marginWidth;
    }
}

#pragma mark - scrollView delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.scrollView.contentOffset.x + self.bounds.size.width * 2 > self.nextSlotToLoad.page * self.pageWidth
        && self.nextIndexToLoad < [self.dataSource numberOfTilesInTileView:self]) {
        [self loadNextPage];
    }
}

#pragma mark - private methods

- (void)initializeLayout
{
    NSInteger numTiles = [self.dataSource numberOfTilesInTileView:self];
    for (int i = 0; i < numTiles; i++) {
        KXTileColumnWidth colWidth = kTileColumnWidth1;
        
        //Figure out how wide the tile will be
        if ([self.dataSource respondsToSelector:@selector(tileView:canShowTileWithWidthLessEqualTo:atIndex:)]) {
            if ([self.dataSource tileView:self canShowTileWithWidthLessEqualTo:kTileColumnWidth2 atIndex:i]
                && self.nextEmptySlot.column + kTileColumnWidth2 <= self.columnsPerPage) {
                colWidth = kTileColumnWidth2;
            }
        }
        
        if (self.scrollView.contentSize.width < (self.nextEmptySlot.page + 1) * self.pageWidth) {
            CGFloat newWidth = self.scrollView.contentSize.width + self.pageWidth;
            self.scrollView.contentSize = CGSizeMake(newWidth, self.scrollView.contentSize.height);
        }

        
        CGRect newFrame = [self frameForTileAtPage:self.nextEmptySlot.page row:self.nextEmptySlot.row column:self.nextEmptySlot.column tileColumnWidth:colWidth];
        KXTile *newTile = [[KXTile alloc] initWithFrame:newFrame];
        newTile.backgroundColor = [UIColor whiteColor];
        
        [newTile addTarget:self action:@selector(handleGesture:)];

        [self.scrollView addSubview:newTile];
        [self.tiles addObject:newTile];
        [newTile release];
                
        //Update nextSlot state
        [self.nextEmptySlot increment];
        if (colWidth == kTileColumnWidth2) {
            [self.nextEmptySlot increment];
        }
    }
}

- (void)intiializeTiles
{
    NSInteger pagesToLoad = MAX((NSInteger) self.bounds.size.width / self.pageWidth * 2, 1);
    for (int i = 0; i < pagesToLoad; i++) {
        [self loadNextPage];
    }
}

- (void)loadNextPage
{
    NSInteger currentPage = self.nextSlotToLoad.page;
    while (currentPage == self.nextSlotToLoad.page && self.nextIndexToLoad < [self.dataSource numberOfTilesInTileView:self]) {
        UIView * tile = [self.tiles objectAtIndex:self.nextIndexToLoad];
        [tile addSubview:[self.dataSource tileView:self contentViewForTileAtIndex:self.nextIndexToLoad]];
        
        [self.nextSlotToLoad increment];
        self.nextIndexToLoad++;
    }
}

- (void)handleGesture:(KXTile *)tile
{
    if ([self.delegate respondsToSelector:@selector(tileView:didSelectTileAtIndex:)]) {
        [self.delegate tileView:self didSelectTileAtIndex:[self.tiles indexOfObject:tile]];
    }
}


#pragma mark - convenience methods for getting coordinates of tiles

//these coordinates are relative to page number. y value can be considered absolute
//  x value needs to be added to page number * pageWidth to get absolute x value on the scrollView
- (CGFloat)originYForTileAtRow:(NSInteger)row
{
    return row * ([self tileHeight]) + (row + 1) * self.marginHeight;
}

- (CGFloat)originXForTileAtColumn:(NSInteger)column
{
    return column * ([self tileWidthForTileColumnWidth:kTileColumnWidth1]) + (column + 1) * self.marginWidth;
}

- (CGPoint)originForTileAtRow:(NSInteger)row column:(NSInteger)column
{
    return CGPointMake([self originXForTileAtColumn:column], [self originYForTileAtRow:row]);
}

- (CGPoint)absoluteOriginForTileAtPage:(NSInteger)page row:(NSInteger)row column:(NSInteger)column
{
    return CGPointMake([self originXForTileAtColumn:column] + page * self.pageWidth, [self originYForTileAtRow:row]);
}

- (CGRect)frameForTileAtPage:(NSInteger)page row:(NSInteger)row column:(NSInteger)column tileColumnWidth:(KXTileColumnWidth)colWidth
{
    //return CGRectMake([self originXForTileAtColumn:column], [self originYForTileAtRow:row], [self tileWidthForTileColumnWidth:colWidth], [self tileHeight]);
    CGRect frame = CGRectMake(0, 0, [self tileWidthForTileColumnWidth:colWidth], [self tileHeight]);
    frame.origin = [self absoluteOriginForTileAtPage:page row:row column:column];
    return frame;
}

#pragma mark - other convenience methods

//NOTE: page indices start from zero
- (NSInteger)currentPageIndex
{
    return self.scrollView.contentOffset.x / self.pageWidth;
}



@end
