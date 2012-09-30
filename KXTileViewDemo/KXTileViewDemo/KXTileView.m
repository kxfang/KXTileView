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

#define KXTileContextViewTag 54325235

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

- (id)initWithMaxRow:(NSInteger)maxRow maxColumn:(NSInteger)maxColumn page:(NSInteger)p row:(NSInteger)r column:(NSInteger)c {
    self = [super init];
    if (self) {
        maxRows = maxRow;
        maxColumns = maxColumn;
        page = p;
        row = r;
        column = c;
    }
    return self;
}

- (id)initWithMaxRow:(NSInteger)maxRow maxColumn:(NSInteger)maxColumn
{
    return [self initWithMaxRow:maxRow maxColumn:maxColumn page:0 row:0 column:0];
}

- (id)initWithKXTileSlot:(KXTileSlot *)slot {
    return [self initWithMaxRow:slot.maxRows maxColumn:slot.maxColumns page:slot.page row:slot.row column:slot.column];
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

- (void)decrement
{
    if (self.column == 0 && self.row == 0) {
        if (self.page > 0) {
            self.page--;
            self.row = self.maxRows - 1;
            self.column = self.maxColumns - 1;
        }
    }
    else if (self.column == 0) {
        self.column = self.maxColumns - 1;
        self.row--;
    }
    else {
        self.column --;
    }
}
@end

typedef enum {
    KXTileViewStateDefault,
    KXTileViewStateSwiped,
    KXTileViewStateZoomed
} KXTileViewState;

@interface KXTileView ()

@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) UIView *scrollViewOverlay;
@property (nonatomic, retain) NSMutableArray *tiles;

//Internal state stuff
@property (nonatomic, assign) KXTileViewState state;
@property (nonatomic, assign) NSInteger nextIndexToLoad;
@property (nonatomic, assign) KXTileSlot *nextSlotToLoad;
@property (nonatomic, assign) KXTileSlot *nextEmptySlot;
@property (nonatomic, retain) NSMutableArray *tileSlots; //stores slots corresponding to each tile

//Properties relating to tile-zooming
@property (nonatomic, assign) CGRect zoomedInTileCachedFrame;
@property (nonatomic, assign) KXTile *zoomedInTile;
@property (nonatomic, assign) NSInteger zoomedInTileIndex;

//Properties relating to swiping tiles
@property (nonatomic, assign) CGRect swipedTileCachedFrame;
@property (nonatomic, assign) KXTile *swipedTile;
@property (nonatomic, assign) NSInteger swipedTileIndex;
@property (nonatomic, assign) UIView *swipeContextView;
@property (nonatomic, assign) BOOL allowStartSwipe;

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

@synthesize swipeActionEnabled = _swipeActionEnabled;

@synthesize state = _state;
@synthesize nextIndexToLoad = _nextIndexToLoad;
@synthesize nextSlotToLoad = _nextSlotToLoad;
@synthesize nextEmptySlot = _nextEmptySlot;
@synthesize tileSlots = _tileSlots;

@synthesize zoomedInTileCachedFrame = _zoomedTileCachedFrame;
@synthesize zoomedInTile = _zoomedInTile;
@synthesize zoomedInTileIndex = _zoomedInIndex;

@synthesize swipedTileCachedFrame = _swipedTileCachedFrame;
@synthesize swipedTile = _swipedTile;
@synthesize swipedTileIndex = _swipedTileIndex;
@synthesize swipeContextView = _swipeContextView;
@synthesize allowStartSwipe = _allowStartSwipe;

@synthesize scrollView = _scrollView;
@synthesize scrollViewOverlay = _scrollViewOverlay;

