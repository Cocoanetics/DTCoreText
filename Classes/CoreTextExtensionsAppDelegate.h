//
//  CoreTextExtensionsAppDelegate.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CoreTextExtensionsViewController;

@interface CoreTextExtensionsAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    CoreTextExtensionsViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet CoreTextExtensionsViewController *viewController;

@end

