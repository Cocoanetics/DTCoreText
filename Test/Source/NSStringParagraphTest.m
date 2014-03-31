//
//  NSStringParagraphTest.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 11.04.13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "NSStringParagraphTest.h"
#import "NSString+Paragraphs.h"

@implementation NSStringParagraphTest

- (void)testParagraphFinding
{
	NSString *string = @"abc\ndef\n\nghi";
	
	NSRange range = NSMakeRange(3, 1);
	NSUInteger begIndex;
	NSUInteger endIndex;
	
	// range on NL character
	NSRange paragraphRange = [string rangeOfParagraphsContainingRange:range parBegIndex:&begIndex parEndIndex:&endIndex];
	NSRange expectedRange = NSMakeRange(0, 4);
	STAssertEquals(paragraphRange, expectedRange, @"First range");
	STAssertEquals(begIndex, (NSUInteger)0, @"First range start index");
	STAssertEquals(endIndex, (NSUInteger)4, @"First range end index");

	// empty range
	range = NSMakeRange(3, 0);
	paragraphRange = [string rangeOfParagraphsContainingRange:range parBegIndex:&begIndex parEndIndex:&endIndex];
	expectedRange = NSMakeRange(0, 4);
	STAssertEquals(paragraphRange, expectedRange, @"Second range");
	STAssertEquals(begIndex, (NSUInteger)0, @"Second range start index");
	STAssertEquals(endIndex, (NSUInteger)4, @"Second range end index");

	// test empty paragraph
	range = NSMakeRange(8, 1);
	paragraphRange = [string rangeOfParagraphsContainingRange:range parBegIndex:&begIndex parEndIndex:&endIndex];
	expectedRange = NSMakeRange(8, 1);
	STAssertEquals(paragraphRange, expectedRange, @"Second range");
	STAssertEquals(begIndex, (NSUInteger)8, @"Second range start index");
	STAssertEquals(endIndex, (NSUInteger)9, @"Second range end index");
	
	// range at end of string
	range = NSMakeRange(9, 2);
	paragraphRange = [string rangeOfParagraphsContainingRange:range parBegIndex:&begIndex parEndIndex:&endIndex];
	expectedRange = NSMakeRange(9, 3);
	STAssertEquals(paragraphRange, expectedRange, @"Third range");
	STAssertEquals(begIndex, (NSUInteger)9, @"Third range start index");
	STAssertEquals(endIndex, (NSUInteger)12, @"Third range end index");
}

@end
