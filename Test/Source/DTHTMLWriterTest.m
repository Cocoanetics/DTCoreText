//
//  DTHTMLWriterTest.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 11.07.13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTHTMLWriterTest.h"

@implementation DTHTMLWriterTest


#pragma mark - Helpers

- (void)_testListIndentRoundTripFromHTML:(NSString *)HTML fragmentMode:(BOOL)fragmentMode
{
	NSAttributedString *string1 = [self attributedStringFromHTMLString:HTML options:nil];
	
	
	// generate html
	DTHTMLWriter *writer1 = [[DTHTMLWriter alloc] initWithAttributedString:string1];
	NSString *html1;
	
	if (fragmentMode)
	{
		html1 = [writer1 HTMLFragment];
	}
	else
	{
		html1 = [writer1 HTMLString];
	}
	
	NSAttributedString *string2 = [self attributedStringFromHTMLString:html1 options:nil];
	
	BOOL stringsHaveSameLength = [string1 length] == [string2 length];
	
	XCTAssertTrue(stringsHaveSameLength, @"Roundtripped string should be of equal length, but string1 is %ld, string2 is %ld", (long)[string1 length], (long)[string2 length]);
	
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
		
		XCTAssertTrue(equal, @"Paragraph Styles in range %@ should be equal", NSStringFromRange(substringRange));
		
		NSRange prefixRange;
		NSString *prefix1 = [string1 attribute:DTListPrefixField atIndex:substringRange.location effectiveRange:&prefixRange];
		NSString *prefix2 = [attributes1 objectForKey:DTListPrefixField];
		
		XCTAssertEqualObjects(prefix1, prefix2, @"List prefix fields should be equal in range %@", NSStringFromRange(substringRange));
		
		NSArray *lists1 = [attributes1 objectForKey:DTTextListsAttribute];
		NSArray *lists2 = [attributes2 objectForKey:DTTextListsAttribute];
		
		BOOL sameNumberOfLists = [lists1 count] == [lists2 count];
		
		XCTAssertTrue(sameNumberOfLists, @"Should be same number of lists");
		
		if (sameNumberOfLists)
		{
			// compare the individual lists, they are not identical, but should be equal
			for (NSUInteger index = 0; index<[lists1 count]; index++)
			{
				DTCSSListStyle *list1 = [lists1 objectAtIndex:index];
				DTCSSListStyle *list2 = [lists2 objectAtIndex:index];
				
				XCTAssertTrue([list1 isEqualToListStyle:list2], @"List Style at index %ld is not equal", (long)index);
			}
		}
		
		if (NSMaxRange(prefixRange) < NSMaxRange(enclosingRange))
		{
			attributes1 = [string1 attributesAtIndex:NSMaxRange(prefixRange) effectiveRange:NULL];
			attributes2 = [string2 attributesAtIndex:NSMaxRange(prefixRange) effectiveRange:NULL];
			
			paraStyle1 = [attributes1 paragraphStyle];
			paraStyle2 = [attributes2 paragraphStyle];
			
			equal = [paraStyle1 isEqual:paraStyle2];
			
			
			XCTAssertTrue(equal, @"Paragraph Styles following prefix in range %@ should be equal", NSStringFromRange(substringRange));
		}
	}];
}

#pragma mark - Color

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

	XCTAssertTrue(colorRange.location != NSNotFound,  @"html should contains background-color:#ffff00");
}

#pragma mark - List Output

- (void)testSimpleListRoundTrip
{
	NSString *HTML = @"<ul><li>fooo</li><li>fooo</li><li>fooo</li></ul>";
	
	[self _testListIndentRoundTripFromHTML:HTML fragmentMode:NO];
	[self _testListIndentRoundTripFromHTML:HTML fragmentMode:YES];
}

