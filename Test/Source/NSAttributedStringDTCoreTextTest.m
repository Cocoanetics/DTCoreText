//
//  NSAttributedStringDTCoreTextTest.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 30.09.13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "NSAttributedStringDTCoreTextTest.h"

@implementation NSAttributedStringDTCoreTextTest

- (void)testRangeOfAnchor
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<p>some text</p><a name=\"anchor\">anchor</a><p>more text</p>" options:NULL];
	
	NSRange range = [attributedString rangeOfAnchorNamed:@"anchor"];
	NSRange expectedRange = NSMakeRange(10, 7);
	XCTAssertTrue(NSEqualRanges(range, expectedRange), @"Incorrect Result for findable anchor");
	
	range = [attributedString rangeOfAnchorNamed:@"something"];
	expectedRange = NSMakeRange(NSNotFound, 0);
	XCTAssertTrue(NSEqualRanges(range, expectedRange), @"Incorrect Result for non-findable anchor");
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
	XCTAssertTrue([blocks count]==1, @"There should be 1 block");
	DTTextBlock *effectiveBlock = [blocks lastObject];
	
	// test other block inside range
	NSRange nonFoundRange = [attributedString rangeOfTextBlock:newBlock atIndex:innerRange.location];
	NSRange expectedRange = NSMakeRange(NSNotFound, 0);
	XCTAssertTrue(NSEqualRanges(nonFoundRange, expectedRange), @"Should not find other block inside");

	// test other block outside range
	nonFoundRange = [attributedString rangeOfTextBlock:newBlock atIndex:1];
	expectedRange = NSMakeRange(NSNotFound, 0);
	XCTAssertTrue(NSEqualRanges(nonFoundRange, expectedRange), @"Should not find other block at index 1");
	
	// test effective block outside range
	nonFoundRange = [attributedString rangeOfTextBlock:effectiveBlock atIndex:1];
	expectedRange = NSMakeRange(NSNotFound, 0);
	XCTAssertTrue(NSEqualRanges(nonFoundRange, expectedRange), @"Should not find effective block at index 1");
	
	// test effective block outside range
	NSRange foundRange = [attributedString rangeOfTextBlock:effectiveBlock atIndex:innerRange.location];
	expectedRange = innerRange;
	XCTAssertTrue(NSEqualRanges(foundRange, expectedRange), @"Should find effective block around 'inside'");
}

#pragma mark - Lists

- (void)testListRange
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<p>some text</p><ul><li>inside</li></ul><p>following</p>" options:NULL];
	
	NSRange innerRange = [[attributedString string] rangeOfString:@"inside\n"];
	
	NSDictionary *innerAttributes = [attributedString attributesAtIndex:innerRange.location effectiveRange:NULL];
	NSArray *lists = [innerAttributes objectForKey:DTTextListsAttribute];
	XCTAssertTrue([lists count]==1, @"There should be 1 block");
	DTCSSListStyle *effectiveList = [lists lastObject];
	
	// new list with equal values, but different list
	DTCSSListStyle *newListStyle = [effectiveList copy];

	XCTAssertFalse(effectiveList == newListStyle, @"Copy should have produced a different instance");
	
	// test new list inside range
	NSRange nonFoundRange = [attributedString rangeOfTextList:newListStyle atIndex:innerRange.location];
	NSRange expectedRange = NSMakeRange(NSNotFound, 0);
	XCTAssertTrue(NSEqualRanges(nonFoundRange, expectedRange), @"Should not find other list inside");

	// test new list outside range
	nonFoundRange = [attributedString rangeOfTextList:newListStyle atIndex:1];
	expectedRange = NSMakeRange(NSNotFound, 0);
	XCTAssertTrue(NSEqualRanges(nonFoundRange, expectedRange), @"Should not find other list at index 1");

	// test effective list inside range
	NSRange foundRange = [attributedString rangeOfTextList:effectiveList atIndex:innerRange.location];
	expectedRange = [[attributedString string] paragraphRangeForRange:innerRange];
	XCTAssertTrue(NSEqualRanges(foundRange, expectedRange), @"Should find effective list around 'inner'");
	
	// test effective list outside range
	nonFoundRange = [attributedString rangeOfTextList:effectiveList atIndex:1];
	expectedRange = NSMakeRange(NSNotFound, 0);
	XCTAssertTrue(NSEqualRanges(nonFoundRange, expectedRange), @"Should not find effective list at index 1");
}

