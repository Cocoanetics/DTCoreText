//
//  UIDevice+DTVersion.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 5/30/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "UIDevice+DTVersion.h"

@implementation UIDevice (DTVersion)

- (DTVersion) osVersion
{
	static DTVersion retVersion;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSString* versionString = [self systemVersion];
		NSArray *parts = [versionString componentsSeparatedByString:@"."];
		
		NSUInteger partCount = [parts count];
		
		retVersion.major = (partCount>0)?[[parts objectAtIndex:0] intValue]:0;
		retVersion.minor = (partCount>1)?[[parts objectAtIndex:1] intValue]:0;
		retVersion.point = (partCount>2)?[[parts objectAtIndex:2] intValue]:0;
	});
	
	return retVersion;
}

@end