- (void)testSimpleListRoundTripWithTextScale
{
	CGFloat textSize = 32.0f;
	CGFloat textScale = 1.5f;
	
	//Artificially scale up the text size
	NSString *html = [NSString stringWithFormat:@"<ul style=\"-webkit-padding-start:%fpx;padding-left:%fpx;\"><li>fooo</li><li>fooo</li><li>fooo</li></ul>", (textSize * textScale), (textSize * textScale)];
	NSAttributedString *string = [self attributedStringFromHTMLString:html options:nil];

	DTHTMLWriter *writer = [[DTHTMLWriter alloc] initWithAttributedString:string];
	//Give the writer the artificial scale
	writer.textScale = textScale;
	NSString *writtenHTML = [writer HTMLFragment];
	
	XCTAssertTrue([writtenHTML rangeOfString:@"-webkit-padding-start:32px;padding-left:32px;"].location != NSNotFound, @"Text scale should not affect list indention amount");
}

- (void)testNestedListRoundTrip
{
	NSString *HTML = @"<ol><li>1a<ul><li>2a</li></ul></li><li>more</li><li>more</li></ol>";
	
	[self _testListIndentRoundTripFromHTML:HTML fragmentMode:NO];
	[self _testListIndentRoundTripFromHTML:HTML fragmentMode:YES];
}

- (void)testNestedListRoundTripWithPrecedingElement
{
	NSString *HTML = @"<p>This breaks writing nested lists</p><ol><li>1a<ul><li>2a</li></ul></li><li>more</li><li>more</li></ol>";
	
	[self _testListIndentRoundTripFromHTML:HTML fragmentMode:NO];
	[self _testListIndentRoundTripFromHTML:HTML fragmentMode:YES];
}

- (void)testNestedListWithPaddingRoundTrip
{
	NSString *HTML = @"<ul style=\"padding-left:55px\"><li>fooo<ul style=\"padding-left:66px\"><li>bar</li></ul></li></ul>";
	
	[self _testListIndentRoundTripFromHTML:HTML fragmentMode:NO];
	[self _testListIndentRoundTripFromHTML:HTML fragmentMode:YES];
}

- (void)testNestedListOutputWithoutTextNodeRoundTrip
{
	NSString *HTML = @"<ul>\n<li>\n<ol>\n<li>Foo</li>\n<li>Bar</li>\n</ol>\n</li>\n<li>BLAH</li>\n</ul>";
	
	[self _testListIndentRoundTripFromHTML:HTML fragmentMode:NO];
	[self _testListIndentRoundTripFromHTML:HTML fragmentMode:YES];
}

- (void)testNestedListOutput
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<ol><li>1a<ul><li>2a</li></ul></li></ol>" options:NULL];
	
	// generate html
	DTHTMLWriter *writer = [[DTHTMLWriter alloc] initWithAttributedString:attributedString];
	NSString* html = [[writer HTMLFragment] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	
	NSRange rangeLILI = [html rangeOfString:@"</li></ul></li></ol>"];
	XCTAssertTrue(rangeLILI.location != NSNotFound, @"List Items should be closed next to each other");
	
	NSRange rangeLIUL = [html rangeOfString:@"</li><ul"];
	XCTAssertTrue(rangeLIUL.location == NSNotFound, @"List Items should not be closed before UL");
	
	NSRange rangeSpanUL = [html rangeOfString:@"</span></ul"];
	XCTAssertTrue(rangeSpanUL.location == NSNotFound, @"Missing LI between span and UL");
}

- (void)testNestedListOutputWithoutTextNode
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<ul><li><ol><li>2a</li><li>2b</li></ol></li><li>1a</li></ul>" options:NULL];
	
	// generate html
	DTHTMLWriter *writer = [[DTHTMLWriter alloc] initWithAttributedString:attributedString];
	NSString* html = [[writer HTMLFragment] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	
	NSRange twoAOutsideOL = [html rangeOfString:@"2a</span><ol"];
	XCTAssertTrue(twoAOutsideOL.location == NSNotFound, @"List item 2a should not be outside the ordered list");
}

