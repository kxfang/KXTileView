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

@end

@implementation KXViewController

@synthesize lastSwipedTileIndex = _lastSwipedTileIndex;
@synthesize numberOfTiles = _numberOfTiles;

- (void)loadView
{
    self.numberOfTiles = 15;
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
    return self.numberOfTiles;
}

- (UIView *)tileView:(KXTileView *)tileView contentViewForTileAtIndex:(NSInteger)index withFrame:(CGRect)frame
{
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.text = [NSString stringWithFormat:@"View %d", index];
    label.font = [UIFont systemFontOfSize:25.0];
    label.backgroundColor = [UIColor orangeColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    return label;
//    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
//    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width * 3/7, frame.size.height)];
//    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width *3/7 + 20, 0, frame.size.width*4/7-20, frame.size.height)];
//    imageView.image = [UIImage imageNamed:@"test.jpg"];
//    textLabel.text = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus a eros a risus porta consequat mattis sit amet dolor. Etiam sodales commodo velit ut tristique. Sed at semper turpis. Morbi sit amet dui dolor, vel vulputate arcu. Morbi rhoncus, felis a molestie auctor, nulla dui pellentesque orci, quis volutpat quam lacus sit amet urna. Ut a varius elit. Mauris varius libero vitae est pulvinar commodo. Nunc enim arcu, consequat ac congue at, euismod ut nibh. Cras lobortis consectetur ante, quis elementum metus rutrum sed. Praesent magna purus, interdum vel porta sed, sodales et est. Proin tincidunt eleifend nisl, ut scelerisque lacus varius eget. Morbi quis turpis non risus volutpat bibendum eget pretium augue. Curabitur ultricies fermentum metus, sed ullamcorper augue sollicitudin ac. Ut in ultricies dolor. Maecenas sit amet erat quis nulla fermentum posuere eu sit amet ipsum.";
//    textLabel.numberOfLines = 0;
//    [contentView addSubview:imageView];
//    [contentView addSubview:textLabel];
//    return contentView;
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

- (BOOL)tileView:(KXTileView *)tileView canShowTileWithWidth:(KXTileColumnWidth) width atIndex:(NSInteger)index
{
    //    if (index % 6 > 2) return true; return false;
    // return YES;
    if (index == 0) return NO;
    else return YES;
}

- (void)tileView:(KXTileView *)tileView didSelectTileAtIndex:(NSInteger)index {
    NSLog(@"Tapped %d!", index);
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
    NSLog(@"Tapped button 1 at index: %d", self.lastSwipedTileIndex);
    self.numberOfTiles--;
    [((KXTileView*)self.view) removeTileAtIndex:self.lastSwipedTileIndex animated:YES];
}


@end
