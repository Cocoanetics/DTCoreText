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
	
- (void)_testListIndentRoundTripFromHTML:(NSString *)HTML
{
	NSAttributedString *string1 = [self attributedStringFromHTMLString:HTML options:nil];
	
	// generate html
	DTHTMLWriter *writer1 = [[DTHTMLWriter alloc] initWithAttributedString:string1];
	NSString* html1 = [writer1 HTMLFragment];
	
	NSAttributedString *string2 = [self attributedStringFromHTMLString:html1 options:nil];
	
	STAssertTrue([string1 length] == [string2 length], @"Roundtripped string should be of equal length");

	[[string1 string] enumerateSubstringsInRange:NSMakeRange(0, [string1 length]) options:NSStringEnumerationByParagraphs usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
		
		NSDictionary *attributes1 = [string1 attributesAtIndex:substringRange.location effectiveRange:NULL];
		NSDictionary *attributes2 = [string2 attributesAtIndex:substringRange.location effectiveRange:NULL];
		
		DTCoreTextParagraphStyle *paraStyle1 = [attributes1 paragraphStyle];
		DTCoreTextParagraphStyle *paraStyle2 = [attributes2 paragraphStyle];
		
		BOOL equal = [paraStyle1 isEqual:paraStyle2];
		
		if (!equal)
		{
			NSLog(@"Hier");
		}
		
		STAssertTrue(equal, @"Paragraph Styles in range %@ should be equal", NSStringFromRange(substringRange));
		
		NSRange prefixRange;
		NSString *prefix1 = [string1 attribute:DTListPrefixField atIndex:substringRange.location effectiveRange:&prefixRange];
		NSString *prefix2 = [attributes1 objectForKey:DTListPrefixField];
		
		STAssertEqualObjects(prefix1, prefix2, @"List prefix fields should be equal in range %@", NSStringFromRange(substringRange));
		
		NSArray *lists1 = [attributes1 objectForKey:DTTextListsAttribute];
		NSArray *lists2 = [attributes2 objectForKey:DTTextListsAttribute];
		
		STAssertEqualObjects(lists1, lists2, @"Lists should be equal in range %@", NSStringFromRange(substringRange));
		
		
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


// --- needs fix for nested list writing first, the first LI gets closed before the UL opening
- (void)testNestedListRoundTrip
{
	[self _testListIndentRoundTripFromHTML:@"<ol><li>1a<ul><li>2a</li></ul></li><li>more</li><li>more</li></ol>"];
}


- (void)testNestedListWithPaddingRoundTrip
{
	[self _testListIndentRoundTripFromHTML:@"<ul style=\"padding-left:55px\"><li>fooo<ul style=\"padding-left:66px\"><li>bar</li></ul></li></ul>"];
}

#pragma mark - List Output

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

@end
