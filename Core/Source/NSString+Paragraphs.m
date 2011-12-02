//
//  NSString+Paragraphs.m
//  DTRichTextEditor
//
//  Created by Oliver Drobnik on 11/11/11.
//  Copyright (c) 2011 Cocoanetics. All rights reserved.
//

#import "NSString+Paragraphs.h"

@implementation NSString (Paragraphs)

- (NSRange)rangeOfParagraphsContainingRange:(NSRange)range parBegIndex:(NSUInteger *)parBegIndex parEndIndex:(NSUInteger *)parEndIndex
{
	// get beginning and end of paragraph containing the replaced range
	CFIndex beginIndex;
	CFIndex endIndex;
	
	CFStringGetParagraphBounds((__bridge CFStringRef)self, CFRangeMake(range.location, range.length), &beginIndex, &endIndex, NULL);
	
	if (parBegIndex)
	{
		*parBegIndex = beginIndex;
	}
	
	if (parEndIndex)
	{
		*parEndIndex = endIndex;
	}
	
	return NSMakeRange(beginIndex, endIndex - beginIndex);
}

- (BOOL)indexIsAtBeginningOfParagraph:(NSUInteger)index
{
	// index zero is beginning of first paragraph
	if (!index)
	{
		return YES;
	}
	
	// beginning of any other paragraph is after NL
	if ([self characterAtIndex:index-1] == '\n')
	{
		return YES;
	}
	
	// no beginning
	return NO;
}

@end
