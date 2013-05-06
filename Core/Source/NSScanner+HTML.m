//
//  NSScanner+HTML.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/12/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCoreText.h"
#import "NSScanner+HTML.h"
#import "NSCharacterSet+HTML.h"

@implementation NSScanner (HTML)

#pragma mark CSS

// scan a single element from a style list
- (BOOL)scanCSSAttribute:(NSString **)name value:(NSString **)value
{
	NSString *attrName = nil;
	NSMutableString *attrValue = [NSMutableString string];
	
	NSInteger initialScanLocation = [self scanLocation];
	
	NSCharacterSet *whiteCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	
	NSMutableCharacterSet *nonWhiteCharacterSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy];
	[nonWhiteCharacterSet formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@";"]];
	[nonWhiteCharacterSet invert];
	
	// alphanumeric plus -
	NSCharacterSet *cssStyleAttributeNameCharacterSet = [NSCharacterSet cssStyleAttributeNameCharacterSet];
	
	if (![self scanCharactersFromSet:cssStyleAttributeNameCharacterSet intoString:&attrName])
	{
		return NO;
	}
	
	// skip whitespace
	[self scanCharactersFromSet:whiteCharacterSet intoString:NULL];
	
	// expect :
	if (![self scanString:@":" intoString:NULL])
	{
		[self setScanLocation:initialScanLocation];
		return NO;
	}
	
	// skip whitespace
	[self scanCharactersFromSet:whiteCharacterSet intoString:NULL];
	
	NSString *quote = nil;
	if ([self scanCharactersFromSet:[NSCharacterSet quoteCharacterSet] intoString:&quote])
	{
		// attribute is quoted
		
		if (![self scanUpToString:quote intoString:&attrValue])
		{
			[self setScanLocation:initialScanLocation];
			return NO;
		}
		
		// skip ending quote
		[self scanString:quote intoString:NULL];
		
		// skip whitespace
		[self scanCharactersFromSet:whiteCharacterSet intoString:NULL];
		
		//TODO: decode unicode sequences like "\2022"
		
		// skip ending characters
		[self scanString:@";" intoString:NULL];
	}
	else
	{
		// attribute is not quoted, we append elements until we find a ; or the string is at the end
		while (![self isAtEnd])
		{
			NSString *value = nil;
			if (![self scanCharactersFromSet:nonWhiteCharacterSet intoString:&value])
			{
				// skip ending characters
				[self scanString:@";" intoString:NULL];
				
				break;
			}
			
			// interleave a space if there are multiple parts
			if ([attrValue length])
			{
				[attrValue appendString:@" "];
			}
			
			[attrValue appendString:value];
			
			// skip whitespace
			[self scanCharactersFromSet:whiteCharacterSet intoString:NULL];
			
			if ([self scanString:@";" intoString:NULL])
			{
				// reached end of attribute
				break;
			}
		}
	}
	
	
	
	// Success 
	if (name)
	{
		*name = attrName;
	}
	
	if (value)
	{
		*value = attrValue;
	}
	
	return YES;
}

/*
 
 Source: http://www.w3.org/TR/CSS1/#url
 
 The format of a URL value is 'url(' followed by optional white space followed by an optional single quote (') or double quote (") character followed by the URL itself (as defined in [11]) followed by an optional single quote (') or double quote (") character followed by optional whitespace followed by ')'. Quote characters that are not part of the URL itself must be balanced.
 
 Parentheses, commas, whitespace characters, single quotes (') and double quotes (") appearing in a URL must be escaped with a backslash: '\(', '\)', '\,'.
 
 Partial URLs are interpreted relative to the source of the style sheet, not relative to the document:
*/

// NOTE: Simplified, we assume that there are no quotes in the URL

- (BOOL)scanCSSURL:(NSString **)urlString
{
	if (![self scanString:@"url(" intoString:NULL])
	{
		return NO;
	}
	

	NSCharacterSet *quoteCharacterSet = [NSCharacterSet quoteCharacterSet];
	NSString *quote;
	NSString *attrValue;
	
	if ([self scanCharactersFromSet:quoteCharacterSet intoString:&quote])
	{
		if ([quote length]==1)
		{
			[self scanUpToString:quote intoString:&attrValue];	
			[self scanString:quote intoString:NULL];
		}
		else
		{
			// most likely e.g. href=""
			attrValue = @"";
		}
		
		// decode HTML entities
		attrValue = [attrValue stringByReplacingHTMLEntities];
	}
	else 
	{
		// non-quoted attribute, ends at )
		if ([self scanUpToString:@")" intoString:&attrValue])
		{
			// decode HTML entities
			attrValue = [attrValue stringByReplacingHTMLEntities];
		}
	}

	if (urlString)
	{
		*urlString = attrValue;
	}
	
	return YES;
}

- (BOOL)scanHTMLColor:(DTColor **)color
{
	NSUInteger indexBefore = [self scanLocation];
	
	NSString *colorName = nil;
	
	NSMutableCharacterSet *tokenEndSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy];
	[tokenEndSet addCharactersInString:@","];
	
	if ([self scanString:@"#" intoString:NULL])
	{
		self.scanLocation = indexBefore;
		
		[self scanUpToCharactersFromSet:tokenEndSet intoString:&colorName];
	}
	else if ([self scanString:@"rgb" intoString:NULL])
	{
		if ([self scanUpToString:@")" intoString:NULL])
		{
			self.scanLocation++;
			colorName = [[self string] substringWithRange:NSMakeRange(indexBefore, self.scanLocation - indexBefore)];
			
			colorName = [colorName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		}
	}
	else
	{
		// could be a plain html color name
		[self scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:&colorName];
	}
	
	DTColor *foundColor = nil;
	
	if (colorName)
	{
		foundColor = [DTColor colorWithHTMLName:colorName];
	}
	
	if (!foundColor)
	{
		self.scanLocation = indexBefore;
		return NO;
	}
	
	if (color)
	{
		*color = foundColor;
	}
	
	return YES;
}

@end
