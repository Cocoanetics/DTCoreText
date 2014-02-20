//
//  NSCoder+DTCompatibility.m
//  DTCoreText
//
//  Created by Ryan Johnson on 14/02/19.
//  Copyright (c) 2014 Drobnik.com. All rights reserved.
//

#import "NSCoder+DTCompatibility.h"

#if !TARGET_OS_IPHONE
NSString* NSStringFromNSEdgeInsets(NSEdgeInsets insets);
NSEdgeInsets NSEdgeInsetsFromString(NSString *string);
#endif

@implementation NSCoder (DTCompatibility)

#if !TARGET_OS_IPHONE
- (void)encodeCGSize:(CGSize)size forKey:(NSString *)key {
    [self encodeObject:NSStringFromCGSize(size) forKey:key];
}

- (CGSize)decodeCGSizeForKey:(NSString *)key {
	return NSSizeToCGSize(NSSizeFromString([self decodeObjectForKey:key]));
}
#endif

- (void)encodeDTEdgeInsets:(DTEdgeInsets)insets forKey:(NSString *)key {
#if TARGET_OS_IPHONE
	[self encodeUIEdgeInsets:insets forKey:key];
#else
	[self encodeObject:NSStringFromNSEdgeInsets(insets) forKey:key];
#endif
}

- (DTEdgeInsets)decodeDTEdgeInsetsForKey:(NSString *)key {
#if TARGET_OS_IPHONE
	return [self decodeUIEdgeInsetsForKey:key];
#else
	return NSEdgeInsetsFromString([self decodeObjectForKey:key]);
#endif
}


@end

#if !TARGET_OS_IPHONE
NSString* NSStringFromNSEdgeInsets(NSEdgeInsets insets) {
	return [NSString stringWithFormat:@"{%f,%f,%f,%f}", insets.top, insets.left, insets.bottom, insets.right];
}

NSEdgeInsets NSEdgeInsetsFromString(NSString *string) {
	// Cut off curly brackets
	string = [string substringWithRange:NSMakeRange(1, string.length - 2)];

	NSArray *floatStrings = [string componentsSeparatedByString:@","];
	if (floatStrings.count != 4) {
		return NSEdgeInsetsMake(0, 0, 0, 0);
	}
	CGFloat top = [floatStrings[0] floatValue];
	CGFloat left = [floatStrings[1] floatValue];
	CGFloat bottom = [floatStrings[2] floatValue];
	CGFloat right = [floatStrings[3] floatValue];

	return NSEdgeInsetsMake(top, left, bottom, right);
}

#endif
