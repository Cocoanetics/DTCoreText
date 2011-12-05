//
//  UIDevice+DTVersion.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 5/30/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//



typedef struct
{
	NSInteger major;
	NSInteger minor;
	NSInteger point;
} DTVersion;

@interface UIDevice (DTVersion)

- (DTVersion) osVersion;

@end
