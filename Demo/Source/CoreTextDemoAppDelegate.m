//
//  DemoAppDelegate.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "CoreTextDemoAppDelegate.h"
#import "DemoSnippetsViewController.h"

@implementation CoreTextDemoAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions 
{   
	// Create window
	_window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	// Create the view controller
	DemoSnippetsViewController *snippetsViewController = [[DemoSnippetsViewController alloc] init];
	_navigationController = [[UINavigationController alloc] initWithRootViewController:snippetsViewController];
	
	// Display the window
	[_window addSubview:_navigationController.view];
	[_window makeKeyAndVisible];
	
	return YES;
}



@end
