//
//  DemoAppDelegate.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "CoreTextDemoAppDelegate.h"
#import "DemoSnippetsViewController.h"

#import "DTCoreText.h"
#import "UIView+DTDebug.h"

@implementation CoreTextDemoAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions 
{
	// register a custom class for a tag
	[DTTextAttachment registerClass:[DTObjectTextAttachment class] forTagName:@"oliver"];
	
	// preload font matching table
	[DTCoreTextFontDescriptor asyncPreloadFontLookupTable];
	
	// for debugging, we make sure that UIView methods are only called on main thread
	[UIView toggleViewMainThreadChecking];
	
	// Create window
	_window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	// Create the view controller
	DemoSnippetsViewController *snippetsViewController = [[DemoSnippetsViewController alloc] init];
	_navigationController = [[UINavigationController alloc] initWithRootViewController:snippetsViewController];
	
	// Display the window
	_window.rootViewController = _navigationController;
	[_window makeKeyAndVisible];
	
	return YES;
}



@end
