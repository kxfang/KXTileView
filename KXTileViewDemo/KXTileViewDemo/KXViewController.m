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

@end

@implementation KXViewController

@synthesize lastSwipedTileIndex = _lastSwipedTileIndex;

- (void)loadView
{
    KXTileView *tileView = [[KXTileView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
    tileView.delegate = self;
    tileView.dataSource = self;
    [tileView resetLayout];
    self.view = tileView;
    [tileView release];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (NSInteger)numberOfTilesInTileView:(KXTileView *)tileView
{
    return 90;
}

- (UIView *)tileView:(KXTileView *)tileView contentViewForTileAtIndex:(NSInteger)index withFrame:(CGRect)frame
{
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.text = [NSString stringWithFormat:@"%d", index];
    label.backgroundColor = [UIColor whiteColor];
    label.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    return label;
}

- (void)tileView:(KXTileView *)tileView didSwipeTileAtIndex:(NSInteger)index {
    self.lastSwipedTileIndex = index;
}

- (UIView *)tileView:(KXTileView *)tileView contextViewForSwipedTileAtIndex:(NSInteger)index {
    UIView *contextView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 400, 80)];
    UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    deleteButton.frame = CGRectMake(160, 0, 80, 80);
    [contextView addSubview:deleteButton];
    contextView.backgroundColor = [UIColor darkGrayColor];
    [deleteButton addTarget:self action:@selector(didTapDeleteButtonInContextView) forControlEvents:UIControlEventTouchUpInside];
    [deleteButton setTitle:@"Delete" forState:UIControlStateNormal];
    deleteButton.titleLabel.font = [UIFont systemFontOfSize:15.0];
    deleteButton.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [deleteButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [contextView autorelease];
    return contextView;
}

- (BOOL)tileView:(KXTileView *)tileView canShowTileWithWidthLessEqualTo:(KXTileColumnWidth) width atIndex:(NSInteger)index
{
    //    if (index % 6 > 2) return true; return false;
    // return YES;
    return index % 3;
}

- (void)tileView:(KXTileView *)tileView didSelectTileAtIndex:(NSInteger)index {
    NSLog(@"Tapped %d!", index);
    [tileView zoomIntoTileAtIndex:index];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didTapDone)];
}

- (void)didTapDone
{
    [(KXTileView *)self.view zoomOutOfTile];
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)didTapDeleteButtonInContextView {
    NSLog(@"Tapped button 1 at index: %d", self.lastSwipedTileIndex);
}


@end
