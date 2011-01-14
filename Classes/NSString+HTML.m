//
//  NSString+HTML.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "NSString+HTML.h"

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
	NSString *tag = [self lowercaseString];
	
	BOOL inlineTag = ([tag isEqualToString:@"font"] || 
					  [tag isEqualToString:@"b"] ||
					  [tag isEqualToString:@"strong"] ||
					  [tag isEqualToString:@"em"] ||
					  [tag isEqualToString:@"i"] ||
					  [tag isEqualToString:@"sub"] ||
					  [tag isEqualToString:@"sup"] ||
					  [tag isEqualToString:@"u"]);
	
	return inlineTag;
}

@end
