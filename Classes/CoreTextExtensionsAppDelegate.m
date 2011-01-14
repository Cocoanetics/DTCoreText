//
//  CoreTextExtensionsAppDelegate.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "CoreTextExtensionsAppDelegate.h"
#import "CoreTextExtensionsViewController.h"
#import "NSAttributedString+HTML.h"

@implementation CoreTextExtensionsAppDelegate

@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
	// Create window
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	// Create view controller and set it as the window's root view controller
	viewController = [[CoreTextExtensionsViewController alloc] init];
	
	// Display the window
	[window addSubview:viewController.view];
    [window makeKeyAndVisible];

    return YES;
}


- (void)dealloc 
{
    [window release];
	[viewController release];
    [super dealloc];
}

@end
