//
//  DTHTMLAttributedStringBuilderTest.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 25.12.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTHTMLAttributedStringBuilderTest.h"

@implementation DTHTMLAttributedStringBuilderTest

#pragma mark - Utilities

- (NSRange)_effectiveRangeOfFontAtIndex:(NSUInteger)index inAttributedString:(NSAttributedString *)attributedString font:(CTFontRef *)font
{
	NSRange totalEffectiveRange = NSMakeRange(index, 0);
	CTFontRef searchFont = NULL;
	
	while (index < [attributedString length])
	{
		NSRange range;
		CTFontRef foundFont = (__bridge CTFontRef)([attributedString attribute:(id)kCTFontAttributeName atIndex:index effectiveRange:&range]);
		
		if (searchFont)
		{
			if (searchFont != foundFont)
			{
				break;
			}
		}
		else
		{
			searchFont = foundFont;
		}
		
		totalEffectiveRange = NSUnionRange(totalEffectiveRange, range);
		
		index = NSMaxRange(range);
	}
	
	if (font)
	{
		*font = searchFont;
	}
	
	return totalEffectiveRange;
}

#pragma mark - Whitespace

- (void)testSpaceBetweenUnderlines
{
	NSAttributedString *output = [self attributedStringFromTestFileName:@"SpaceBetweenUnderlines"];
	
	NSRange range_a;
	NSNumber *underLine = [output attribute:(id)kCTUnderlineStyleAttributeName atIndex:1 effectiveRange:&range_a];
	
	XCTAssertTrue([underLine integerValue]==0, @"Space between a and b should not be underlined");
}

// a block following an inline image should only cause a \n after the image, not whitespace
- (void)testWhitspaceAfterParagraphPromotedImage
{
	NSAttributedString *output = [self attributedStringFromTestFileName:@"WhitespaceFollowingImagePromotedToParagraph"];
	
	XCTAssertTrue([output length]==6, @"Generated String should be 6 characters");
	
	NSMutableString *expectedOutput = [NSMutableString stringWithFormat:@"1\n%@\n2\n", UNICODE_OBJECT_PLACEHOLDER];
	
	XCTAssertTrue([expectedOutput isEqualToString:[output string]], @"Expected output not matching");
}

// This should come out as Keep_me_together with the _ being non-breaking spaces
- (void)testKeepMeTogether
{
	NSAttributedString *output = [self attributedStringFromTestFileName:@"KeepMeTogether"];
	
	NSString *expectedOutput = @"Keep\u00a0me\u00a0together";
	
	XCTAssertTrue([expectedOutput isEqualToString:[output string]], @"Expected output not matching");
}

// issue 466: Support Encoding of Tabs in HTML
- (void)testTabDecodingAndPreservation
{
	NSAttributedString *output = [self attributedStringFromHTMLString:@"Some text and then 2 encoded<span style=\"white-space:pre\">&#9;&#9</span>tabs and 2 non-encoded		tabs" options:nil];
	
	NSString *plainString = [output string];
	NSRange range = [plainString rangeOfString:@"encoded"];
	
	XCTAssertTrue(range.location != NSNotFound, @"Should find 'encoded' in the string");
	
	NSString *tabs = [plainString substringWithRange:NSMakeRange(range.location+range.length, 2)];
	
	BOOL hasTabs = [tabs isEqualToString:@"\t\t"];
	
	XCTAssertTrue(hasTabs, @"There should be two tabs");
	
	range = [plainString rangeOfString:@"non-encoded"];
	NSString *compressedTabs = [plainString substringWithRange:NSMakeRange(range.location+range.length, 2)];
	
	BOOL hasCompressed = [compressedTabs isEqualToString:@" t"];
	
	XCTAssertTrue(hasCompressed, @"The second two tabs should be compressed to a single whitespace");
}

// issue 588: P inside LI
- (void)testParagraphInsideListItem
{
	NSAttributedString *output = [self attributedStringFromHTMLString:@"<ul><li><p>First Item</p></li></ul>" options:nil];
	NSString *plainText = [output string];
	
	NSRange firstRange = [plainText rangeOfString:@"First"];
	
	XCTAssertTrue(firstRange.location>0, @"Location should be greater than 0");
	
	NSString *characterBeforeFirstRange = [plainText substringWithRange:NSMakeRange(firstRange.location-1, 1)];
	
	XCTAssertTrue([characterBeforeFirstRange isEqualToString:@"\t"], @"Character before First should be tab");
	XCTAssertTrue(![characterBeforeFirstRange isEqualToString:@"\n"], @"Character before First should not be \n");
}

// issue 617: extra \n causes paragraph break
- (void)testSuperfluousParagraphBreakAfterBR
{
	NSAttributedString *output = [self attributedStringFromHTMLString:@"<h1 style=\"font-variant: small-caps;\">one<br>\n\ttwo</h1>" options:nil];
	NSString *plainText = [output string];
	
	NSRange twoRange = [plainText rangeOfString:@"TWO"];
	
	NSString *charBeforeTwo = [plainText substringWithRange:NSMakeRange(twoRange.location-1, 1)];
	
	XCTAssertFalse([charBeforeTwo isEqualToString:@"\n"], @"Superfluous NL following BR");
}

#pragma mark - General Tests

// tests functionality of dir attribute
- (void)testWritingDirection
{
	NSAttributedString *output = [self attributedStringFromHTMLString:@"<p dir=\"rtl\">rtl</p><p dir=\"ltr\">ltr</p><p>normal</p>" options:nil];
	
	CTParagraphStyleRef paragraphStyleRTL = (__bridge CTParagraphStyleRef)([output attribute:(id)kCTParagraphStyleAttributeName atIndex:0 effectiveRange:NULL]);
	DTCoreTextParagraphStyle *styleRTL = [DTCoreTextParagraphStyle paragraphStyleWithCTParagraphStyle:paragraphStyleRTL];
	
	XCTAssertTrue(styleRTL.baseWritingDirection == NSWritingDirectionRightToLeft, @"Writing direction is not RTL");
	
	CTParagraphStyleRef paragraphStyleLTR = (__bridge CTParagraphStyleRef)([output attribute:(id)kCTParagraphStyleAttributeName atIndex:4 effectiveRange:NULL]);
	DTCoreTextParagraphStyle *styleLTR = [DTCoreTextParagraphStyle paragraphStyleWithCTParagraphStyle:paragraphStyleLTR];
	
	XCTAssertTrue(styleLTR.baseWritingDirection == NSWritingDirectionLeftToRight, @"Writing direction is not LTR");

	CTParagraphStyleRef paragraphStyleNatural = (__bridge CTParagraphStyleRef)([output attribute:(id)kCTParagraphStyleAttributeName atIndex:8 effectiveRange:NULL]);
	DTCoreTextParagraphStyle *styleNatural = [DTCoreTextParagraphStyle paragraphStyleWithCTParagraphStyle:paragraphStyleNatural];
	
	XCTAssertTrue(styleNatural.baseWritingDirection == NSWritingDirectionNatural, @"Writing direction is not Natural");
}



// parser should get the displaySize and originalSize from local image
- (void)testAttachmentDisplaySize
{
	NSString *string = [NSString stringWithFormat:@"<img src=\"Oliver.jpg\" style=\"foo:bar\">"];
	NSAttributedString *output = [self attributedStringFromHTMLString:string options:nil];

	XCTAssertEqual([output length],(NSUInteger)1 , @"Output length should be 1");

	DTTextAttachment *attachment = [output attribute:NSAttachmentAttributeName atIndex:0 effectiveRange:NULL];
	
	XCTAssertNotNil(attachment, @"No attachment found in output");
	
	CGSize expectedSize = CGSizeMake(150, 150);
	XCTAssertTrue(CGSizeEqualToSize(attachment.originalSize, expectedSize), @"Non-expected originalSize");
	XCTAssertTrue(CGSizeEqualToSize(attachment.displaySize, expectedSize), @"Non-expected displaySize");
}

