//
//  NSScanner+HTML.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/12/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "NSScanner+HTML.h"
#import "NSCharacterSet+HTML.h"
#import "DTColorFunctions.h"
#import "NSString+HTML.h" 

@implementation NSScanner (HTML)

#pragma mark CSS

// scan a single element from a style list
- (BOOL)scanCSSAttribute:(NSString * __autoreleasing*)name value:(id __autoreleasing*)value
{
	NSString *attrName = nil;
	
	NSInteger initialScanLocation = [self scanLocation];
	
	NSCharacterSet *whiteCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	
	NSMutableCharacterSet *nonWhiteCharacterSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy];
	[nonWhiteCharacterSet formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@";"]];
	[nonWhiteCharacterSet invert];

	NSMutableCharacterSet *nonWhiteCommaCharacterSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy];
	[nonWhiteCommaCharacterSet formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@";,"]];
	[nonWhiteCommaCharacterSet invert];

	
	// alphanumeric plus -
	NSCharacterSet *cssStyleAttributeNameCharacterSet = [NSCharacterSet cssStyleAttributeNameCharacterSet];
	
	if (![self scanCharactersFromSet:cssStyleAttributeNameCharacterSet intoString:&attrName])
	{
		return NO;
	}
	
	// skip whitespace
	[self scanCharactersFromSet:whiteCharacterSet intoString:NULL];
	
	// expect :
	if (![self  scanString:@":" intoString:NULL])
	{
		[self setScanLocation:initialScanLocation];
		return NO;
	}
	
	// skip whitespace
	[self scanCharactersFromSet:whiteCharacterSet intoString:NULL];
	
	NSMutableArray *results = [NSMutableArray array];
	BOOL nextIterationAddsNewEntry = YES;
	
	while (![self isAtEnd] && ![self scanString:@";" intoString:NULL])
	{
		// skip whitespace
		[self scanCharactersFromSet:whiteCharacterSet intoString:NULL];

		NSString *quote = nil;
		if ([self scanCharactersFromSet:[NSCharacterSet quoteCharacterSet] intoString:&quote])
		{
			NSString *quotedValue = nil;
			
			// attribute is quoted
			if (![self scanUpToString:quote intoString:&quotedValue])
			{
				[self setScanLocation:initialScanLocation];
				return NO;
			}
			else
			{
				if (nextIterationAddsNewEntry)
				{
					[results addObject:quotedValue];
					nextIterationAddsNewEntry = NO;
				}
				else
				{
					quotedValue = [NSString stringWithFormat:@"%@ %@%@%@", [results lastObject], quote, quotedValue, quote];
					[results removeLastObject];
					[results addObject:quotedValue];
				}
			}
			
			// skip ending quote
			[self scanString:quote intoString:NULL];
			
			//TODO: decode unicode sequences like "\2022"
		}
		else
		{
			// attribute is not quoted, we append elements until we find a ; or the string is at the end
			NSString *valueString = nil;
			
			if ([self scanString:@"rgb(" intoString:&valueString])
			{
				if ([valueString isEqualToString:@"rgb("])
				{
					[self scanUpToString:@";" intoString:&valueString];
					NSString * formattedRGBString = [NSString stringWithFormat:@"rgb(%@", valueString];
					
					if (nextIterationAddsNewEntry)
					{
						[results addObject:formattedRGBString];
						nextIterationAddsNewEntry = NO;
					}
					else
					{
						valueString = [NSString stringWithFormat:@"%@ %@", [results lastObject], formattedRGBString];
						[results removeLastObject];
						[results addObject:valueString];
					}
				}
			}
			else if ([self scanString:@"," intoString:&valueString])
			{
                BOOL isStringOnlyCSSProperty = NO;
                
				if (![valueString isEqualToString:@","])
				{
					[results addObject:valueString];
				}
				else if ([attrName isEqualToString:@"font"] ||
						 ([attrName rangeOfString:@"color"].location != NSNotFound) ||
						 ([attrName rangeOfString:@"shadow"].location != NSNotFound) ||
						 ([attrName rangeOfString:@"background"].location != NSNotFound))
				{
					valueString = [NSString stringWithFormat:@"%@%@", [results lastObject], valueString];
					[results removeLastObject];
					[results addObject:valueString];
                    
                    isStringOnlyCSSProperty = YES;
				}
				
				if ([valueString isEqualToString:@","] && !isStringOnlyCSSProperty)
				{
					nextIterationAddsNewEntry = YES;
				}
			}
			else if ([self scanCharactersFromSet:nonWhiteCommaCharacterSet intoString:&valueString])
			{
				if ([valueString length] && ![valueString isEqualToString:@","])
				{
					if (nextIterationAddsNewEntry) {
						[results addObject:valueString];
						nextIterationAddsNewEntry = NO;
					} else {
						valueString = [NSString stringWithFormat:@"%@ %@", [results lastObject], valueString];
						[results removeLastObject];
						[results addObject:valueString];
					}
				}
			}
		}

		// skip whitespace
		[self scanCharactersFromSet:whiteCharacterSet intoString:NULL];
	}
	
	// Success 
	if (name)
	{
		*name = attrName;
	}
	
	if (value)
	{
		if (results.count == 0) {
			*value = @"";
		} else if (results.count == 1) {
			*value = [results objectAtIndex:0];
		} else {
			*value = results;
		}
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

- (BOOL)scanCSSURL:(NSString * __autoreleasing*)urlString
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

- (BOOL)scanHTMLColor:(DTColor * __autoreleasing*)color
{
	return [self scanHTMLColor:color HTMLName:NULL];
}

- (BOOL)scanHTMLColor:(DTColor * __autoreleasing*)color HTMLName:(NSString * __autoreleasing*)name
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
		foundColor = DTColorCreateWithHTMLName(colorName);
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

	if (name) {
		*name = colorName;
	}

	return YES;
}

@end
