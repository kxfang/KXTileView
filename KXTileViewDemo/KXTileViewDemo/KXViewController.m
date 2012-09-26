//
//  KXViewController.m
//  Test1
//
//  Created by Kevin Fang on 12-9-19.
//  Copyright (c) 2012年 Kevin Fang. All rights reserved.
//

#import "KXViewController.h"

@interface KXViewController ()

@end

@implementation KXViewController

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
    label.backgroundColor = [UIColor purpleColor];
    label.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    return label;
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


@end
