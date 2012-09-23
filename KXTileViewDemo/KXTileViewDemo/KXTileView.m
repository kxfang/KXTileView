//
//  KXTileView.m
//  Test1
//
//  Created by Kevin Fang on 12-9-19.
//  Copyright (c) 2012年 Kevin Fang. All rights reserved.
//


#import "KXTileView.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

@interface KXTileSlot : NSObject
@property (nonatomic, assign) NSInteger page;
@property (nonatomic, assign) NSInteger row;
@property (nonatomic, assign) NSInteger column;
@end

@implementation KXTileSlot
@synthesize page, row, column;
@end

@interface KXTileView ()

@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) NSMutableArray *tiles;
@property (nonatomic, assign) NSInteger rowForNextEmptySlot;
@property (nonatomic, assign) NSInteger columnForNextEmptySlot;
@property (nonatomic, assign) KXTileSlot *nextSlot;


- (void)initializeLayout;

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

@synthesize rowForNextEmptySlot = _rowForNextEmptySlot;
@synthesize columnForNextEmptySlot = _columnForNextEmptySlot;
@synthesize nextSlot = _nextSlot;

@synthesize scrollView = _scrollView;

#pragma mark - init methods

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        self.scrollView.backgroundColor = [UIColor blackColor];
        self.scrollView.contentSize = self.bounds.size;
        [self addSubview:self.scrollView];
        
        //intialize properties with default values
        self.pageWidth = self.frame.size.width - 50;
        self.rowsPerPage = 4;
        self.columnsPerPage = 3;
        self.marginHeight = 20;
        self.marginWidth = 20;
        
        _nextSlot = [[KXTileSlot alloc] init];
        self.nextSlot.page = 0;
        self.nextSlot.row = 0;
        self.nextSlot.column = 0;
        
        //intialize internal store of tiles;
        _tiles = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    self.scrollView = nil;
    self.tiles = nil;
    self.nextSlot = nil;
    [super dealloc];
}

#pragma mark - setter/getter overrides

- (void)setDataSource:(id<KXTileViewDataSource>)dataSource
{
    _dataSource = dataSource;
    [self initializeLayout];
}

#pragma mark - convenience methods for returning sizes of rows and cols

- (CGFloat)tileHeight
{
    return (self.frame.size.height - self.marginHeight * (self.rowsPerPage + 1)) / self.rowsPerPage;
}

- (CGFloat)tileWidthForTileColumnWidth:(KXTileColumnWidth)tileColumnWidth
{
    CGFloat singleTileWidth = (self.pageWidth- self.marginWidth * (self.columnsPerPage + 1)) / self.columnsPerPage;
    switch (tileColumnWidth) {
        case kTileColumnWidth1:
            //width per column minus margin
            return singleTileWidth;
            
        case kTileColumnWidth2:
            //width as above multiplied by 2 and add margin between tiles
            return singleTileWidth * 2 + self.marginWidth;
    }
}

#pragma mark - private methods

- (void)incrementNextSlot {
    if (self.nextSlot.column >= self.columnsPerPage - 1) {
        if (self.nextSlot.row >= self.rowsPerPage - 1) {
            self.nextSlot.page++;
            self.nextSlot.row = 0;
            self.nextSlot.column = 0;
            
        }
        else {
            self.nextSlot.row++;
            self.nextSlot.column = 0;
        }
    }
    else {
        self.nextSlot.column++;
    }
}

- (void)initializeLayout
{
    NSInteger numTiles = [self.dataSource numberOfTilesInTileView:self];
    for (int i = 0; i < numTiles; i++) {
        KXTileColumnWidth colWidth = kTileColumnWidth1;
        
        //Figure out how wide the tile will be
        if ([self.dataSource respondsToSelector:@selector(tileView:canShowTileWithWidthLessEqualTo:atIndex:)]) {
            if ([self.dataSource tileView:self canShowTileWithWidthLessEqualTo:kTileColumnWidth2 atIndex:i]
                && self.nextSlot.column + kTileColumnWidth2 <= self.columnsPerPage) {
                colWidth = kTileColumnWidth2;
            }
        }
        
        if (self.scrollView.contentSize.width < (self.nextSlot.page + 1) * self.pageWidth) {
            CGFloat newWidth = self.scrollView.contentSize.width + self.pageWidth;
            self.scrollView.contentSize = CGSizeMake(newWidth, self.scrollView.contentSize.height);
        }

        
        CGRect newFrame = [self frameForTileAtPage:self.nextSlot.page row:self.nextSlot.row column:self.nextSlot.column tileColumnWidth:colWidth];
        UIView *newTile = [[UIView alloc] initWithFrame:newFrame];
        newTile.backgroundColor = [UIColor whiteColor];
        newTile.layer.borderWidth = 4.0;
        newTile.layer.borderColor = [UIColor purpleColor].CGColor;

        [self.scrollView addSubview:newTile];
        [self.tiles addObject:newTile];
        [newTile release];
        
        //Update nextSlot state
        [self incrementNextSlot];
        if (colWidth == kTileColumnWidth2) {
            [self incrementNextSlot];
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