// parser should ignore "auto" value for height
- (void)testAttachmentAutoSize
{
	NSString *string = [NSString stringWithFormat:@"<img src=\"Oliver.jpg\" style=\"width:260px; height:auto;\">"];
	NSAttributedString *output = [self attributedStringFromHTMLString:string options:nil];
	
	XCTAssertEqual([output length],(NSUInteger)1 , @"Output length should be 1");
	
	DTTextAttachment *attachment = [output attribute:NSAttachmentAttributeName atIndex:0 effectiveRange:NULL];
	
	XCTAssertNotNil(attachment, @"No attachment found in output");
	
	CGSize expectedOriginalSize = CGSizeMake(150, 150);
	CGSize expectedDisplaySize = CGSizeMake(260, 260);
	
	XCTAssertTrue(CGSizeEqualToSize(attachment.originalSize, expectedOriginalSize), @"Non-expected originalSize");
	XCTAssertTrue(CGSizeEqualToSize(attachment.displaySize, expectedDisplaySize), @"Non-expected displaySize");
}

// parser should recover from no end element being sent for this img
- (void)testMissingClosingBracket
{
	NSString *string = [NSString stringWithFormat:@"<img src=\"Oliver.jpg\""];
	NSAttributedString *output = [self attributedStringFromHTMLString:string options:nil];
	
	XCTAssertEqual([output length],(NSUInteger)1 , @"Output length should be 1");
	
	DTTextAttachment *attachment = [output attribute:NSAttachmentAttributeName atIndex:0 effectiveRange:NULL];
	
	XCTAssertNotNil(attachment, @"No attachment found in output");
}


- (void)testRTLParsing
{
	NSAttributedString *output = [self attributedStringFromTestFileName:@"RTL"];

	NSUInteger paraEndIndex;
	NSRange firstParagraphRange = [[output string] rangeOfParagraphsContainingRange:NSMakeRange(0, 0) parBegIndex:NULL parEndIndex:&paraEndIndex];
	XCTAssertTrue(NSEqualRanges(NSMakeRange(0, 22), firstParagraphRange), @"First Paragraph Range should be {0,14}");

	NSRange secondParagraphRange = [[output string] rangeOfParagraphsContainingRange:NSMakeRange(paraEndIndex, 0) parBegIndex:NULL parEndIndex:NULL];
	XCTAssertTrue(NSEqualRanges(NSMakeRange(22, 24), secondParagraphRange), @"Second Paragraph Range should be {14,14}");

	CTParagraphStyleRef firstParagraphStyle = (__bridge CTParagraphStyleRef)([output attribute:(id)kCTParagraphStyleAttributeName atIndex:firstParagraphRange.location effectiveRange:NULL]);
	CTParagraphStyleRef secondParagraphStyle = (__bridge CTParagraphStyleRef)([output attribute:(id)kCTParagraphStyleAttributeName atIndex:secondParagraphRange.location effectiveRange:NULL]);
	
	DTCoreTextParagraphStyle *firstParaStyle = [DTCoreTextParagraphStyle paragraphStyleWithCTParagraphStyle:firstParagraphStyle];
	DTCoreTextParagraphStyle *secondParaStyle = [DTCoreTextParagraphStyle paragraphStyleWithCTParagraphStyle:secondParagraphStyle];
	
	XCTAssertTrue(firstParaStyle.baseWritingDirection==kCTWritingDirectionRightToLeft, @"First Paragraph Style is not RTL");
	XCTAssertTrue(secondParaStyle.baseWritingDirection==kCTWritingDirectionRightToLeft, @"Second Paragraph Style is not RTL");
}

- (void)testEmptyParagraphAndFontAttribute
{
	NSAttributedString *output = [self attributedStringFromTestFileName:@"EmptyLinesAndFontAttribute"];
	
	NSUInteger paraEndIndex;
	NSRange firstParagraphRange = [[output string] rangeOfParagraphsContainingRange:NSMakeRange(0, 0) parBegIndex:NULL parEndIndex:&paraEndIndex];
	XCTAssertTrue(NSEqualRanges(NSMakeRange(0, 2), firstParagraphRange), @"First Paragraph Range should be {0,14}");
	
	NSRange secondParagraphRange = [[output string] rangeOfParagraphsContainingRange:NSMakeRange(paraEndIndex, 0) parBegIndex:NULL parEndIndex:&paraEndIndex];
	XCTAssertTrue(NSEqualRanges(NSMakeRange(2, 1), secondParagraphRange), @"Second Paragraph Range should be {14,14}");

	NSRange thirdParagraphRange = [[output string] rangeOfParagraphsContainingRange:NSMakeRange(paraEndIndex, 0) parBegIndex:NULL parEndIndex:NULL];
	XCTAssertTrue(NSEqualRanges(NSMakeRange(3, 1), thirdParagraphRange), @"Second Paragraph Range should be {14,14}");
	
	CTFontRef firstParagraphFont;
	NSRange firstParagraphFontRange = [self _effectiveRangeOfFontAtIndex:firstParagraphRange.location inAttributedString:output font:&firstParagraphFont];
	
	XCTAssertNotNil((__bridge id)firstParagraphFont, @"First paragraph font is missing");
	
	if (firstParagraphFont)
	{
		XCTAssertTrue(NSEqualRanges(firstParagraphRange, firstParagraphFontRange), @"Range Font in first paragraph is not full paragraph");
	}

	CTFontRef secondParagraphFont;
	NSRange secondParagraphFontRange = [self _effectiveRangeOfFontAtIndex:secondParagraphRange.location inAttributedString:output font:&secondParagraphFont];
	
	XCTAssertNotNil((__bridge id)secondParagraphFont, @"Second paragraph font is missing");
	
	if (secondParagraphFont)
	{
		XCTAssertTrue(NSEqualRanges(secondParagraphFontRange, secondParagraphRange), @"Range Font in second paragraph is not full paragraph");
	}
	
	CTFontRef thirdParagraphFont;
	NSRange thirdParagraphFontRange = [self _effectiveRangeOfFontAtIndex:thirdParagraphRange.location inAttributedString:output font:&thirdParagraphFont];
	
	XCTAssertNotNil((__bridge id)secondParagraphFont, @"Third paragraph font is missing");
	
	if (thirdParagraphFont)
	{
		XCTAssertTrue(NSEqualRanges(thirdParagraphFontRange, thirdParagraphRange), @"Range Font in third paragraph is not full paragraph");
	}
}

// if there is a text attachment contained in a HREF then the URL of that needs to be transferred to the image because it is needed for affixing a custom subview for a link button over the image or
- (void)testTransferOfHyperlinkURLToAttachment
{
	NSAttributedString *string = [self attributedStringFromHTMLString:@"<a href=\"https://www.cocoanetics.com\"><img class=\"Bla\" style=\"width:150px; height:150px\" src=\"Oliver.jpg\"></a>" options:nil];
	
	XCTAssertEqual([string length], (NSUInteger)1, @"Output length should be 1");
	
	// get the attachment
	DTTextAttachment *attachment = [string attribute:NSAttachmentAttributeName atIndex:0 effectiveRange:NULL];
	
	XCTAssertNotNil(attachment, @"Attachment is missing");
	
	// get the link
	NSURL *URL = [string attribute:DTLinkAttribute atIndex:0 effectiveRange:NULL];
	
	XCTAssertNotNil(URL, @"Element URL is nil");
	
	XCTAssertEqualObjects(URL, attachment.hyperLinkURL, @"Attachment URL and element URL should match!");
}