#pragma mark - Kerning

- (void)testKerning
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<h1 style=\"font-variant: small-caps; letter-spacing:10px\">one</h1>" options:NULL];
	
	// generate html
	DTHTMLWriter *writer = [[DTHTMLWriter alloc] initWithAttributedString:attributedString];
	NSString *html = [[writer HTMLFragment] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	
	NSRange letterSpacingRange = [html rangeOfString:@"letter-spacing:10px;"];
	XCTAssertTrue(letterSpacingRange.location != NSNotFound, @"Letter-spacing missing");
}

- (void)testKerningWithTextScale
{
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:3], NSTextSizeMultiplierDocumentOption, nil];
	
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<h1 style=\"font-variant: small-caps; letter-spacing:10px\">one</h1>" options:options];
	
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:NULL];
	CGFloat kerning = [attributes kerning];
	XCTAssertTrue(kerning == 30, @"Scaled up kerning should be 30");
	
	// generate html
	DTHTMLWriter *writer = [[DTHTMLWriter alloc] initWithAttributedString:attributedString];
	NSString *html = [[writer HTMLFragment] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	
	NSRange letterSpacingRange = [html rangeOfString:@"letter-spacing:10px;"];
	XCTAssertTrue(letterSpacingRange.location == NSNotFound, @"Letter-spacing missing");
}

#pragma mark - Link generation

/**
 * Text:       first second third
 * Link:             [----]
 */
- (void)testSingleLineAnchor
{
	NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@"first second third"];
	[attributedString addAttribute:DTAnchorAttribute value:@"nameValue" range:NSMakeRange(6, 6)]; // word "second"
	
	DTHTMLWriter *writer = [[DTHTMLWriter alloc] initWithAttributedString:attributedString];
	
	NSString *generatedHTMLFragment = [writer HTMLFragment];
	NSString *expectedHTMLFragment = [NSString stringWithFormat:
									  @"<span>"
									  "<span style=\"color:#000000;\">first </span>"
									  "<a name=\"nameValue\">"
									  "<span style=\"color:#000000;\">second</span>"
									  "</a>"
									  "<span style=\"color:#000000;\"> third</span>"
									  "</span>\n"];
	
	XCTAssertTrue([generatedHTMLFragment isEqualToString:expectedHTMLFragment], @"Strings are not equal %@ %@", expectedHTMLFragment, generatedHTMLFragment);
}

/**
 * Text:       single line blue link blue link
 * Background:             [------------]
 * Link:                        [--]
 */
- (void)testSingleLineAnchorWithBackgroundColorAround
{
	NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@"single line blue link blue link"];
	[attributedString addAttribute:DTAnchorAttribute value:@"nameValue" range:NSMakeRange(17, 4)]; // "link"
	DTColor *color = DTColorCreateWithHexString(@"0000FF");
	[attributedString addAttribute:DTBackgroundColorAttribute value:(id)color.CGColor range:NSMakeRange(12, 14)]; // "blue link blue"
	
	DTHTMLWriter *writer = [[DTHTMLWriter alloc] initWithAttributedString:attributedString];
	
	NSString *generatedHTMLFragment = [writer HTMLFragment];
	NSString *expectedHTMLFragment = [NSString stringWithFormat:
									  @"<span>"
									  "<span style=\"color:#000000;\">single line </span>"
									  "<span style=\"color:#000000;background-color:#0000ff;\">blue </span>"
									  "<a name=\"nameValue\">"
									  "<span style=\"color:#000000;background-color:#0000ff;\">link</span>"
									  "</a>"
									  "<span style=\"color:#000000;background-color:#0000ff;\"> blue</span>"
									  "<span style=\"color:#000000;\"> link</span>"
									  "</span>\n"];
	
	XCTAssertTrue([generatedHTMLFragment isEqualToString:expectedHTMLFragment], @"Strings are not equal %@ %@", expectedHTMLFragment, generatedHTMLFragment);
}

