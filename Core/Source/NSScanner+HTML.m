//
//  NSScanner+HTML.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/12/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "NSScanner+HTML.h"
#import "NSCharacterSet+HTML.h"
#import "NSString+HTML.h"

@implementation NSScanner (HTML)

- (NSString *)peekNextTagSkippingClosingTags:(BOOL)skipClosingTags
{
	NSScanner *scanner = [self copy];
	
	do
	{
		NSString *textUpToNextTag = nil;
		
		if ([scanner scanUpToString:@"<" intoString:&textUpToNextTag])
		{
			// Check if there are alpha chars after the end tag
			NSScanner *subScanner = [NSScanner scannerWithString:textUpToNextTag];
			[subScanner scanUpToString:@">" intoString:NULL];
			[subScanner scanString:@">" intoString:NULL];
			
			// Rest might be alpha
			NSString *rest = [[textUpToNextTag substringFromIndex:subScanner.scanLocation] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			
			// We don't want a newline in this case so we send back any inline character
			if ([rest length])
			{
				return @"b";
			}
		}
		
		[scanner scanString:@"<" intoString:NULL];
	} while (skipClosingTags&&[scanner scanString:@"/" intoString:NULL]);
	
	NSString *nextTag = nil;
	
	[scanner scanCharactersFromSet:[NSCharacterSet tagNameCharacterSet] intoString:&nextTag];
	
	return [nextTag lowercaseString];
}

- (BOOL)scanHTMLTag:(NSString **)tagName attributes:(NSDictionary **)attributes isOpen:(BOOL *)isOpen isClosed:(BOOL *)isClosed
{
	NSInteger initialScanLocation = [self scanLocation];
	
	if (![self scanString:@"<" intoString:NULL])
	{
		[self setScanLocation:initialScanLocation];
		return NO;
	}
	
	BOOL tagOpen = YES;
	BOOL immediatelyClosed = NO;
	
	NSCharacterSet *tagCharacterSet = [NSCharacterSet tagNameCharacterSet];
	NSCharacterSet *tagAttributeNameCharacterSet = [NSCharacterSet tagAttributeNameCharacterSet];
	NSCharacterSet *quoteCharacterSet = [NSCharacterSet quoteCharacterSet];
	NSCharacterSet *whiteCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	NSCharacterSet *nonquoteAttributedEndCharacterSet = [NSCharacterSet nonQuotedAttributeEndCharacterSet];
	
	NSString *scannedTagName = nil;
	NSMutableDictionary *tmpAttributes = [NSMutableDictionary dictionary];
	
	if ([self scanString:@"/" intoString:NULL])
	{
		// Close of tag
		tagOpen = NO;
	}
	
	[self scanCharactersFromSet:whiteCharacterSet intoString:NULL];
	
	// Read the tag name
	if ([self scanCharactersFromSet:tagCharacterSet intoString:&scannedTagName])
	{
		// make tags lowercase
		scannedTagName = [scannedTagName lowercaseString];
		
		[self scanCharactersFromSet:whiteCharacterSet intoString:NULL];
	}
	else
	{
		// might also be a comment
		if ([self scanString:@"!--" intoString:NULL])
		{
			scannedTagName = @"#COMMENT#";
			
			NSString *commentStr = nil;
			
			if ([self scanUpToString:@"-->" intoString:&commentStr])
			{
				[tmpAttributes setObject:commentStr forKey:@"CommentText"];
			}
			
			// skip closing
			[self scanString:@"-->" intoString:NULL];
			
			tagOpen = NO;
			immediatelyClosed = YES;
		}
		else
		{
			// not a valid tag, treat as text
			[self setScanLocation:initialScanLocation];
			return NO;
		}
	}
	
	// Read attributes of tag
	while (![self isAtEnd] && !immediatelyClosed)
	{
		if ([self scanString:@"/" intoString:NULL])
		{
			
			immediatelyClosed = YES;
		}
		
		[self scanCharactersFromSet:whiteCharacterSet intoString:NULL];
		
		if ([self scanString:@">" intoString:NULL])
		{
			break;
		}
		
		NSString *attrName = nil;
		NSString *attrValue = nil;
		
		if (![self scanCharactersFromSet:tagAttributeNameCharacterSet intoString:&attrName])
		{
			immediatelyClosed = YES;
			break;
		}
		
		attrName = [attrName lowercaseString];
		
		[self scanCharactersFromSet:whiteCharacterSet intoString:NULL];
		
		if (![self scanString:@"=" intoString:nil])
		{
			// solo attribute
			[tmpAttributes setObject:attrName forKey:attrName];
		}
		else 
		{
			// attribute = value
			NSString *quote = nil;
			
			[self scanCharactersFromSet:whiteCharacterSet intoString:NULL];
			
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
				
				[tmpAttributes setObject:attrValue forKey:attrName];
			}
			else 
			{
				// non-quoted attribute, ends at /, > or whitespace
				if ([self scanUpToCharactersFromSet:nonquoteAttributedEndCharacterSet intoString:&attrValue])
				{
					// decode HTML entities
					attrValue = [attrValue stringByReplacingHTMLEntities];

					[tmpAttributes setObject:attrValue forKey:attrName];
				}
			}
		}
		
		[self scanCharactersFromSet:whiteCharacterSet intoString:NULL];
	}
	
	// Success 
	if (isClosed)
	{
		*isClosed = immediatelyClosed;
	}
	
	if (isOpen)
	{
		*isOpen = tagOpen;
	}
	
	if (attributes)
	{
		// converting to immutable costs 10.4% of method
		//*attributes = [NSDictionary dictionaryWithDictionary:tmpAttributes];
		*attributes = tmpAttributes;
	}
	
	if (tagName)
	{
		*tagName = scannedTagName;
	}
	
	return YES;
}


- (BOOL)scanDOCTYPE:(NSString **)contents
{
 	NSInteger initialScanLocation = [self scanLocation];
	
	if (![self scanString:@"<!" intoString:NULL])
	{
		[self setScanLocation:initialScanLocation];
		return NO;
	}
	
	NSString *body = nil;
	
	if (![self scanUpToString:@">" intoString:&body])
	{
		[self setScanLocation:initialScanLocation];
		return NO;
	}
	
	if (![self scanString:@">" intoString:NULL])
	{
		[self setScanLocation:initialScanLocation];
		return NO;
	}
	
	if (contents)
	{
		*contents = body;
	}
	
	return YES;
}


#pragma mark CSS


// scan a single element from a style list
- (BOOL)scanCSSAttribute:(NSString **)name value:(NSString **)value
{
	NSString *attrName = nil;
	NSString *attrValue = nil;
	
	NSInteger initialScanLocation = [self scanLocation];
	
	NSCharacterSet *whiteCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	
	
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
	
	if (![self scanUpToString:@";" intoString:&attrValue])
	{
		[self setScanLocation:initialScanLocation];
		return NO;
	}
	
	// skip ending characters
	[self scanString:@";" intoString:NULL];
	
	
	// Success 
	if (name)
	{
		*name = [attrName lowercaseString];
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

// for debugging scanner
- (void)logPosition
{
	NSLog(@"%@", [[self string] substringFromIndex:[self scanLocation]]);
}

@end
