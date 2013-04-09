//
//  KXViewController.m
//  Test1
//
//  Created by Kevin Fang on 12-9-19.
//  Copyright (c) 2012年 Kevin Fang. All rights reserved.
//

#import "KXViewController.h"

@interface KXViewController ()

@property (nonatomic, assign) NSInteger lastSwipedTileIndex;
@property (nonatomic, assign) NSInteger numberOfTiles;
@property (nonatomic, retain) NSMutableArray *arr;

@end

@implementation KXViewController

@synthesize lastSwipedTileIndex = _lastSwipedTileIndex;
@synthesize numberOfTiles = _numberOfTiles;
@synthesize arr = _arr;

- (void)loadView
{
    self.numberOfTiles = 30;
    self.arr = [NSMutableArray arrayWithCapacity:self.numberOfTiles];
    for (NSInteger i = 0; i < self.numberOfTiles; i++) {
        [self.arr addObject:[NSNumber numberWithInteger:i]];
    }
    KXTileView *tileView = [[KXTileView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
    tileView.delegate = self;
    tileView.dataSource = self;
    tileView.backgroundColor = [UIColor whiteColor];
    tileView.useShadow = NO;
    [tileView resetLayout];
    self.view = tileView;
    [tileView release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (NSInteger)numberOfTilesInTileView:(KXTileView *)tileView
{
    return self.numberOfTiles;
}

- (UIView *)tileView:(KXTileView *)tileView coverViewForTileAtIndex:(NSInteger)index withFrame:(CGRect)frame
{
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.text = @"Cover View";
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:25.0];
    label.backgroundColor = [UIColor colorWithRed:0 green:0.533 blue:0.8 alpha:1.0];
    label.textAlignment = NSTextAlignmentCenter;
    label.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    return [label autorelease];
}

- (void)tileView:(KXTileView *)tileView didSwipeTileAtIndex:(NSInteger)index {
    self.lastSwipedTileIndex = index;
}

- (UIView *)tileView:(KXTileView *)tileView contextViewForSwipedTileAtIndex:(NSInteger)index {
    UIView *contextView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 400, 38)];
    
    UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    deleteButton.frame = CGRectMake(366, 4, 30, 30);
    [contextView addSubview:deleteButton];
    contextView.backgroundColor = [UIColor colorWithRed:0 green:0.333 blue:0.6 alpha:1.0];
    [deleteButton addTarget:self action:@selector(didTapDeleteButtonInContextView) forControlEvents:UIControlEventTouchUpInside];
    [deleteButton setBackgroundImage:[UIImage imageNamed:@"delete.png"] forState:UIControlStateNormal];
    deleteButton.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
    
    [deleteButton release];
    return [contextView autorelease];
}

- (UIView *)tileView:(KXTileView *)tileView contentViewForTileAtIndex:(NSInteger)index withFrame:(CGRect)frame {
    UIScrollView *container = [[UIScrollView alloc] initWithFrame:frame];
    container.backgroundColor = [UIColor whiteColor];
    UIImageView *view = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"content-view.png"]];
    view.center = CGPointMake(container.bounds.size.width/2, view.bounds.size.height/2);
    [container addSubview:view];
    [view release];
    container.contentSize = CGSizeMake(container.bounds.size.width, view.bounds.size.height);
    return [container autorelease];
}

- (BOOL)tileView:(KXTileView *)tileView canShowTileWithWidth:(KXTileColumnWidth)width atIndex:(NSInteger)index
{
    // some arbitrary logic to determine the size of the tile; you can base this off your model
    int i = [[self.arr objectAtIndex:index] integerValue];
    if (i % 4 <= 1) return NO;
    else return YES;
}

- (void)tileView:(KXTileView *)tileView didSelectTileAtIndex:(NSInteger)index {
    // react to tile selection
    [tileView zoomIntoTileAtIndex:index];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didTapDone)];
}

- (void)tileView:(KXTileView *)tileView didFinishZoomOutTileAtIndex:(NSInteger)index {
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)didTapDone
{
    [(KXTileView *)self.view zoomOutOfTile];
}

- (void)didTapDeleteButtonInContextView {
    self.numberOfTiles--;
    [((KXTileView*)self.view) removeTileAtIndex:self.lastSwipedTileIndex animated:YES];
    [self.arr removeObjectAtIndex:self.lastSwipedTileIndex];
}


@end
