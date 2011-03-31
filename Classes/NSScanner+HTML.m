//
//  NSScanner+HTML.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/12/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "NSScanner+HTML.h"
#import "NSCharacterSet+HTML.h"

@implementation NSScanner (HTML)

- (NSString *)peekNextTagSkippingClosingTags:(BOOL)skipClosingTags
{
	NSScanner *scanner = [[self copy] autorelease];
	
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
	if (![self scanCharactersFromSet:tagCharacterSet intoString:&scannedTagName])
	{
		[self setScanLocation:initialScanLocation];
		return NO;
	}

	// make tags lowercase
	scannedTagName = [scannedTagName lowercaseString];
	
	//[self scanCharactersFromSet:whiteCharacterSet intoString:NULL];
	
	// Read attributes of tag
	while (![self isAtEnd])
	{
		if ([self scanString:@"/" intoString:NULL])
		{
			
			immediatelyClosed = YES;
			break;
		}
		
		if ([self scanString:@">" intoString:NULL])
		{
			break;
		}
		
		[self scanCharactersFromSet:whiteCharacterSet intoString:NULL];
		
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
				[self scanUpToString:quote intoString:&attrValue];	
				[self scanString:quote intoString:NULL];
				
				[tmpAttributes setObject:attrValue forKey:attrName];
			}
			else 
			{
				// non-quoted attribute, ends at /, > or whitespace
				if ([self scanUpToCharactersFromSet:nonquoteAttributedEndCharacterSet intoString:&attrValue])
				{
					[tmpAttributes setObject:attrValue forKey:attrName];
				}
			}
		}
		
		[self scanCharactersFromSet:whiteCharacterSet intoString:NULL];
	}

	// skip ending bracket
	//[self scanCharactersFromSet:whiteCharacterSet intoString:NULL];
	//[self scanString:@">" intoString:NULL];
	
	
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
	NSCharacterSet *attributeNameCharacterSet = [NSCharacterSet tagAttributeNameCharacterSet];
                                                 
	
	
	if (![self scanCharactersFromSet:attributeNameCharacterSet intoString:&attrName])
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


// for debugging scanner
- (void)logPosition
{
	NSLog(@"%@", [[self string] substringFromIndex:[self scanLocation]]);
}

@end
