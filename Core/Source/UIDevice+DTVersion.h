//
//  UIDevice+DTVersion.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 5/30/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef struct
{
	NSInteger major;
	NSInteger minor;
	NSInteger point;
} DTVersion;

/** Convenience method to return the current OS version as a struct of three NSIntegers. Using UIDevice's `currentDevice` method and the current device's `systemVersion` returns a string delimited by a period which can then be split into an array. This method returns a struct storing each value instead of a string or array. Used in DTCoreTextLayoutFrame to workaround the way iOS 4.2 handles images. 
 */
@interface UIDevice (DTVersion)

/**  
 @return Returns a DTVersion struct with three fields each of type NSInteger storing the major, minor, and point numbers identifying this OS version. */
- (DTVersion) osVersion;

@end