// setting ordered list starting number
- (void)testOrderedListStartingNumber
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<ol start=\"5\">\n<li>Item #5</li>\n<li>Item #6</li>\n<li>etc.</li>\n</ol>" options:nil];
	NSString *string = [attributedString string];
	
	NSArray *lines = [string componentsSeparatedByString:@"\n"];
	
	XCTAssertEqual([lines count], (NSUInteger)4, @"There should be 4 lines"); // last one is empty
	
	NSString *line1 = lines[0];
	XCTAssertTrue([line1 hasPrefix:@"\t5."], @"String should have prefix 5. on first item");
	
	NSString *line2 = lines[1];
	XCTAssertTrue([line2 hasPrefix:@"\t6."], @"String should have prefix 6. on third item");
	
	NSString *line3 = lines[2];
	XCTAssertTrue([line3 hasPrefix:@"\t7."], @"String should have prefix 7. on third item");
}

- (void)testHeaderLevelTransfer
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<h3>Header</h3>" options:nil];
	
	NSNumber *headerLevelNum = [attributedString attribute:DTHeaderLevelAttribute atIndex:0 effectiveRange:NULL];
	
	XCTAssertNotNil(headerLevelNum, @"No Header Level Attribute");

	NSInteger level = [headerLevelNum integerValue];
	
	XCTAssertEqual(level, (NSInteger)3, @"Level should be 3");
}

// Issue 437, strikethrough bleeding into NL
- (void)testBleedingOutAttributes
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<p><del>abc</del></p>" options:nil];
	
	XCTAssertTrue([attributedString length] == 4, @"Attributed String should be 4 characters long");
	
	NSRange effectiveRange;
	NSNumber *strikethroughStyle = [attributedString attribute:DTStrikeOutAttribute atIndex:0 effectiveRange:&effectiveRange];
	
	XCTAssertNotNil(strikethroughStyle, @"There should be a strikethrough style");
	
	NSRange expectedRange = NSMakeRange(0, 3);
	
	XCTAssertTrue(NSEqualRanges(effectiveRange, expectedRange), @"Strikethrough style should only contain abc, not the NL");
}

// Issue 441, display size ignored if img has width/height
- (void)testImageDisplaySize
{
	NSDictionary *options = @{DTMaxImageSize: [NSValue valueWithCGSize:CGSizeMake(200, 200)]};
	
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<img width=\"300\" height=\"300\" src=\"Oliver.jpg\">" options:options];
	
	XCTAssertTrue([attributedString length]==1, @"Output length should be 1");
	
	DTImageTextAttachment *imageAttachment = [attributedString attribute:NSAttachmentAttributeName atIndex:0 effectiveRange:NULL];
	
	CGSize expectedSize = CGSizeMake(200, 200);
	
	XCTAssertTrue(CGSizeEqualToSize(expectedSize, imageAttachment.displaySize), @"Expected size should be equal to display size");
}

#pragma mark - Horizontal Rules

// issue 740: HR inside block following newline are trimmed off
- (void)testHorizontalRulesInsideBlockquote
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<HR><BLOCKQUOTE><hr>one<hr><br>two<hr></BLOCKQUOTE><hr>" options:nil];
	
	// we expect 5 HR, two at the beginning and the end, one in the middle
	NSRange range;
	NSRange expectedRange = NSMakeRange(0, 1);
	BOOL isHR = [[attributedString attributesAtIndex:expectedRange.location effectiveRange:&range][DTHorizontalRuleStyleAttribute] boolValue];
	XCTAssertTrue(isHR, @"HR should be in range %@", NSStringFromRange(expectedRange));
	
	expectedRange = NSMakeRange(1, 1);
	isHR = [[attributedString attributesAtIndex:expectedRange.location effectiveRange:&range][DTHorizontalRuleStyleAttribute] boolValue];
	XCTAssertTrue(isHR, @"HR should be in range %@", NSStringFromRange(expectedRange));

	expectedRange = NSMakeRange(6, 1);
	isHR = [[attributedString attributesAtIndex:expectedRange.location effectiveRange:&range][DTHorizontalRuleStyleAttribute] boolValue];
	XCTAssertTrue(isHR, @"HR should be in range %@", NSStringFromRange(expectedRange));

	if ([attributedString length]>12)
	{
		expectedRange = NSMakeRange(12, 1);
		isHR = [[attributedString attributesAtIndex:expectedRange.location effectiveRange:&range][DTHorizontalRuleStyleAttribute] boolValue];
		XCTAssertTrue(isHR, @"HR should be in range %@", NSStringFromRange(expectedRange));
		
		expectedRange = NSMakeRange(13, 1);
		isHR = [[attributedString attributesAtIndex:expectedRange.location effectiveRange:&range][DTHorizontalRuleStyleAttribute] boolValue];
		XCTAssertTrue(isHR, @"HR should be in range %@", NSStringFromRange(expectedRange));
	}
}


#pragma mark - Non-Wellformed Content

// issue 462: Assertion Failure when attempting to parse beyond final </html> tag
- (void)testCharactersAfterEndOfHTML
{
	XCTAssertTrue([self attributedStringFromHTMLString:@"<html><body><p>text</p></body></html>bla bla bla" options:nil]!=nil, @"Should be able to parse without crash");
}

// issue 447: EXC_BAD_ACCESS on Release build when accessing -[DTHTMLElement parentElement] with certain HTML data
- (void)testTagAfterEndOfHTML
{
	XCTAssertTrue([self attributedStringFromHTMLString:@"<html><body><p>text</p></body></html><img>" options:nil]!=nil, @"Should be able to parse without crash");
}

#pragma mark - Fonts

// Pull Request 744: DTDefaultFontName to specify font name next to DTDefaultFontFamily
- (void)testDefaultFontName
{
	NSDictionary *options = @{DTDefaultFontName: @"Helvetica-Bold"};

	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<html><body><p>Bla<p></body></html>" options:options];

	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:NULL];

	DTCoreTextFontDescriptor *fontDescriptor = [attributes fontDescriptor];

	XCTAssertEqualObjects(fontDescriptor.fontFamily, @"Helvetica", @"Incorrect font family");
	XCTAssertTrue(fontDescriptor.boldTrait, @"Should be bold");
}

// Issue 443: crash on combining font-family:inherit with small caps
- (void)testFontFamilySmallCapsCrash
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<p style=\"font-variant:small-caps; font-family:inherit;\">Test</p>" options:nil];
	
	XCTAssertTrue([attributedString length]==5, @"Should be 5 characters");
}

- (void)testFallbackFontFamily
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<p style=\"font-family:Calibri\">Text</p>" options:nil];
	
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:NULL];
	
	DTCoreTextFontDescriptor *fontDescriptor = [attributes fontDescriptor];
	
	XCTAssertEqualObjects(fontDescriptor.fontFamily, @"Times New Roman", @"Incorrect fallback font family");
}

- (void)testInvalidFontSize
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<span style=\"font-size:30px\"><p style=\"font-size:normal\">Bla</p></span>" options:nil];
	
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:NULL];
	
	DTCoreTextFontDescriptor *fontDescriptor = [attributes fontDescriptor];
	
	XCTAssertEqual(fontDescriptor.pointSize, (CGFloat)30, @"Should ignore invalid CSS length");
}