/**
 * Text:       111222333444
 * Background:    [-----]
 * Link:         [-----]
 */
- (void)testSingleLineAnchorWithBackgroundColorAround2
{
	DTColor *backgroundColor = DTColorCreateWithHexString(@"9b57b5");
	
	NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@"111222333444"];
	[attributedString addAttribute:DTBackgroundColorAttribute value:(id)backgroundColor.CGColor range:NSMakeRange(3, 7)];
	[attributedString addAttribute:DTAnchorAttribute value:@"nameAttribute" range:NSMakeRange(2, 7)];
	
	DTHTMLWriter *writer = [[DTHTMLWriter alloc] initWithAttributedString:attributedString];
	
	NSString *generatedHTMLFragment = [writer HTMLFragment];
	NSString *expectedHTMLFragment = [NSString stringWithFormat:
									  @"<span>"
									  "<span style=\"color:#000000;\">11</span>"
									  "<a name=\"nameAttribute\">"
									  "<span style=\"color:#000000;\">1</span>"
									  "<span style=\"color:#000000;background-color:#9b57b5;\">222333</span>"
									  "</a>"
									  "<span style=\"color:#000000;background-color:#9b57b5;\">4</span>"
									  "<span style=\"color:#000000;\">44</span>"
									  "</span>\n"];
	
	XCTAssertTrue([generatedHTMLFragment isEqualToString:expectedHTMLFragment], @"Strings are not equal %@ %@", expectedHTMLFragment, generatedHTMLFragment);
}

/**
 * Text:       111222333444
 * Background:   [-----]
 * Link:          [-----]
 */
- (void)testSingleLineAnchorWithBackgroundColorAround3
{
	DTColor *backgroundColor = DTColorCreateWithHexString(@"9b57b5");
	
	NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@"111222333444"];
	[attributedString addAttribute:DTBackgroundColorAttribute value:(id)backgroundColor.CGColor range:NSMakeRange(2, 7)];
	[attributedString addAttribute:DTAnchorAttribute value:@"nameAttribute" range:NSMakeRange(3, 7)];
	
	DTHTMLWriter *writer = [[DTHTMLWriter alloc] initWithAttributedString:attributedString];
	
	NSString *generatedHTMLFragment = [writer HTMLFragment];
	NSString *expectedHTMLFragment = [NSString stringWithFormat:
									  @"<span>"
									  "<span style=\"color:#000000;\">11</span>"
									  "<span style=\"color:#000000;background-color:#9b57b5;\">1</span>"
									  "<a name=\"nameAttribute\">"
									  "<span style=\"color:#000000;background-color:#9b57b5;\">222333</span>"
									  "<span style=\"color:#000000;\">4</span>"
									  "</a>"
									  "<span style=\"color:#000000;\">44</span>"
									  "</span>\n"];
	
	XCTAssertTrue([generatedHTMLFragment isEqualToString:expectedHTMLFragment], @"Strings are not equal %@ %@", expectedHTMLFragment, generatedHTMLFragment);
}

/**
 * Text:       first line\nsecond line\nthird line
 * Link:       [---------------------]
 */
- (void)testMultiLineAnchor
{
	NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@"first line\nsecond line\nthird line"];
	[attributedString addAttribute:DTAnchorAttribute value:@"nameValue" range:NSMakeRange(0, 22)]; // first and second line
	
	DTHTMLWriter *writer = [[DTHTMLWriter alloc] initWithAttributedString:attributedString];
	
	NSString *generatedHTMLFragment = [writer HTMLFragment];
	NSString *expectedHTMLFragment = [NSString stringWithFormat:
									  @"<p>"
									  "<a name=\"nameValue\">"
									  "<span style=\"color:#000000;\">first line</span>"
									  "</a>"
									  "</p>\n"
									  "<p>"
									  "<a name=\"nameValue\">"
									  "<span style=\"color:#000000;\">second line</span>"
									  "</a>"
									  "</p>\n"
									  "<span>"
									  "<span style=\"color:#000000;\">third line</span>"
									  "</span>\n"];
	
	XCTAssertTrue([generatedHTMLFragment isEqualToString:expectedHTMLFragment], @"Strings are not equal %@ %@", expectedHTMLFragment, generatedHTMLFragment);
}

