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

- (NSDictionary *)dictionaryOfAttributesFromTag
{
	NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
	
	NSString *stringToScan = self;
	
	NSScanner *attributeScanner = [NSScanner scannerWithString:stringToScan];
	
//	NSMutableArray *attributeArray = [NSMutableArray array];
	
	// Skip leading <tagname
	
	NSString *temp = nil;
	
	if ([attributeScanner scanString:@"<" intoString:&temp])
	{
		[attributeScanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&temp];
		[attributeScanner scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:&temp];
		[attributeScanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&temp];
	}
	
	while (![attributeScanner isAtEnd])
	{
		NSString *attrName = nil;
		NSString *attrValue = nil;
		
		[attributeScanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&temp];
		[attributeScanner scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:&attrName];
		[attributeScanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&temp];
		[attributeScanner scanString:@"=" intoString:nil];
		[attributeScanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&temp];
		
		NSString *quote = nil;
		
		if ([attributeScanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"'\""] intoString:&quote])
		{
			[attributeScanner scanUpToString:quote intoString:&attrValue];	
			[attributeScanner scanString:quote intoString:&temp];
			
			[tmpDict setObject:attrValue forKey:attrName];
		}
		else
		{
			// no attribute found, scan to the end
			[attributeScanner setScanLocation:[self length]];
		}
	}
	
	if ([tmpDict count])
	{
		return [NSDictionary dictionaryWithDictionary:tmpDict];
	}
	else 
	{
		return nil;
	}
}


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
					  @"u", @"a", nil];
	}
	
	return [inlineTags containsObject:[self lowercaseString]];
}

@end