- (void)testFontTagWithStyle
{
	NSAttributedString *output = [self attributedStringFromHTMLString:@"<font style=\"font-size: 17pt;\"> <u>BOLUS DOSE&nbsp;&nbsp; = xx.x mg&nbsp;</u> </font>" options:nil];
	
	CTFontRef font = (__bridge CTFontRef)([output attribute:(id)kCTFontAttributeName atIndex:0 effectiveRange:NULL]);
	
	CGFloat pointSize = CTFontGetSize(font);
	
	XCTAssertEqual(pointSize, (CGFloat)23.0f, @"Font Size should be 23 px (= 17 pt)");
}

- (void)testFontSizeInterpretation
{
	NSAttributedString *output = [self attributedStringFromTestFileName:@"FontSizes"];
	
	NSUInteger paraEndIndex = 0;
	
	while (paraEndIndex<[output length])
	{
		NSRange paragraphRange = [[output string] rangeOfParagraphsContainingRange:NSMakeRange(paraEndIndex, 0) parBegIndex:NULL parEndIndex:&paraEndIndex];
		
		__block CGFloat paragraphFontSize = 0; // initialized from first font in paragraph
		
		[output enumerateAttribute:(id)kCTFontAttributeName inRange:paragraphRange options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
			
			NSString *subString = [[output string] substringWithRange:range];
			
			// the NL are exempt from the test
			if ([subString isEqualToString:@"\n"])
			{
				return;
			}
			
			DTCoreTextFontDescriptor *fontDescriptor = [DTCoreTextFontDescriptor fontDescriptorForCTFont:(__bridge CTFontRef)(value)];
			
			if (paragraphFontSize==0)
			{
				paragraphFontSize = fontDescriptor.pointSize;
			}
			else
			{
				XCTAssertEqual(fontDescriptor.pointSize, paragraphFontSize, @"Font in range %@ does not match paragraph font size of %.1fpx", NSStringFromRange(range), paragraphFontSize);
			}
		}];
		
	}
}

// testing if Helvetica font family returns the correct font
- (void)testHelveticaVariants
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<p style=\"font-family:Helvetica\">Regular</p><p style=\"font-family:Helvetica;font-weight:bold;\">Bold</p><p style=\"font-family:Helvetica;font-style:italic;}\">Italic</p><p style=\"font-family:Helvetica;font-style:italic;font-weight:bold;}\">Bold+Italic</p>" options:nil];
	
	NSString *string = [attributedString string];
	NSRange entireStringRange = NSMakeRange(0, [string length]);
	
	__block NSUInteger lineNumber = 0;
	
	[string enumerateSubstringsInRange:entireStringRange options:NSStringEnumerationByParagraphs usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
		
		CTFontRef font;
		NSRange fontRange = [self _effectiveRangeOfFontAtIndex:substringRange.location inAttributedString:attributedString font:&font];
		
		XCTAssertTrue(NSEqualRanges(enclosingRange, fontRange), @"Font should be on entire string");
		
		DTCoreTextFontDescriptor *fontDescriptor = [DTCoreTextFontDescriptor fontDescriptorForCTFont:font];
		
		switch (lineNumber) {
			case 0:
			{
				XCTAssertEqualObjects(fontDescriptor.fontFamily, @"Helvetica", @"Font family should be Helvetica");
				XCTAssertEqualObjects(fontDescriptor.fontName, @"Helvetica", @"Font face should be Helvetica");
				break;
			}
				
			case 1:
			{
				XCTAssertEqualObjects(fontDescriptor.fontFamily, @"Helvetica", @"Font family should be Helvetica");
				XCTAssertEqualObjects(fontDescriptor.fontName, @"Helvetica-Bold", @"Font face should be Helvetica");
				break;
			}
			case 2:
			{
				XCTAssertEqualObjects(fontDescriptor.fontFamily, @"Helvetica", @"Font family should be Helvetica");
				XCTAssertEqualObjects(fontDescriptor.fontName, @"Helvetica-Oblique", @"Font face should be Helvetica-Oblique");
				break;
			}
			case 3:
			{
				XCTAssertEqualObjects(fontDescriptor.fontFamily, @"Helvetica", @"Font family should be Helvetica");
				XCTAssertEqualObjects(fontDescriptor.fontName, @"Helvetica-BoldOblique", @"Font face should be Helvetica-BoldOblique");
				break;
			}
			default:
				break;
		}
		
		lineNumber++;
	}];
}

// issue 537
- (void)testMultipleFontFamiliesCrash
{
	XCTAssertTrue([self attributedStringFromHTMLString:@"<p style=\"font-family:Helvetica,sans-serif\">Text</p>" options:nil]!=nil, @"Should be able to parse without crash");
}

// issue 538
- (void)testMultipleFontFamiliesSelection
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<p style=\"font-family:'American Typewriter',sans-serif\">Text</p>" options:nil];
	
	CTFontRef font;
	NSRange fontRange = [self _effectiveRangeOfFontAtIndex:0 inAttributedString:attributedString font:&font];
	
	NSRange expectedRange = NSMakeRange(0, [attributedString length]);
	XCTAssertTrue(NSEqualRanges(fontRange, expectedRange), @"Font should be entire length");
	
	DTCoreTextFontDescriptor *descriptor = [DTCoreTextFontDescriptor fontDescriptorForCTFont:font];
	
	XCTAssertEqualObjects(descriptor.fontFamily, @"American Typewriter", @"Font Family should be 'American Typewriter'");
}

// issue 538
- (void)testMultipleFontFamiliesSelectionLaterPosition
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<p style=\"font-family:foo,'American Typewriter'\">Text</p>" options:nil];
	
	CTFontRef font;
	NSRange fontRange = [self _effectiveRangeOfFontAtIndex:0 inAttributedString:attributedString font:&font];
	
	NSRange expectedRange = NSMakeRange(0, [attributedString length]);
	XCTAssertTrue(NSEqualRanges(fontRange, expectedRange), @"Font should be entire length");
	
	DTCoreTextFontDescriptor *descriptor = [DTCoreTextFontDescriptor fontDescriptorForCTFont:font];
	
	XCTAssertEqualObjects(descriptor.fontFamily, @"American Typewriter", @"Font Family should be 'American Typewriter'");
}

// issue 742
- (void)testHelveticaNeueLight
{
	NSString *helveticaNeueFontFaceName = @"HelveticaNeue-Light";
	
	CTFontRef lightFont =  CTFontCreateWithName((__bridge CFStringRef)helveticaNeueFontFaceName, 12, NULL);
	NSString *checkName = CFBridgingRelease(CTFontCopyPostScriptName(lightFont));
	CFRelease(lightFont);
	
	if (![checkName isEqualToString:helveticaNeueFontFaceName])
	{
		NSLog(@"Font face '%@'not supported on current platform, skipping test", helveticaNeueFontFaceName);
		return;
	}
	
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<p><font face=\"HelveticaNeue-Light\">HelveticaNeue-Light <b>bold</b> <em>italic</em></font></p>" options:nil];
	
	CTFontRef font;
	NSRange fontRange = [self _effectiveRangeOfFontAtIndex:0 inAttributedString:attributedString font:&font];
	
	// test normal font
	NSRange expectedRange = NSMakeRange(0, 20);
	XCTAssertTrue(NSEqualRanges(fontRange, expectedRange), @"Font should be 20 characters long");
	DTCoreTextFontDescriptor *descriptor = [DTCoreTextFontDescriptor fontDescriptorForCTFont:font];
	XCTAssertEqualObjects(descriptor.fontName, @"HelveticaNeue-Light", @"Font face should be 'HelveticaNeue-Light'");
	
	// test inherited font with bold
	expectedRange = NSMakeRange(20, 4);  // "bold"
	fontRange = [self _effectiveRangeOfFontAtIndex:expectedRange.location inAttributedString:attributedString font:&font];
	XCTAssertTrue(NSEqualRanges(fontRange, expectedRange), @"Bold Font should be 4 characters long");
	descriptor = [DTCoreTextFontDescriptor fontDescriptorForCTFont:font];
	XCTAssertEqualObjects(descriptor.fontName, @"HelveticaNeue-Bold", @"Font face should be 'HelveticaNeue-Bold'");
	
	// test inherited font with italic
	expectedRange = NSMakeRange(25, 7);  // "italic" (6) + NL (1) = 7
	fontRange = [self _effectiveRangeOfFontAtIndex:expectedRange.location inAttributedString:attributedString font:&font];
	XCTAssertTrue(NSEqualRanges(fontRange, expectedRange), @"Italic Font should be 5 characters long");
	descriptor = [DTCoreTextFontDescriptor fontDescriptorForCTFont:font];
	XCTAssertEqualObjects(descriptor.fontName, @"HelveticaNeue-Italic", @"Font face should be 'HelveticaNeue-Italic'");
}

