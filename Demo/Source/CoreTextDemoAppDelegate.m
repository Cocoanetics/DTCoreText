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
	// Setup font and paragraph style
	DTCoreTextFontDescriptor* titleFontDescriptor = [[DTCoreTextFontDescriptor alloc] initWithFontAttributes:nil];
	titleFontDescriptor.pointSize = 20.0f;
	titleFontDescriptor.fontFamily = @"PT Serif";
	titleFontDescriptor.boldTrait = YES;
	CTFontRef titleFont = [titleFontDescriptor newMatchingFont];
	NSString* titleString = [[NSString alloc] initWithFormat:@"%@\n", @"Google Wallet’s Founding Engineer, Product Lead Already at Work on Next Startup, Tappmo"]; // A long string that triggers line switching.
	DTCoreTextParagraphStyle* titleParagraphStyle = [DTCoreTextParagraphStyle defaultParagraphStyle];
	titleParagraphStyle.paragraphSpacing = 14;
	titleParagraphStyle.maximumLineHeight = 10;  //Whatever you chose, nothing happens.
	titleParagraphStyle.lineHeightMultiple = 0.5; //Whatever you chose, nothing happens.
	NSAttributedString* titleNSAString = [[NSAttributedString alloc] initWithString:titleString attributes:[NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)(titleFont), (id)kCTFontAttributeName, CFBridgingRelease([titleParagraphStyle createCTParagraphStyle]), (id)kCTParagraphStyleAttributeName, nil]];
	
	// Calculate the height
	DTCoreTextLayouter* titleLayouter =  [[DTCoreTextLayouter alloc] initWithAttributedString:titleNSAString];
	DTCoreTextLayoutFrame* dtFrame = [titleLayouter layoutFrameWithRect:CGRectMake(0, 0, 300, CGFLOAT_OPEN_HEIGHT) range:NSMakeRange(0, titleNSAString.length)];
	dtFrame.lines;  // To manually trigger line building(Maybe a better way to this?)
	float resultHeight = dtFrame.frame.size.height; // Never affected by lineHeightMultiple/maximumLineHeight.
	
	
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
