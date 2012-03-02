//
//  NSMutableString+HTML.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 01.02.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "NSMutableString+HTML.h"


#define IS_WHITESPACE(_c) (_c == ' ' || _c == '\t' || _c == 0xA || _c == 0xB || _c == 0xC || _c == 0xD || _c == 0x85)

@implementation NSMutableString (HTML)

- (void)removeTrailingWhitespace
{
	NSUInteger length = self.length;
	
	NSInteger lastIndex = length-1;
	NSInteger index = lastIndex;
	NSInteger whitespaceLength = 0;
	
	while (index>=0 && IS_WHITESPACE([self characterAtIndex:index])) 
	{
		index--;
		whitespaceLength++;
	}

	// do the removal once for all whitespace characters
	if (whitespaceLength)
	{
		[self deleteCharactersInRange:NSMakeRange(index+1, whitespaceLength)];
	}
}

@end