// issue 804: allow custom font name specification
- (void)testOverrideFontName
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<p style=\"-coretext-fontname:Arial-BoldMT\">Bold</p>" options:nil];

	CTFontRef font;
	NSRange fontRange = [self _effectiveRangeOfFontAtIndex:0 inAttributedString:attributedString font:&font];
	
	NSRange expectedRange = NSMakeRange(0, [attributedString length]);
	XCTAssertTrue(NSEqualRanges(fontRange, expectedRange), @"Font should be entire length");
	
	DTCoreTextFontDescriptor *descriptor = [DTCoreTextFontDescriptor fontDescriptorForCTFont:font];
	
	XCTAssertEqualObjects(descriptor.fontName, @"Arial-BoldMT", @"Font should be 'Arial-BoldMT'");
}

#pragma mark - Nested Lists

- (void)testNestedListWithStyleNone
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<ul><li>Bullet</li><li style=\"list-style: none\"><ul><li>Bullet 2</li></ul></li></ul>" options:nil];
	
	NSString *string = [attributedString string];
	NSRange entireStringRange = NSMakeRange(0, [string length]);
	
	__block NSUInteger lineNumber = 0;
	
	[string enumerateSubstringsInRange:entireStringRange options:NSStringEnumerationByParagraphs usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
		
		NSAttributedString *attributedSubstring = [attributedString attributedSubstringFromRange:enclosingRange];
		
		switch (lineNumber)
		{
			case 1:
			{
				NSArray *lists = [attributedSubstring attribute:DTTextListsAttribute atIndex:0 effectiveRange:NULL];
				NSInteger numLists = [lists count];
				XCTAssertEqual(numLists, (NSInteger)2, @"There should be two lists active on line 2, but %ld found", (long)numLists);
				
				NSString *subString = [[attributedSubstring string] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
				
				XCTAssertTrue([subString hasSuffix:@"Bullet 2"], @"The second line should have the 'Bullet 2' text");
				
				break;
			}
				
			default:
				break;
		}
		
		lineNumber++;
	}];
}

// list prefixes should never contained the newline
- (void)testPrefixWithNewlines
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<ul><li>Bullet</li><li><ul><li>Bullet 2</li></ul></li></ul>" options:nil];
	
	NSString *string = [attributedString string];
	NSRange entireStringRange = NSMakeRange(0, [string length]);
	
	__block NSUInteger lineNumber = 0;
	
	[string enumerateSubstringsInRange:entireStringRange options:NSStringEnumerationByParagraphs usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
		
		NSAttributedString *attributedSubstring = [attributedString attributedSubstringFromRange:enclosingRange];
		
		NSRange prefixRange = [attributedSubstring rangeOfFieldAtIndex:0];
		NSString *prefix = [[attributedSubstring string] substringWithRange:prefixRange];
		
		// there should never be a newline contained inside the prefix
		NSRange newlineRange = [prefix rangeOfString:@"\n"];
		
		BOOL foundNL = (newlineRange.location != NSNotFound);
		
		XCTAssertFalse(foundNL, @"Newline in prefix of line %lu", (unsigned long)lineNumber);
		
		lineNumber++;
	}];
}

// issue 574
- (void)testCorrectListBullets
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<ul><li>1</li><ul><li>2</li><ul><li>3</li></ul></ul></ul>" options:nil];
	

	NSString *string = [attributedString string];
	NSRange entireStringRange = NSMakeRange(0, [string length]);
	
	__block NSUInteger lineNumber = 0;
	
	[string enumerateSubstringsInRange:entireStringRange options:NSStringEnumerationByParagraphs usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
		
		NSAttributedString *attributedSubstring = [attributedString attributedSubstringFromRange:enclosingRange];
		
		NSRange prefixRange = [attributedSubstring rangeOfFieldAtIndex:0];
		prefixRange.location++;
		prefixRange.length = 1;
		NSString *bulletChar = [[attributedSubstring string] substringWithRange:prefixRange];
		
		NSString *expectedChar = nil;
		
		switch (lineNumber)
		{
			case 0:
			{
				expectedChar = @"\u2022"; // disc
				break;
			}
				
			case 1:
			{
				expectedChar = @"\u25e6"; // circle
				break;
			}
				
			case 2:
			{
				expectedChar = @"\u25aa"; // square
				break;
			}
		}
		
		BOOL characterIsCorrect = [bulletChar isEqualToString:expectedChar];
		XCTAssertTrue(characterIsCorrect, @"Bullet Character on UL level %lu should be '%@' but is '%@'", (long)lineNumber+1, expectedChar, bulletChar);
		
		lineNumber++;
	}];
}

// issue 574
- (void)testMixedListPrefix
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<ol><li>1a<ul><li>2a<ol><li>3a</li></ol></li></ul></li></ol>" options:nil];
	
	NSString *string = [attributedString string];
	NSRange entireStringRange = NSMakeRange(0, [string length]);
	
	__block NSUInteger lineNumber = 0;
	
	[string enumerateSubstringsInRange:entireStringRange options:NSStringEnumerationByParagraphs usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
		
		NSAttributedString *attributedSubstring = [attributedString attributedSubstringFromRange:enclosingRange];
		
		NSRange prefixRange = [attributedSubstring rangeOfFieldAtIndex:0];
		NSString *prefix = [[attributedSubstring string] substringWithRange:prefixRange];
		
		NSString *expectedPrefix = nil;
		
		switch (lineNumber)
		{
			case 0:
			{
				expectedPrefix = @"\t1.\t"; // one
				break;
			}
				
			case 1:
			{
				expectedPrefix = @"\t\u25e6\t"; // circle
				break;
			}
				
			case 2:
			{
				expectedPrefix = @"\t1.\t"; // one
				break;
			}
		}
		
		BOOL prefixIsCorrect = [prefix isEqualToString:expectedPrefix];
		XCTAssertTrue(prefixIsCorrect, @"Prefix level %lu should be '%@' but is '%@'", (long)lineNumber+1, expectedPrefix, prefix);
		
		lineNumber++;
	}];
}

