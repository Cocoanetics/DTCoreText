//
//  NSString+HTML.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "NSString+HTML.h"

static NSSet *inlineTags = nil;

@implementation NSString (HTML)

- (NSUInteger)integerValueFromHex
{
    NSScanner *scanner = [NSScanner scannerWithString:self];
	unsigned int result = 0;
    [scanner scanHexInt: &result];
	
    return result;
}

- (BOOL)isInlineTag
{
	if (!inlineTags)
	{
		inlineTags = [[NSSet alloc] initWithObjects:@"font", @"b", @"strong", @"em", @"i", @"sub", @"sup",
					  @"u", @"a", @"image", @"del", @"br", nil];
	}
	
	return [inlineTags containsObject:[self lowercaseString]];
}

@end
