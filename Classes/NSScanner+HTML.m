//
//  NSScanner+HTML.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/12/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "NSScanner+HTML.h"


@implementation NSScanner (HTML)

- (NSString *)peekNextTag
{
	NSScanner *scanner = [[self copy] autorelease];
	
	[scanner scanUpToString:@"<" intoString:NULL];
	
	[scanner scanString:@"<" intoString:NULL];
	
	[scanner scanString:@"/" intoString:NULL];

	NSString *nextTag = nil;
	
	NSCharacterSet *tagCharacters = [NSCharacterSet alphanumericCharacterSet];
	[scanner scanCharactersFromSet:tagCharacters intoString:&nextTag];
	
	return [nextTag lowercaseString];
}

@end