- (void)testListPrefix
{
	DTCSSListStyle *listStyle = [[DTCSSListStyle alloc] initWithStyles:nil];
	listStyle.startingItemNumber = 3;
	listStyle.type = DTCSSListStyleTypeDecimal;
	listStyle.position = DTCSSListStylePositionOutside;
	
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<ol><li>some text</li></ol>" options:NULL];
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:NULL];
	
	NSAttributedString *prefix = [NSAttributedString prefixForListItemWithCounter:3 listStyle:listStyle listIndent:30 attributes:attributes];
	
	XCTAssertTrue([[prefix string] isEqualToString:@"\t3.\t"], @"Prefix should be different");
	attributes = [prefix attributesAtIndex:0 effectiveRange:NULL];
	
	// prefix field should be entire length
	NSRange fieldRange = [prefix rangeOfFieldAtIndex:0];
	NSRange expectedRange = NSMakeRange(0, [prefix length]);
	
	XCTAssertTrue(NSEqualRanges(fieldRange, expectedRange), @"Prefix Field should be entire prefix");
	
	DTCoreTextParagraphStyle *paragraphStyle = [attributes paragraphStyle];
	XCTAssertEqual(paragraphStyle.headIndent, (CGFloat)30, @"head ident should be equal to 30");
	
	NSArray *lists = [attributes objectForKey:DTTextListsAttribute];
	
	XCTAssertTrue([lists count]==1, @"There should be one list in the prefix");
	
	if ([lists count]!=1)
	{
		return;
	}
	
	DTCSSListStyle *effectiveList = [[lists lastObject] copy];
	
	// modify to make equal
	effectiveList.startingItemNumber = 3;
	
	XCTAssertTrue([effectiveList isEqualToListStyle:listStyle], @"Effective list style should be equal");
}

- (void)testItemNumber
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<ol><li>1</li><li>2</li><li>3</li></ol>" options:NULL];

	NSRange entireString = NSMakeRange(0, [attributedString length]);
	[[attributedString string] enumerateSubstringsInRange:entireString options:NSStringEnumerationByParagraphs usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {

		NSDictionary *attributes = [attributedString attributesAtIndex:substringRange.location effectiveRange:NULL];
		DTCSSListStyle *list = [[attributes objectForKey:DTTextListsAttribute] lastObject];
		
		NSRange prefixRange = [attributedString rangeOfFieldAtIndex:substringRange.location];
		substring = [substring substringFromIndex:prefixRange.length];
		NSInteger number = [substring integerValue];
		
		NSInteger index = [attributedString itemNumberInTextList:list atIndex:substringRange.location];
		
		XCTAssertEqual(number, index, @"Item number should match the text but doesn't for range %@", NSStringFromRange(substringRange));
	}];
}

#pragma mark - Links

- (void)testLinkRange
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<p>some <a href=\"http://www.cocoanetics.com\">li<b>nk</b></a> text</p>" options:NULL];
	
	NSRange innerRange = [[attributedString string] rangeOfString:@"link"];
	
	// test inside
	NSURL *foundURL = nil;
	NSRange linkRange = [attributedString rangeOfLinkAtIndex:innerRange.location URL:&foundURL];
	
	XCTAssertNotNil(foundURL, @"No link found inside");
	
	if (foundURL)
	{
		XCTAssertTrue([[foundURL absoluteString] isEqualToString:@"http://www.cocoanetics.com"], @"found URL invalid");
	}
	
	XCTAssertTrue(NSEqualRanges(linkRange, innerRange), @"Link should enclose inner text");
	
	
	// test outside before
	foundURL = nil;
	linkRange = [attributedString rangeOfLinkAtIndex:innerRange.location-1 URL:&foundURL];
	
	XCTAssertNil(foundURL, @"There should be no link before");
	NSRange expectedRange = NSMakeRange(NSNotFound, 0);
	
	XCTAssertTrue(NSEqualRanges(linkRange, expectedRange), @"range should not found range");

	// test outside after
	foundURL = nil;
	linkRange = [attributedString rangeOfLinkAtIndex:NSMaxRange(innerRange) URL:&foundURL];
	
	XCTAssertNil(foundURL, @"There should be no link after");
	expectedRange = NSMakeRange(NSNotFound, 0);
	
	XCTAssertTrue(NSEqualRanges(linkRange, expectedRange), @"range should not found range");
}

@end
