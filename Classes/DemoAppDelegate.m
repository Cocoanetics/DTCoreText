//
//  DemoAppDelegate.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DemoAppDelegate.h"
#import "DemoSnippetsViewController.h"

@implementation DemoAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
	/*
	NSString *test = @"< font size=\"6\">Visit this link: <a href=\"http://bla\">bla</a></font>";
	BOOL open;
	BOOL close;
	NSString *tag = nil;
	NSDictionary *attr = nil;
	
	NSScanner *scanner = [NSScanner scannerWithString:test];
	
	BOOL s = [scanner scanHTMLTag:&tag attributes:&attr isOpen:&open isClosed:&close];
	
	NSLog(@"%@", attr);
	 */
	
	// Create window
	_window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	// Create the view controller
	DemoSnippetsViewController *snippetsViewController = [[DemoSnippetsViewController alloc] init];
	_navigationController = [[UINavigationController alloc] initWithRootViewController:snippetsViewController];
	[snippetsViewController release];	
	
	// Display the window
	[_window addSubview:_navigationController.view];
    [_window makeKeyAndVisible];

    return YES;
}


- (void)dealloc 
{
    [_window release];
	[_navigationController release];
    [super dealloc];
}

@end
