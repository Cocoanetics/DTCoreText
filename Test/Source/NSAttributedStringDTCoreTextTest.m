//
//  NSAttributedStringDTCoreTextTest.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 30.09.13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "NSAttributedStringDTCoreTextTest.h"
#import "NSAttributedString+DTCoreText.h"

@implementation NSAttributedStringDTCoreTextTest

- (void)testRangeOfAnchor
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<p>some text</p><a name=\"anchor\">anchor</a><p>more text</p>" options:NULL];
	
	NSRange range = [attributedString rangeOfAnchorNamed:@"anchor"];
	NSRange expectedRange = NSMakeRange(10, 7);
	STAssertEquals(range, expectedRange, @"Incorrect Result for findable anchor");
	
	range = [attributedString rangeOfAnchorNamed:@"something"];
	expectedRange = NSMakeRange(NSNotFound, 0);
	STAssertEquals(range, expectedRange, @"Incorrect Result for non-findable anchor");
}

#pragma mark - Text Blocks

- (void)testTextBlockRange
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<p>some text</p><div style=\"padding:10px\">inside</div><p>following</p>" options:NULL];
	
	NSRange innerRange = [[attributedString string] rangeOfString:@"inside\n"];
	
	// inner block has padding 10 around and no background color
	DTTextBlock *newBlock = [[DTTextBlock alloc] init];
	newBlock.padding = DTEdgeInsetsMake(10, 10, 10, 10);

	NSDictionary *innerAttributes = [attributedString attributesAtIndex:innerRange.location effectiveRange:NULL];
	NSArray *blocks = [innerAttributes objectForKey:DTTextBlocksAttribute];
	STAssertTrue([blocks count]==1, @"There should be 1 block");
	DTTextBlock *effectiveBlock = [blocks lastObject];
	
	// test other block inside range
	NSRange nonFoundRange = [attributedString rangeOfTextBlock:newBlock atIndex:innerRange.location];
	NSRange expectedRange = NSMakeRange(NSNotFound, 0);
	STAssertEquals(nonFoundRange, expectedRange, @"Should not find other block inside");

	// test other block outside range
	nonFoundRange = [attributedString rangeOfTextBlock:newBlock atIndex:1];
	expectedRange = NSMakeRange(NSNotFound, 0);
	STAssertEquals(nonFoundRange, expectedRange, @"Should not find other block at index 1");
	
	// test effective block outside range
	nonFoundRange = [attributedString rangeOfTextBlock:effectiveBlock atIndex:1];
	expectedRange = NSMakeRange(NSNotFound, 0);
	STAssertEquals(nonFoundRange, expectedRange, @"Should not find effective block at index 1");
	
	// test effective block outside range
	NSRange foundRange = [attributedString rangeOfTextBlock:effectiveBlock atIndex:innerRange.location];
	expectedRange = innerRange;
	STAssertEquals(foundRange, expectedRange, @"Should find effective block around 'inside'");
}

#pragma mark - Lists

- (void)testListRange
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<p>some text</p><ul><li>inside</li></ul><p>following</p>" options:NULL];
	
	NSRange innerRange = [[attributedString string] rangeOfString:@"inside\n"];
	
	NSDictionary *innerAttributes = [attributedString attributesAtIndex:innerRange.location effectiveRange:NULL];
	NSArray *lists = [innerAttributes objectForKey:DTTextListsAttribute];
	STAssertTrue([lists count]==1, @"There should be 1 block");
	DTCSSListStyle *effectiveList = [lists lastObject];
	
	// new list with equal values, but different list
	DTCSSListStyle *newListStyle = [effectiveList copy];

	STAssertFalse(effectiveList == newListStyle, @"Copy should have produced a different instance");
	
	// test new list inside range
	NSRange nonFoundRange = [attributedString rangeOfTextList:newListStyle atIndex:innerRange.location];
	NSRange expectedRange = NSMakeRange(NSNotFound, 0);
	STAssertEquals(nonFoundRange, expectedRange, @"Should not find other list inside");

	// test new list outside range
	nonFoundRange = [attributedString rangeOfTextList:newListStyle atIndex:1];
	expectedRange = NSMakeRange(NSNotFound, 0);
	STAssertEquals(nonFoundRange, expectedRange, @"Should not find other list at index 1");

	// test effective list inside range
	NSRange foundRange = [attributedString rangeOfTextList:effectiveList atIndex:innerRange.location];
	expectedRange = [[attributedString string] paragraphRangeForRange:innerRange];
	STAssertEquals(foundRange, expectedRange, @"Should find effective list around 'inner'");
	
	// test effective list outside range
	nonFoundRange = [attributedString rangeOfTextList:effectiveList atIndex:1];
	expectedRange = NSMakeRange(NSNotFound, 0);
	STAssertEquals(nonFoundRange, expectedRange, @"Should not find effective list at index 1");
}

@end