// issue 613
- (void)testBackgroundColorTransferFromListItemToText
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<ul><li style=\"background-color:red\">12345" options:nil];
	
	NSRange effectiveRange;
	NSDictionary *attributes = [attributedString attributesAtIndex:4 effectiveRange:&effectiveRange];
	
	DTColor *backgroundColor = [attributes backgroundColor];
	
	XCTAssertNotNil(backgroundColor, @"Missing Background Color");
	
	NSRange expectedRange = NSMakeRange(3, 5);
	
	XCTAssertTrue(NSEqualRanges(effectiveRange, expectedRange), @"Range is not correct");
	
	NSString *colorHex = DTHexStringFromDTColor(backgroundColor);
	
	XCTAssertEqualObjects(colorHex, @"ff0000", @"Color should be red");
}

- (void)testTextListRanges
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<ol><li>1a<ul><li>2a</li></ul></li><li>more</li><li>more</li></ol>" options:NULL];
	
	NSArray *lists = [attributedString attribute:DTTextListsAttribute atIndex:0 effectiveRange:NULL];
	
	XCTAssertTrue([lists count]==1, @"There should be 1 outer list");
	
	DTCSSListStyle *outerList = [lists lastObject];
	
	NSRange list1Range = [attributedString rangeOfTextList:outerList atIndex:0];
	
	XCTAssertTrue(!list1Range.location, @"lists should start at index 0");
	XCTAssertTrue(list1Range.length, @"lists should range for entire string");
	
	NSRange innerRange = [[attributedString string] rangeOfString:@"2a"];
	NSArray *innerLists = [attributedString attribute:DTTextListsAttribute atIndex:innerRange.location effectiveRange:NULL];
	
	XCTAssertTrue([innerLists count]==2, @"There should be 2 inner lists");
	
	if ([innerLists count])
	{
		XCTAssertTrue([innerLists objectAtIndex:0] == outerList , @"list at index 0 in inner lists should be same as outer list");
	}
	
	NSRange list2Range = [attributedString rangeOfTextList:[innerLists lastObject] atIndex:innerRange.location];
	NSRange innerParagraph = [[attributedString string] paragraphRangeForRange:innerRange];
	
	XCTAssertTrue(NSEqualRanges(innerParagraph, list2Range), @"Inner list range should be equal to inner paragraph");
}


// issue 625
- (void)testEmptyListItemWithSubList
{
	// first paragraph should have one lists
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<ul>\n<li>\n<ol>\n<li>Foo</li>\n<li>Bar</li>\n</ol>\n</li>\n<li>BLAH</li>\n</ul>" options:NULL];
	NSRange firstParagraphRange = [[attributedString string] paragraphRangeForRange:NSMakeRange(0, 1)];
	NSArray *firstParagraphLists = [attributedString attribute:DTTextListsAttribute atIndex:firstParagraphRange.location effectiveRange:NULL];
	NSUInteger firstListsCount = [firstParagraphLists count];
	
	XCTAssertTrue(firstListsCount == 1, @"There should be two lists on the first paragraph");
	
	// all lists in the first paragraph should be at least covering the entire paragraph
	
	[firstParagraphLists enumerateObjectsUsingBlock:^(DTCSSListStyle *oneList, NSUInteger idx, BOOL *stop) {
		
		NSRange listRange = [attributedString rangeOfTextList:oneList atIndex:firstParagraphRange.location];
		
		NSRange commonRange = NSIntersectionRange(listRange, firstParagraphRange);
		
		XCTAssertTrue(NSEqualRanges(commonRange, firstParagraphRange), @"List %lu does not cover entire paragraph", (long)idx+1);
	}];
	
	// second paragraph should have two lists
	NSRange secondParagraphRange = [[attributedString string] paragraphRangeForRange:NSMakeRange(NSMaxRange(firstParagraphRange),1)];
	NSArray *secondParagraphLists = [attributedString attribute:DTTextListsAttribute atIndex:secondParagraphRange.location effectiveRange:NULL];
	NSUInteger secondListsCount = [secondParagraphLists count];
	
	XCTAssertTrue(secondListsCount == 2, @"There should be two lists on the first paragraph");
	
	// all lists in the second paragraph should be at least covering the entire paragraph
	
	[secondParagraphLists enumerateObjectsUsingBlock:^(DTCSSListStyle *oneList, NSUInteger idx, BOOL *stop) {
		
		NSRange listRange = [attributedString rangeOfTextList:oneList atIndex:secondParagraphRange.location];
		
		NSRange commonRange = NSIntersectionRange(listRange, secondParagraphRange);
		
		XCTAssertTrue(NSEqualRanges(commonRange, secondParagraphRange), @"List %lu does not cover entire paragraph", (long)idx+1);
	}];
	
}

#pragma mark - CSS Tests