#pragma mark - init methods

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        self.scrollView.backgroundColor = [UIColor lightGrayColor];
        self.scrollView.delegate = self;
        [self addSubview:self.scrollView];
        
        _scrollViewOverlay = [[UIView alloc] initWithFrame:self.scrollView.bounds];
        self.scrollViewOverlay.backgroundColor = [UIColor blackColor];
        self.scrollViewOverlay.alpha = 0.0;
        [self.scrollView addSubview:self.scrollViewOverlay];
        
        //intialize properties with default values
        self.pageWidth = self.frame.size.width - 50;
        self.rowsPerPage = 4;
        self.columnsPerPage = 3;
        self.marginHeight = 15;
        self.marginWidth = 15;
        
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.autoresizesSubviews = YES;
        
        self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.scrollView.autoresizesSubviews = YES;
        
        self.swipeActionEnabled = YES;
        self.allowStartSwipe = YES;
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

- (void)layoutSubviews
{
    [self resetLayout];
}

- (void)resetLayout
{
    self.nextEmptySlot = nil;
    self.nextSlotToLoad = nil;
    
    self.swipedTile = nil;
    
    self.scrollView.contentSize = self.bounds.size;
    
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
    
    self.tileSlots = nil;
    _tileSlots = [[NSMutableArray alloc] init];
    
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

- (void)setState:(KXTileViewState)state
{
    if (_state != state) {
        _state = state;
        switch (state) {
            case KXTileViewStateDefault:
                self.scrollView.scrollEnabled = YES;
                self.allowStartSwipe = YES;
                break;
                
            case KXTileViewStateSwiped:
                self.scrollView.scrollEnabled = YES;
                self.allowStartSwipe = YES;
                break;
                
            case KXTileViewStateZoomed:
                [self cancelSwipe];
                self.scrollView.scrollEnabled = NO;
                self.allowStartSwipe = NO;
        }
    }
}

#pragma mark - public methods

- (void)zoomIntoTileAtIndex:(NSInteger)index {
    if (index >= 0 && [self.tiles count] > index) {
        KXTile *tile = [self.tiles objectAtIndex:index];
        tile.shouldBounceOnTouch = NO;
        [self.scrollView bringSubviewToFront:tile];
        self.zoomedInTileCachedFrame = tile.frame;
        self.zoomedInTile = tile;
        self.state = KXTileViewStateZoomed;
        
        [self.scrollView bringSubviewToFront:self.scrollViewOverlay];
        [self.scrollView bringSubviewToFront:tile];
        
        [UIView animateWithDuration:0.4 animations:^{
            tile.frame = CGRectMake(self.scrollView.contentOffset.x, 0, self.bounds.size.width, self.bounds.size.height);
            self.scrollViewOverlay.alpha = 0.7;
        }completion:^(BOOL finished) {
            if ([self.delegate respondsToSelector:@selector(tileView:didFinishZoomInTileAtIndex:)]) {
                [self.delegate tileView:self didFinishZoomInTileAtIndex:index];
            }
        }];
    }
}

- (void)zoomOutOfTile {
    if (self.zoomedInTile != nil) {
        self.zoomedInTile.shouldBounceOnTouch = YES;
        self.state = KXTileViewStateDefault;
        [UIView animateWithDuration:0.4 animations:^{
            self.zoomedInTile.frame = self.zoomedInTileCachedFrame;
            self.zoomedInTile = nil;
            self.scrollViewOverlay.alpha = 0.0;
        }completion:^(BOOL finished){
            if ([self.delegate respondsToSelector:@selector(tileView:didFinishZoomOutTileAtIndex:)]) {
                [self.delegate tileView:self didFinishZoomOutTileAtIndex:self.zoomedInTileIndex];
                self.zoomedInTileIndex = 0;
            }
        }];
    }
}

- (void)removeTileAtIndex:(NSInteger)index animated:(BOOL)animated {
    if (animated) {
        [UIView animateWithDuration:0.4 animations:^{
            [self removeTileAtIndex:index];
        }];
    }
    else {
        [self removeTileAtIndex:index];
    }
}

- (void)removeTileAtIndex:(NSInteger)index {
    KXTile *removedTile = [self.tiles objectAtIndex:index];
    [self.tiles removeObjectAtIndex:index];
    
    if (removedTile == self.swipedTile) {
        self.swipedTile = nil;
    }
    
    [removedTile removeFromSuperview];
    
    KXTileSlot *lastSlot = [self.tileSlots lastObject];
    if (lastSlot.row == 0 && lastSlot.column == 0) {
        self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width - self.pageWidth, self.scrollView.contentSize.height);
    }
    
    if (index < self.nextIndexToLoad) {
        self.nextIndexToLoad--;
        [self.nextSlotToLoad decrement];
        if (removedTile.bounds.size.width > [self frameForTileAtPage:0 row:0 column:0 tileColumnWidth:kTileColumnWidth1].size.width + 1) {
            [self.nextSlotToLoad decrement];
        }
    }
    
    KXTileSlot *currentEmptySlot = [[self.tileSlots objectAtIndex:index] retain];
    
    int currentIndex = 0;
    for (KXTile * tile in self.tiles) {
        if (currentIndex >= index) {
            KXTileSlot *newSlot = [[KXTileSlot alloc] initWithKXTileSlot:currentEmptySlot];
            [self.tileSlots replaceObjectAtIndex:currentIndex withObject:newSlot];
            [newSlot release];
            KXTileColumnWidth tileWidth = [self tileWidthForSlot:currentEmptySlot atIndex:currentIndex];
            CGRect oldFrame = tile.frame;
            
            tile.frame = [self frameForTileAtPage:currentEmptySlot.page row:currentEmptySlot.row column:currentEmptySlot.column tileColumnWidth:tileWidth];
            
            //if tile size changed, re-query the dataSource for the tile
            if (oldFrame.size.width != tile.bounds.size.width) {
                tile.contentView = [self.dataSource tileView:self contentViewForTileAtIndex:currentIndex withFrame:tile.bounds];
                [tile resetShadow];
            }
            
            [currentEmptySlot increment];
            if (tileWidth == kTileColumnWidth2) {
                [currentEmptySlot increment];
            }
        }
        currentIndex++;
    }
    [self.tileSlots removeLastObject];

    [currentEmptySlot release];
}