/**
 * Text:       single line blue newline\nlink blue link
 * Background:             [---------------------]
 * Link:                        [-----------]
 */
- (void)testMultiLineAnchorWithBackgroundColorAround
{
	NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@"single line blue newline\nlink blue link"];
	[attributedString addAttribute:DTAnchorAttribute value:@"nameValue" range:NSMakeRange(17, 12)]; // "link"
	DTColor *color = DTColorCreateWithHexString(@"0000FF");
	[attributedString addAttribute:DTBackgroundColorAttribute value:(id)color.CGColor range:NSMakeRange(12, 22)]; // "blue link blue"
	
	DTHTMLWriter *writer = [[DTHTMLWriter alloc] initWithAttributedString:attributedString];
	
	NSString *generatedHTMLFragment = [writer HTMLFragment];
	NSString *expectedHTMLFragment = [NSString stringWithFormat:
									  @"<p>"
									  "<span style=\"color:#000000;\">single line </span>"
									  "<span style=\"color:#000000;background-color:#0000ff;\">blue </span>"
									  "<a name=\"nameValue\">"
									  "<span style=\"color:#000000;background-color:#0000ff;\">newline</span>"
									  "</a>"
									  "</p>\n"
									  "<span>"
									  "<a name=\"nameValue\">"
									  "<span style=\"color:#000000;background-color:#0000ff;\">link</span>"
									  "</a>"
									  "<span style=\"color:#000000;background-color:#0000ff;\"> blue</span>"
									  "<span style=\"color:#000000;\"> link</span>"
									  "</span>\n"];
	
	XCTAssertTrue([generatedHTMLFragment isEqualToString:expectedHTMLFragment], @"Strings are not equal %@ %@", expectedHTMLFragment, generatedHTMLFragment);
}

/**
 * Text:       111\n222\n333\n444
 * Background:   [------------]
 * Link:           [-------]
 */
- (void)testMultiLineAnchorWithExtendedBackgroundColorAround {
	DTColor *backgroundColor = DTColorCreateWithHexString(@"9b57b5");
	
	NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@"111\n222\n333\n444"];
	[attributedString addAttribute:DTBackgroundColorAttribute value:(id)backgroundColor.CGColor range:NSMakeRange(2, 11)];
	[attributedString addAttribute:DTAnchorAttribute value:@"nameAttribute" range:NSMakeRange(4, 7)];
	
	DTHTMLWriter *writer = [[DTHTMLWriter alloc] initWithAttributedString:attributedString];
	
	NSString *generatedHTMLFragment = [writer HTMLFragment];
	NSString *expectedHTMLFragment = [NSString stringWithFormat:
									  @"<p>"
									  "<span style=\"color:#000000;\">11</span>"
									  "<span style=\"color:#000000;background-color:#9b57b5;\">1</span>"
									  "</p>\n"
									  "<p>"
									  "<a name=\"nameAttribute\">"
									  "<span style=\"color:#000000;background-color:#9b57b5;\">222</span>"
									  "</a>"
									  "</p>\n"
									  "<p>"
									  "<a name=\"nameAttribute\">"
									  "<span style=\"color:#000000;background-color:#9b57b5;\">333</span>"
									  "</a>"
									  "</p>\n"
									  "<span>"
									  "<span style=\"color:#000000;background-color:#9b57b5;\">4</span>"
									  "<span style=\"color:#000000;\">44</span>"
									  "</span>\n"];
	
	XCTAssertTrue([generatedHTMLFragment isEqualToString:expectedHTMLFragment], @"Strings are not equal %@ %@", expectedHTMLFragment, generatedHTMLFragment);
}

