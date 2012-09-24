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

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    KXTileView *tileView = [[KXTileView alloc] initWithFrame:self.view.bounds];
    tileView.delegate = self;
    tileView.dataSource = self;
    [tileView resetLayout];
    [self.view addSubview:tileView];
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

- (UIView *)tileView:(KXTileView *)tileView contentViewForTileAtIndex:(NSInteger)index
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 50, 50)];
    label.text = [NSString stringWithFormat:@"%d", index];
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
}


@end
