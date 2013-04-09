//
//  KXAppDelegate.m
//  KXTileViewDemo
//
//  Created by Kevin Fang on 12-9-22.
//  Copyright (c) 2012年 Kevin Fang. All rights reserved.
//

#import "KXAppDelegate.h"

#import "KXViewController.h"

@implementation KXAppDelegate

- (void)dealloc
{
    [_window release];
    [_viewController release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:[[[KXViewController alloc] init] autorelease]];
    self.viewController = navController;
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