/**
 * Text:       111\n222\n333\n444
 * Background:       [---]
 * Link:              [---]
 */
- (void)testMultiLineAnchorWithExtendedBackgroundColorAround2
{
	DTColor *backgroundColor = DTColorCreateWithHexString(@"9b57b5");
	
	NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@"111\n222\n333\n444"];
	[attributedString addAttribute:DTBackgroundColorAttribute value:(id)backgroundColor.CGColor range:NSMakeRange(5, 4)];
	[attributedString addAttribute:DTAnchorAttribute value:@"nameAttribute" range:NSMakeRange(6, 4)];
	
	DTHTMLWriter *writer = [[DTHTMLWriter alloc] initWithAttributedString:attributedString];
	
	NSString *generatedHTMLFragment = [writer HTMLFragment];
	NSString *expectedHTMLFragment = [NSString stringWithFormat:
									  @"<p>"
									  "<span style=\"color:#000000;\">111</span>"
									  "</p>\n"
									  "<p>"
									  "<span style=\"color:#000000;\">2</span>"
									  "<span style=\"color:#000000;background-color:#9b57b5;\">2</span>"
									  "<a name=\"nameAttribute\">"
									  "<span style=\"color:#000000;background-color:#9b57b5;\">2</span>"
									  "</a>"
									  "</p>\n"
									  "<p>"
									  "<a name=\"nameAttribute\">"
									  "<span style=\"color:#000000;background-color:#9b57b5;\">3</span>"
									  "<span style=\"color:#000000;\">3</span>"
									  "</a>"
									  "<span style=\"color:#000000;\">3</span>"
									  "</p>\n"
									  "<span>"
									  "<span style=\"color:#000000;\">444</span>"
									  "</span>\n"];
	
	XCTAssertTrue([generatedHTMLFragment isEqualToString:expectedHTMLFragment], @"Strings are not equal %@ %@", expectedHTMLFragment, generatedHTMLFragment);
}

/**
 * Text:       111\n222\n333\n444
 * Background:        [---]
 * Link:             [---]
 */
- (void)testMultiLineAnchorWithExtendedBackgroundColorAround3 {
	DTColor *backgroundColor = DTColorCreateWithHexString(@"9b57b5");
	
	NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@"111\n222\n333\n444"];
	[attributedString addAttribute:DTBackgroundColorAttribute value:(id)backgroundColor.CGColor range:NSMakeRange(6, 4)];
	[attributedString addAttribute:DTAnchorAttribute value:@"nameAttribute" range:NSMakeRange(5, 4)];
	
	DTHTMLWriter *writer = [[DTHTMLWriter alloc] initWithAttributedString:attributedString];
	
	NSString *generatedHTMLFragment = [writer HTMLFragment];
	NSString *expectedHTMLFragment = [NSString stringWithFormat:
									  @"<p>"
									  "<span style=\"color:#000000;\">111</span>"
									  "</p>\n"
									  "<p>"
									  "<span style=\"color:#000000;\">2</span>"
									  "<a name=\"nameAttribute\">"
									  "<span style=\"color:#000000;\">2</span>"
									  "<span style=\"color:#000000;background-color:#9b57b5;\">2</span>"
									  "</a>"
									  "</p>\n"
									  "<p>"
									  "<a name=\"nameAttribute\">"
									  "<span style=\"color:#000000;background-color:#9b57b5;\">3</span>"
									  "</a>"
									  "<span style=\"color:#000000;background-color:#9b57b5;\">3</span>"
									  "<span style=\"color:#000000;\">3</span>"
									  "</p>\n"
									  "<span>"
									  "<span style=\"color:#000000;\">444</span>"
									  "</span>\n"];
	
	XCTAssertTrue([generatedHTMLFragment isEqualToString:expectedHTMLFragment], @"Strings are not equal %@ %@", expectedHTMLFragment, generatedHTMLFragment);
}
@end
