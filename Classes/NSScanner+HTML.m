//
//  NSScanner+HTML.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/12/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "NSScanner+HTML.h"


@implementation NSScanner (HTML)

- (NSString *)peekNextTag // SkippedAlpha:(BOOL *)didSkipAlpha
{
	NSScanner *scanner = [[self copy] autorelease];
	
	do
	{
		NSString *textUpToNextTag = nil;
		
		if ([scanner scanUpToString:@"<" intoString:&textUpToNextTag])
		{
			// check if there are alpha chars after the end tag
			NSScanner *subScanner = [NSScanner scannerWithString:textUpToNextTag];
			[subScanner scanUpToString:@">" intoString:NULL];
			[subScanner scanString:@">" intoString:NULL];
			
			// rest might be alpha
			NSString *rest = [[textUpToNextTag substringFromIndex:subScanner.scanLocation] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			
			// we don't want a newline in this case so we send back any inline character
			if ([rest length])
			{
				return @"b";
			}
		}
		
		[scanner scanString:@"<" intoString:NULL];
	} while ([scanner scanString:@"/" intoString:NULL]);

	NSString *nextTag = nil;
	
	NSCharacterSet *tagCharacters = [NSCharacterSet alphanumericCharacterSet];
	[scanner scanCharactersFromSet:tagCharacters intoString:&nextTag];
	
	return [nextTag lowercaseString];
}

/*

- (BOOL)hasTextBeforeEndOfTag(NSString *)currentTag
{
	BOOL b = NO;
	
	NSScanner *scanner = [[self copy] autorelease];

	// 
	
	
	
	do
	{
		// skip until end of current tag
		[scanner scanUpToString:@">" intoString:NULL];
		[scanner scanString:@">" intoString:NULL];

		// see if there a alpha right after it
		if ([scanner scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:NULL])
		{
			b = YES;
		}

		[scanner scanUpToString:@"<" intoString:NULL];
		[scanner scanString:@"<" intoString:NULL];
	} while ([scanner scanString:@"/" intoString:NULL]);
	
	NSString *nextTag = nil;
	
	NSCharacterSet *tagCharacters = [NSCharacterSet alphanumericCharacterSet];
	[scanner scanCharactersFromSet:tagCharacters intoString:&nextTag];
	
	return [nextTag lowercaseString];
}
 
 */


@end
