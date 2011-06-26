//
//  NSMutableAttributedString+HTML.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 4/14/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "NSMutableAttributedString+HTML.h"

#import <CoreText/CoreText.h>


@implementation NSMutableAttributedString (HTML)


// apends a plain string extending the attributes at this position
- (void)appendString:(NSString *)string
{
	NSInteger length = [self length];
	
	NSDictionary *previousAttributes = nil;
	
	if (length)
	{
		// get attributes from last character
		previousAttributes = [self attributesAtIndex:length-1 effectiveRange:NULL];
	}
	
	NSAttributedString *tmpString = [[NSAttributedString alloc] initWithString:string attributes:previousAttributes];
	[self appendAttributedString:tmpString];
	[tmpString release];
}

// appends a string without any attributes
- (void)appendNakedString:(NSString *)string
{
	NSAttributedString *nakedString = [[NSAttributedString alloc] initWithString:string attributes:nil];
	[self appendAttributedString:nakedString];
	[nakedString release];
}

@end
