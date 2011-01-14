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
	CoreTextExtensionsViewController *viewController = [[CoreTextExtensionsViewController alloc] init];
	window.rootViewController = viewController;
	[viewController release];
	
	// Display the window
    [window makeKeyAndVisible];

    return YES;
}


- (void)dealloc {
    [window release];
    [super dealloc];
}

@end
