//
//  DemoSceneDelegate.m
//  DTCoreText
//

#import "DemoSceneDelegate.h"
#import "DemoSnippetsViewController.h"

@import DTCoreTextSwift;

@implementation DemoSceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions
{
	if (![scene isKindOfClass:[UIWindowScene class]]) {
		return;
	}

	UIWindowScene *windowScene = (UIWindowScene *)scene;

	// register a custom class for a tag
	[DTTextAttachment registerClass:[DTObjectTextAttachment class] forTagName:@"oliver"];

	// preload font matching table
	[DTCoreTextFontDescriptor asyncPreloadFontLookupTable];

	self.window = [[UIWindow alloc] initWithWindowScene:windowScene];

	DemoSnippetsViewController *snippetsViewController = [[DemoSnippetsViewController alloc] init];
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:snippetsViewController];

	self.window.rootViewController = navigationController;
	[self.window makeKeyAndVisible];
}

@end
