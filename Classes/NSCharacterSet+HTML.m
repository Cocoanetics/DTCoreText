//
//  NSCharacterSet+HTML.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/15/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "NSCharacterSet+HTML.h"


@implementation NSCharacterSet (HTML)

+ (NSCharacterSet *)tagNameCharacterSet
{
	return [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"];
}

@end