// issue 544
- (void)testCascading
{
	NSAttributedString *output = [self attributedStringFromTestFileName:@"CSSCascading"];
	
	NSUInteger index1 = 0;
	NSUInteger index2 = 3;
	NSUInteger index3 = 10;
	NSUInteger index4 = 16;
	NSUInteger index5 = 18;
	NSUInteger index6 = 47;
	NSUInteger index7 = 98;

	// check first "me"
	NSDictionary *attributes1 = [output attributesAtIndex:index1 effectiveRange:NULL];
	NSNumber *underLine1 = [output attribute:(id)kCTUnderlineStyleAttributeName atIndex:index1 effectiveRange:NULL];
	XCTAssertTrue([underLine1 integerValue]==1, @"First item should be underlined");
	DTColor *foreground1 = [attributes1 foregroundColor];
	NSString *foreground1HTML =  DTHexStringFromDTColor(foreground1);
	BOOL colorOk1 = ([foreground1HTML isEqualToString:@"008000"]);
	XCTAssertTrue(colorOk1, @"First item should be green");
	BOOL isBold1 = [[attributes1 fontDescriptor] boldTrait];
	XCTAssertTrue(isBold1, @"First item should be bold");
	BOOL isItalic1 = [[attributes1 fontDescriptor] italicTrait];
	XCTAssertFalse(isItalic1, @"First item should not be italic");

	// check first "buzz"
	NSDictionary *attributes2 = [output attributesAtIndex:index2 effectiveRange:NULL];
	NSNumber *underLine2 = [output attribute:(id)kCTUnderlineStyleAttributeName atIndex:index2 effectiveRange:NULL];
	XCTAssertTrue([underLine2 integerValue]==1, @"Second item should be underlined");
	DTColor *foreground2 = [attributes2 foregroundColor];
	NSString *foreground2HTML = DTHexStringFromDTColor(foreground2);
	BOOL colorOk2 = ([foreground2HTML isEqualToString:@"800080"]);
	XCTAssertTrue(colorOk2, @"Second item should be purple");
	BOOL isBold2 = [[attributes2 fontDescriptor] boldTrait];
	XCTAssertTrue(isBold2, @"Second item should be bold");

	// check second "owzers"
	NSDictionary *attributes3 = [output attributesAtIndex:index3 effectiveRange:NULL];
	NSNumber *underLine3 = [output attribute:(id)kCTUnderlineStyleAttributeName atIndex:index3 effectiveRange:NULL];
	XCTAssertTrue([underLine3 integerValue]==1, @"Third item should be underlined");
	NSNumber *strikeThrough3 = [output attribute:DTStrikeOutAttribute atIndex:index3 effectiveRange:NULL];
	XCTAssertTrue([strikeThrough3 integerValue]==1, @"Third item should have strike through");
	DTColor *foreground3 = [attributes3 foregroundColor];
	NSString *foreground3HTML = DTHexStringFromDTColor(foreground3);
	BOOL colorOk3 = ([foreground3HTML isEqualToString:@"ffa500"]);
	XCTAssertTrue(colorOk3, @"Third item should be orange");
	BOOL isBold3 = [[attributes3 fontDescriptor] boldTrait];
	XCTAssertFalse(isBold3, @"Third item should not be bold");
	BOOL isItalic3 = [[attributes3 fontDescriptor] italicTrait];
	XCTAssertTrue(isItalic3, @"Third item should be italic");
	
	// check second "Me"
	NSDictionary *attributes4 = [output attributesAtIndex:index4 effectiveRange:NULL];
	NSNumber *underLine4 = [output attribute:(id)kCTUnderlineStyleAttributeName atIndex:index4 effectiveRange:NULL];
	XCTAssertFalse([underLine4 integerValue]==1, @"Fourth item should be not underlined");
	DTColor *foreground4 = [attributes4 foregroundColor];
	NSString *foreground4HTML = DTHexStringFromDTColor(foreground4);
	BOOL colorOk4 = ([foreground4HTML isEqualToString:@"ff0000"]);
	XCTAssertTrue(colorOk4, @"Fourth item should be red");
	BOOL isBold4 = [[attributes4 fontDescriptor] boldTrait];
	XCTAssertFalse(isBold4, @"Fourth item should not be bold");
	BOOL isItalic4 = [[attributes4 fontDescriptor] italicTrait];
	XCTAssertFalse(isItalic4, @"Fourth item should not be italic");

	// check second "ow"
	NSDictionary *attributes5 = [output attributesAtIndex:index5 effectiveRange:NULL];
	NSNumber *underLine5 = [output attribute:(id)kCTUnderlineStyleAttributeName atIndex:index5 effectiveRange:NULL];
	XCTAssertTrue([underLine5 integerValue]==1, @"Fifth item should be underlined");
	DTColor *foreground5 = [attributes5 foregroundColor];
	NSString *foreground5HTML = DTHexStringFromDTColor(foreground5);
	BOOL colorOk5 = ([foreground5HTML isEqualToString:@"008000"]);
	XCTAssertTrue(colorOk5, @"Fifth item should be green");
	BOOL isBold5 = [[attributes5 fontDescriptor] boldTrait];
	XCTAssertTrue(isBold5, @"Fifth item should be bold");
	BOOL isItalic5 = [[attributes5 fontDescriptor] italicTrait];
	XCTAssertFalse(isItalic5, @"Fifth item should not be italic");

	// check second "this is a test of by tag name..."
	NSDictionary *attributes6 = [output attributesAtIndex:index6 effectiveRange:NULL];
	NSNumber *underLine6 = [output attribute:(id)kCTUnderlineStyleAttributeName atIndex:index6 effectiveRange:NULL];
	XCTAssertTrue([underLine6 integerValue]==1, @"Sixth item should be underlined");
	DTColor *foreground6 = [attributes6 foregroundColor];
	NSString *foreground6HTML = DTHexStringFromDTColor(foreground6);
	BOOL colorOk6 = ([foreground6HTML isEqualToString:@"ffa500"]);
	XCTAssertTrue(colorOk6, @"Sixth item should be orange");
	BOOL isBold6 = [[attributes6 fontDescriptor] boldTrait];
	XCTAssertFalse(isBold6, @"Sixth item should not be bold");
	BOOL isItalic6 = [[attributes6 fontDescriptor] italicTrait];
	XCTAssertTrue(isItalic6, @"Sixth item should be italic");

	// check second "i'm gray text"
	NSDictionary *attributes7 = [output attributesAtIndex:index7 effectiveRange:NULL];
	NSNumber *underLine7 = [output attribute:(id)kCTUnderlineStyleAttributeName atIndex:index7 effectiveRange:NULL];
	XCTAssertFalse([underLine7 integerValue]==1, @"Seventh item should not be underlined");
	DTColor *foreground7 = [attributes7 foregroundColor];
	NSString *foreground7HTML = DTHexStringFromDTColor(foreground7);
	BOOL colorOk7 = ([foreground7HTML isEqualToString:@"777777"]);
	XCTAssertTrue(colorOk7, @"Seventh item should be gray");
	BOOL isBold7 = [[attributes7 fontDescriptor] boldTrait];
	XCTAssertFalse(isBold7, @"Seventh item should not be bold");
	BOOL isItalic7 = [[attributes7 fontDescriptor] italicTrait];
	XCTAssertFalse(isItalic7, @"Seventh item should not be italic");
}

// issue 555
- (void)testCascadingOutOfMemory
{
	NSDate *startTime = [NSDate date];
	NSAttributedString *attributedString = [self attributedStringFromTestFileName:@"CSSOOMCrash"];
	XCTAssertTrue(attributedString != nil, @"Should be able to parse without running out of memory");
	XCTAssertTrue(([[NSDate date] timeIntervalSinceDate:startTime]) < 0.5f, @"Test should run in less than 0.5 seconds. Prior to fix, it took 16.85 seconds to run this test.");
}

// issue 557
- (void)testIncorrectFontSizeInheritance
{
	NSString *html = @"<html><head><style>.sample { font-size: 2em; }</style></head><body><div class=\"sample\">Text1<p> Text2</p></div></div></html>";
	NSAttributedString *output = [self attributedStringFromHTMLString:html options:nil];
	
	NSDictionary *attributes1 = [output attributesAtIndex:1 effectiveRange:NULL];
	DTCoreTextFontDescriptor *text1FontDescriptor = [attributes1 fontDescriptor];
	
	NSDictionary *attributes2 = [output attributesAtIndex:7 effectiveRange:NULL];
	DTCoreTextFontDescriptor *text2FontDescriptor = [attributes2 fontDescriptor];
	
	XCTAssertEqual(text1FontDescriptor.pointSize, text2FontDescriptor.pointSize, @"Point size should be the same when font-size is cascaded and inherited.");
}

- (void)testIncorrectSimpleSelectorCascade
{
	NSString *html = @"<html><head><style>.sample { color: green; }</style></head><body><div class=\"sample\">Text1<p> Text2</p></div></div></html>";
	NSAttributedString *output = [self attributedStringFromHTMLString:html options:nil];
	
	NSDictionary *attributes1 = [output attributesAtIndex:1 effectiveRange:NULL];
	DTColor *foreground1 = [attributes1 foregroundColor];
	NSString *foreground1HTML = DTHexStringFromDTColor(foreground1);
	
	NSDictionary *attributes2 = [output attributesAtIndex:7 effectiveRange:NULL];
	DTColor *foreground2 = [attributes2 foregroundColor];
	NSString *foreground2HTML = DTHexStringFromDTColor(foreground2);

	XCTAssertEqualObjects(foreground1HTML, foreground2HTML, @"Color should be inherited via cascaded selector.");
}

- (void)testSubstringCascadedSelectorsBeingProperlyApplied
{
	NSString *html = @"<html><head><style> body .sample { color: red;} body .samples { color: green;}</style></head><body><div class=\"samples\">Text</div></html>";
	NSAttributedString *output = [self attributedStringFromHTMLString:html options:nil];
	
	NSDictionary *attributes = [output attributesAtIndex:1 effectiveRange:NULL];
	DTColor *foreground = [attributes foregroundColor];
	NSString *foregroundHTML = DTHexStringFromDTColor(foreground);
	XCTAssertEqualObjects(foregroundHTML, @"008000", @"Color should be green and not red.");
}