#pragma mark - convenience methods for returning sizes of rows and cols

- (CGFloat)tileHeight
{
    return (self.frame.size.height - self.marginHeight * (self.rowsPerPage + 1)) / self.rowsPerPage;
}

- (CGFloat)tileWidthForTileColumnWidth:(KXTileColumnWidth)tileColumnWidth
{
    int pagingOffset = 0;
    if (self.scrollView.pagingEnabled) {
        pagingOffset = 1;
    }
    CGFloat singleTileWidth = (self.pageWidth - self.marginWidth * (self.columnsPerPage + pagingOffset)) / self.columnsPerPage;
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

- (KXTileColumnWidth)tileWidthForSlot:(KXTileSlot *)slot atIndex:(NSInteger)index{
    KXTileColumnWidth colWidth = kTileColumnWidth1;
    
    if ([self.dataSource respondsToSelector:@selector(tileView:canShowTileWithWidth:atIndex:)]) {
        if ([self.dataSource tileView:self canShowTileWithWidth:kTileColumnWidth2 atIndex:index]
            && slot.column + kTileColumnWidth2 <= self.columnsPerPage) {
            colWidth = kTileColumnWidth2;
        }
    }
    return colWidth;
}

- (void)initializeLayout
{
    NSInteger numTiles = [self.dataSource numberOfTilesInTileView:self];
    for (int i = 0; i < numTiles; i++) {
        KXTileColumnWidth colWidth = [self tileWidthForSlot:self.nextEmptySlot atIndex:i];
        
        if (self.scrollView.contentSize.width < (self.nextEmptySlot.page + 1) * self.pageWidth) {
            CGFloat newWidth = self.scrollView.contentSize.width + self.pageWidth;
            self.scrollView.contentSize = CGSizeMake(newWidth, self.scrollView.contentSize.height);
        }

        
        CGRect newFrame = [self frameForTileAtPage:self.nextEmptySlot.page row:self.nextEmptySlot.row column:self.nextEmptySlot.column tileColumnWidth:colWidth];
        KXTile *newTile = [[KXTile alloc] initWithFrame:newFrame];
        newTile.autoresizesSubviews = YES;
        newTile.backgroundColor = [UIColor whiteColor];
        
        [newTile addTarget:self action:@selector(handleTileTap:)];
        
        UISwipeGestureRecognizer *swipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleTileSwipe:)];
        [newTile addGestureRecognizer:swipeRecognizer];
        swipeRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
        [swipeRecognizer release];

        [self.scrollView addSubview:newTile];
        [self.tiles addObject:newTile];
        [newTile release];
        
        KXTileSlot *slot = [[KXTileSlot alloc] initWithKXTileSlot:self.nextEmptySlot];
        [self.tileSlots addObject:slot];
        [slot release];
                
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
        KXTile * tile = [self.tiles objectAtIndex:self.nextIndexToLoad];
        tile.contentView = [self.dataSource tileView:self contentViewForTileAtIndex:self.nextIndexToLoad withFrame:tile.bounds];
        
        [self.nextSlotToLoad increment];
        self.nextIndexToLoad++;
    }
}

