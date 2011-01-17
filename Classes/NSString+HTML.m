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
					  @"u", @"a", @"img", @"del", @"br", nil];
	}
	
	return [inlineTags containsObject:[self lowercaseString]];
}


- (NSString *)stringByNormalizingWhitespace
{
	NSCharacterSet *whiteSpaceCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	
	NSScanner *scanner = [NSScanner scannerWithString:self];
	[scanner setCharactersToBeSkipped:nil];
	
	NSMutableArray *tokens = [NSMutableArray array];
	
	NSString *prefix = @"";
	if ([scanner scanCharactersFromSet:whiteSpaceCharacterSet intoString:NULL])
	{
		prefix = @" ";
	}

	NSString *suffix = @"";
	
	while (![scanner isAtEnd])
	{
		NSString *string = nil;
		
		if ([scanner scanUpToCharactersFromSet:whiteSpaceCharacterSet intoString:&string])
		{
			[tokens addObject:string];
		}
		
		if ([scanner scanCharactersFromSet:whiteSpaceCharacterSet intoString:NULL])
		{
			suffix = @" ";
		}
		else 
		{
			suffix = @"";
		}
	}
	
	NSString *retStr = [NSString stringWithFormat:@"%@%@%@", prefix, [tokens componentsJoinedByString:@" "], suffix];
	
	return retStr;
}


- (BOOL)hasPrefixCharacterFromSet:(NSCharacterSet *)characterSet
{
	if (![self length])
	{
		return NO;
	}
	
	unichar firstChar = [self characterAtIndex:0];
	
	return [characterSet characterIsMember:firstChar];
}

@end
