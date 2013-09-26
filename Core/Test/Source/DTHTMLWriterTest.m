//
//  DTHTMLWriterTest.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 11.07.13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTHTMLWriterTest.h"
#import "DTCoreText.h"
#import "DTColorFunctions.h"

@implementation DTHTMLWriterTest



#pragma mark - Tests

- (void)testBackgroundColor
{
	// create attributed string
	NSMutableAttributedString* attributedText = [[NSMutableAttributedString alloc] initWithString:@"Hello World"];
	NSRange range = [attributedText.string rangeOfString:@"World"];
	if (range.location != NSNotFound)
	{
		DTColor *color = DTColorCreateWithHexString(@"FFFF00");
		
		[attributedText addAttribute:DTBackgroundColorAttribute value:(id)color.CGColor range:range];
	}
	
	// generate html
	DTHTMLWriter *writer = [[DTHTMLWriter alloc] initWithAttributedString:attributedText];
	writer.useAppleConvertedSpace = NO;
	NSString *html = [writer HTMLFragment];
	
	NSRange colorRange = [html rangeOfString:@"background-color:#ffff00"];

	STAssertTrue(colorRange.location != NSNotFound,  @"html should contains background-color:#ffff00");
}

#pragma mark - List Output

- (void)_testListIndentRoundTripFromHTML:(NSString *)HTML
{
	NSAttributedString *string1 = [self attributedStringFromHTMLString:HTML options:nil];
	
	
	// generate html
	DTHTMLWriter *writer1 = [[DTHTMLWriter alloc] initWithAttributedString:string1];
	NSString* html1 = [writer1 HTMLFragment];
	
	NSAttributedString *string2 = [self attributedStringFromHTMLString:html1 options:nil];
	
	BOOL stringsHaveSameLength = [string1 length] == [string2 length];
	
	STAssertTrue(stringsHaveSameLength, @"Roundtripped string should be of equal length, but string1 is %d, string2 is %d", [string1 length], [string2 length]);

	if (!stringsHaveSameLength)
	{
		return;
	}
	
	[[string1 string] enumerateSubstringsInRange:NSMakeRange(0, [string1 length]) options:NSStringEnumerationByParagraphs usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
		
		NSDictionary *attributes1 = [string1 attributesAtIndex:substringRange.location effectiveRange:NULL];
		NSDictionary *attributes2 = [string2 attributesAtIndex:substringRange.location effectiveRange:NULL];
		
		DTCoreTextParagraphStyle *paraStyle1 = [attributes1 paragraphStyle];
		DTCoreTextParagraphStyle *paraStyle2 = [attributes2 paragraphStyle];
		
		BOOL equal = [paraStyle1 isEqual:paraStyle2];
		
//		if (!equal)
//		{
//			NSLog(@"html input: ================ \n%@", HTML);
//			NSLog(@"string1: ================ \n%@", string1);
//			NSLog(@"html input2: ================ \n%@", html1);
//			NSLog(@"string2: ================ \n%@ \n ================", string2);
//		}
		
		STAssertTrue(equal, @"Paragraph Styles in range %@ should be equal", NSStringFromRange(substringRange));
		
		NSRange prefixRange;
		NSString *prefix1 = [string1 attribute:DTListPrefixField atIndex:substringRange.location effectiveRange:&prefixRange];
		NSString *prefix2 = [attributes1 objectForKey:DTListPrefixField];
		
		STAssertEqualObjects(prefix1, prefix2, @"List prefix fields should be equal in range %@", NSStringFromRange(substringRange));
		
		NSArray *lists1 = [attributes1 objectForKey:DTTextListsAttribute];
		NSArray *lists2 = [attributes2 objectForKey:DTTextListsAttribute];
		
		BOOL sameNumberOfLists = [lists1 count] == [lists2 count];
		
		STAssertTrue(sameNumberOfLists, @"Should be same number of lists");
		
		if (sameNumberOfLists)
		{
			// compare the individual lists, they are not identical, but should be equal
			for (NSUInteger index = 0; index<[lists1 count]; index++)
			{
				DTCSSListStyle *list1 = [lists1 objectAtIndex:index];
				DTCSSListStyle *list2 = [lists2 objectAtIndex:index];
				
				STAssertTrue([list1 isEqualToListStyle:list2], @"List Style at index %d is not equal", index);
			}
		}
			
		if (NSMaxRange(prefixRange) < NSMaxRange(enclosingRange))
		{
			attributes1 = [string1 attributesAtIndex:NSMaxRange(prefixRange) effectiveRange:NULL];
			attributes2 = [string2 attributesAtIndex:NSMaxRange(prefixRange) effectiveRange:NULL];
			
			paraStyle1 = [attributes1 paragraphStyle];
			paraStyle2 = [attributes2 paragraphStyle];
			
			equal = [paraStyle1 isEqual:paraStyle2];
			
			
			STAssertTrue(equal, @"Paragraph Styles following prefix in range %@ should be equal", NSStringFromRange(substringRange));
		}
	}];
}

- (void)testSimpleListRoundTrip
{
	[self _testListIndentRoundTripFromHTML:@"<ul><li>fooo</li><li>fooo</li><li>fooo</li></ul>"];
}

- (void)testNestedListRoundTrip
{
	[self _testListIndentRoundTripFromHTML:@"<ol><li>1a<ul><li>2a</li></ul></li><li>more</li><li>more</li></ol>"];
}

- (void)testNestedListWithPaddingRoundTrip
{
	[self _testListIndentRoundTripFromHTML:@"<ul style=\"padding-left:55px\"><li>fooo<ul style=\"padding-left:66px\"><li>bar</li></ul></li></ul>"];
}

- (void)testNestedListOutputWithoutTextNodeRoundTrip
{
	[self _testListIndentRoundTripFromHTML:@"<ul>\n<li>\n<ol>\n<li>Foo</li>\n<li>Bar</li>\n</ol>\n</li>\n<li>BLAH</li>\n</ul>"];
}

- (void)testNestedListOutput
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<ol><li>1a<ul><li>2a</li></ul></li></ol>" options:NULL];
	
	// generate html
	DTHTMLWriter *writer = [[DTHTMLWriter alloc] initWithAttributedString:attributedString];
	NSString* html = [[writer HTMLFragment] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	
	NSRange rangeLILI = [html rangeOfString:@"</li></ul></li></ol>"];
	STAssertTrue(rangeLILI.location != NSNotFound, @"List Items should be closed next to each other");
	
	NSRange rangeLIUL = [html rangeOfString:@"</li><ul"];
	STAssertTrue(rangeLIUL.location == NSNotFound, @"List Items should not be closed before UL");
	
	NSRange rangeSpanUL = [html rangeOfString:@"</span></ul"];
	STAssertTrue(rangeSpanUL.location == NSNotFound, @"Missing LI between span and UL");
}

- (void)testNestedListOutputWithoutTextNode
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<ul><li><ol><li>2a</li><li>2b</li></ol></li><li>1a</li></ul>" options:NULL];
	
	// generate html
	DTHTMLWriter *writer = [[DTHTMLWriter alloc] initWithAttributedString:attributedString];
	NSString* html = [[writer HTMLFragment] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	
	NSRange twoAOutsideOL = [html rangeOfString:@"2a</span><ol"];
	STAssertTrue(twoAOutsideOL.location == NSNotFound, @"List item 2a should not be outside the ordered list");
}

@end