- (void)cancelSwipe
{
    if (self.swipedTile != nil) {
        UIView *contextView = [self.swipedTile viewWithTag:KXTileContextViewTag];
        [UIView animateWithDuration:0.2 animations:^{
            self.swipedTile.contentView.frame = self.swipedTileCachedFrame;
            self.swipedTile = nil;
            self.state = KXTileViewStateDefault;
        } completion:^(BOOL finished) {
            [contextView removeFromSuperview];
        }];
    } 
}

- (void)handleTileSwipe:(UISwipeGestureRecognizer *)swipeRecognizer
{
    if (self.swipeActionEnabled && swipeRecognizer.direction == UISwipeGestureRecognizerDirectionDown && self.allowStartSwipe) {
        
        [self cancelSwipe];
        KXTile *swipedTile = (KXTile *)swipeRecognizer.view;
        UIView *contextView = nil;
        self.swipedTileIndex = [self.tiles indexOfObject:swipedTile];
        self.swipedTile = swipedTile;
        self.swipedTileCachedFrame = swipedTile.contentView.frame;
        
        CGFloat heightRatio = 0.15;
        if ([self.dataSource respondsToSelector:@selector(tileView:heightRatioForContextViewAtIndex:)]) {
            heightRatio = [self.dataSource tileView:self heightRatioForContextViewAtIndex:self.swipedTileIndex];
        }
        CGFloat contextViewHeight = swipedTile.bounds.size.height * heightRatio;
        
        if ([self.dataSource respondsToSelector:@selector(tileView:contextViewForSwipedTileAtIndex:)]) {
            contextView = [[self.dataSource tileView:self contextViewForSwipedTileAtIndex:self.swipedTileIndex] retain];
            contextView.frame = CGRectMake(0, 0, swipedTile.bounds.size.width, contextViewHeight);
        }
        else {
            contextView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, swipedTile.bounds.size.width, contextViewHeight)];
            contextView.backgroundColor = [UIColor yellowColor];
        }
        contextView.tag = KXTileContextViewTag;
        [swipedTile.clippingView addSubview:contextView];
        [swipedTile.clippingView sendSubviewToBack:contextView];
        
        [contextView release];
        
        [UIView animateWithDuration:0.2 animations:^{
            swipedTile.contentView.center = CGPointMake(swipedTile.contentView.center.x, swipedTile.contentView.center.y + contextView.bounds.size.height);
        }];
        
        if ([self.delegate respondsToSelector:@selector(tileView:didSwipeTileAtIndex:)]) {
            [self.delegate tileView:self didSwipeTileAtIndex:self.swipedTileIndex];
        }
        
        self.state = KXTileViewStateSwiped;
    }
    
}

- (void)handleTileTap:(KXTile *)tile
{
    [self cancelSwipe];
    if (self.state != KXTileViewStateZoomed) {
        if ([self.delegate respondsToSelector:@selector(tileView:didSelectTileAtIndex:)]) {
            [self.delegate tileView:self didSelectTileAtIndex:[self.tiles indexOfObject:tile]];
        }
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