- (void)testCascadedSelectorSpecificity {
	NSString *html = @"<html><head><style> #foo .bar { font-size: 225px; color: green; } body #foo .bar { font-size: 24px; } #foo .bar { font-size: 100px; color: red; }</style> </head><body><div id=\"foo\"><div class=\"bar\">Text</div></div></body></html>";
	NSAttributedString *output = [self attributedStringFromHTMLString:html options:nil];
	
	NSDictionary *attributes = [output attributesAtIndex:1 effectiveRange:NULL];
	DTColor *foreground = [attributes foregroundColor];
	NSString *foregroundHTML = DTHexStringFromDTColor(foreground);
	XCTAssertEqualObjects(foregroundHTML, @"ff0000", @"Color should be red and not green.");

	DTCoreTextFontDescriptor *textFontDescriptor = [attributes fontDescriptor];
	XCTAssertTrue(textFontDescriptor.pointSize == 24.0f, @"Point size should 24 and not 225 or 100.");
}

- (void)testCascadedSelectorsWithEqualSpecificityLastDeclarationWins {
	NSString *html = @"<html><head><style>#foo .bar { color: red; } #foo .bar { color: green; }</style> </head><body><div id=\"foo\"><div class=\"bar\">Text</div></div></body></html>";
	NSAttributedString *output = [self attributedStringFromHTMLString:html options:nil];
	
	NSDictionary *attributes = [output attributesAtIndex:1 effectiveRange:NULL];
	DTColor *foreground = [attributes foregroundColor];
	NSString *foregroundHTML = DTHexStringFromDTColor(foreground);
	XCTAssertEqualObjects(foregroundHTML, @"008000", @"Color should be green and not red.");

	NSString *html2 = @"<html><head><style>.bar { color: red; } .foo { color: green; } </style> </head><body><div class=\"foo\"><div class=\"bar\"><div>Text</div></div></div></body></html>";
	NSAttributedString *output2 = [self attributedStringFromHTMLString:html2 options:nil];
	NSDictionary *attributes2 = [output2 attributesAtIndex:1 effectiveRange:NULL];
	DTColor *foreground2 = [attributes2 foregroundColor];
	NSString *foregroundHTML2 = DTHexStringFromDTColor(foreground2);
	XCTAssertEqualObjects(foregroundHTML2, @"ff0000", @"Color should be red and not green.");
}

// text should be green even though there is a span following the div-div.
- (void)testDivDivSpan
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<html><head><style>div div {color:green;}</style></head><body><div><div><span>FOO</span></div></div></body></html>" options:nil];
	
	NSDictionary *attributes1 = [attributedString attributesAtIndex:0 effectiveRange:NULL];
	DTColor *foreground1 = [attributes1 foregroundColor];
	NSString *foreground1HTML = DTHexStringFromDTColor(foreground1);
	BOOL colorOk1 = ([foreground1HTML isEqualToString:@"008000"]);
	XCTAssertTrue(colorOk1, @"First item should be green");
}

- (void)testLetterSpacing
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<h1 style=\"font-variant: small-caps; letter-spacing:10px\">one</h1>" options:NULL];
	
	NSDictionary *attributes1 = [attributedString attributesAtIndex:0 effectiveRange:NULL];
	
	CGFloat kerning = [attributes1 kerning];
	
	XCTAssertTrue(kerning == 10, @"Kerning should be 10px");
}

// issue 636
- (void)testDisplayStyleInheritance
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<html><head><style>	.container { display: block; }	span.test { font-style:italic; }</style></head><body><div class='container'>\n    before  <span class='test'>test</span> after\n</div></body></html>" options:NULL];
	
	
	NSArray *lines = [[[attributedString string] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsSeparatedByString:@"\n"];
	XCTAssertTrue([lines count]==1, @"There should only be one line, display style block should not be inherited");
}

#pragma mark - Attachments

// issue 738: Attachments with display:none should not show
- (void)testAttachmentWithDisplayNone
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<img style=\"display:none;\" src=\"Oliver.jpg\">" options:nil];
	XCTAssertEqual([attributedString length], 0, @"Text attachment should be invisible");
}

// issue 738: Attachment with display:none would cause incorrect needsOutput return
- (void)testDoubleOutputOfAttachmentWithDisplayNone
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<oliver style=\"width:40; height:40;display:none;\"><p><strong>BOX1</strong></p></oliver><oliver style=\"width:40; height:40;display:block;\"><p><strong>BOX2</strong></p></oliver><p>END</p>" options:nil];
	
	NSRange effectiveRange;
	id attachment = [attributedString attribute:NSAttachmentAttributeName atIndex:0 effectiveRange:&effectiveRange];
	
	XCTAssertNotNil(attachment, @"There should be an attachment");
	XCTAssertTrue(NSEqualRanges(effectiveRange, NSMakeRange(0, 1)), @"Attachment should only be on first character");
	
	for (NSInteger i=1; i<[attributedString length]; i++)
	{
		id otherAttachment = [attributedString attribute:NSAttachmentAttributeName atIndex:i effectiveRange:&effectiveRange];
		XCTAssertNil(otherAttachment, @"There is an unexpected attachment at %@", NSStringFromRange(effectiveRange));
	}
}

// issue 816: Retina data URL would cause incorrect original size
- (void)testRetinaDataURL
{
	NSAttributedString *attributedString = [self attributedStringFromTestFileName:@"RetinaDataURL"];
	
	XCTAssert([attributedString length] == 2, @"RetinaDataURL should be parsed as 2 characters");
	
	NSRange effectiveRange;
	DTImageTextAttachment *attachment = [attributedString attribute:NSAttachmentAttributeName atIndex:0 effectiveRange:&effectiveRange];
	
	XCTAssertNotNil(attachment, @"There should be an attachment");
	XCTAssertTrue(NSEqualRanges(effectiveRange, NSMakeRange(0, 1)), @"Attachment should only be on first character");
	
	CGSize targetSize = CGSizeMake(176, 68);
	
	XCTAssert([attachment isKindOfClass:[DTImageTextAttachment class]], @"Attachment should be image");
	XCTAssert(CGSizeEqualToSize(attachment.image.size, targetSize), @"Attachment has incorrect image size");
	XCTAssert(CGSizeEqualToSize(attachment.originalSize, targetSize), @"Attachment has incorrect original size");
	
#if TARGET_OS_IPHONE
	XCTAssert(attachment.image.scale == 2, @"Attachment image should have scale 2");
#endif
}

#pragma mark - Parsing Options

// issue 649
- (void)testIgnoreInlineStyle
{
	NSDictionary *options = @{DTIgnoreInlineStylesOption: @(YES)};
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<html><head><style>.container { color: red }</style></head><body><span class='container' style=\"color: blue\">Text</span></body></html>" options:options];
	
	NSRange effectiveRange;
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:&effectiveRange];
	
	NSRange expectedRange = NSMakeRange(0, [attributedString length]);
	XCTAssertTrue(NSEqualRanges(expectedRange, effectiveRange), @"Attributes should cover all text");
	
	DTColor *color = [attributes foregroundColor];
	NSString *hexColor = DTHexStringFromDTColor(color);
	
	XCTAssertEqualObjects(hexColor, @"ff0000", @"Color should be red because inline style should be ignored through option");
}

// issue 649
- (void)testProcessInlineStyle
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<html><head><style>.container { color: red }</style></head><body><span class='container' style=\"color: blue\">Text</span></body></html>" options:NULL];
	
	NSRange effectiveRange;
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:&effectiveRange];
	
	NSRange expectedRange = NSMakeRange(0, [attributedString length]);
	XCTAssertTrue(NSEqualRanges(expectedRange, effectiveRange), @"Attributes should cover all text");
	
	DTColor *color = [attributes foregroundColor];
	NSString *hexColor = DTHexStringFromDTColor(color);
	
	XCTAssertEqualObjects(hexColor, @"0000ff", @"Color should be blue because inline style should be processed through lack of ignore option");
}

@end
