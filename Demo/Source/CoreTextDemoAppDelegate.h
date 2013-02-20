//
//  DemoAppDelegate.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

@class DemoTextViewController;

@interface CoreTextDemoAppDelegate : NSObject <UIApplicationDelegate> 
{
    UIWindow *_window;
	UINavigationController *_navigationController;
}

@property (nonatomic, strong) UIWindow *window;

@end
