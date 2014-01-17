//
//  DTHTMLAttributedStringBuilderTest.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 25.12.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTHTMLAttributedStringBuilderTest.h"

#import "DTHTMLAttributedStringBuilder.h"
#import "DTCoreTextConstants.h"
#import "DTCoreTextParagraphStyle.h"
#import "DTTextAttachment.h"
#import "DTCoreText.h"

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
	
	STAssertTrue([underLine integerValue]==0, @"Space between a and b should not be underlined");
}

// a block following an inline image should only cause a \n after the image, not whitespace
- (void)testWhitspaceAfterParagraphPromotedImage
{
	NSAttributedString *output = [self attributedStringFromTestFileName:@"WhitespaceFollowingImagePromotedToParagraph"];
	
	STAssertTrue([output length]==6, @"Generated String should be 6 characters");
	
	NSMutableString *expectedOutput = [NSMutableString stringWithFormat:@"1\n%@\n2\n", UNICODE_OBJECT_PLACEHOLDER];
	
	STAssertTrue([expectedOutput isEqualToString:[output string]], @"Expected output not matching");
}

// This should come out as Keep_me_together with the _ being non-breaking spaces
- (void)testKeepMeTogether
{
	NSAttributedString *output = [self attributedStringFromTestFileName:@"KeepMeTogether"];
	
	NSString *expectedOutput = @"Keep\u00a0me\u00a0together";
	
	STAssertTrue([expectedOutput isEqualToString:[output string]], @"Expected output not matching");
}

// issue 466: Support Encoding of Tabs in HTML
- (void)testTabDecodingAndPreservation
{
	NSAttributedString *output = [self attributedStringFromHTMLString:@"Some text and then 2 encoded<span style=\"white-space:pre\">&#9;&#9</span>tabs and 2 non-encoded		tabs" options:nil];
	
	NSString *plainString = [output string];
	NSRange range = [plainString rangeOfString:@"encoded"];
	
	STAssertTrue(range.location != NSNotFound, @"Should find 'encoded' in the string");
	
	NSString *tabs = [plainString substringWithRange:NSMakeRange(range.location+range.length, 2)];
	
	BOOL hasTabs = [tabs isEqualToString:@"\t\t"];
	
	STAssertTrue(hasTabs, @"There should be two tabs");
	
	range = [plainString rangeOfString:@"non-encoded"];
	NSString *compressedTabs = [plainString substringWithRange:NSMakeRange(range.location+range.length, 2)];
	
	BOOL hasCompressed = [compressedTabs isEqualToString:@" t"];
	
	STAssertTrue(hasCompressed, @"The second two tabs should be compressed to a single whitespace");
}

// issue 588: P inside LI
- (void)testParagraphInsideListItem
{
	NSAttributedString *output = [self attributedStringFromHTMLString:@"<ul><li><p>First Item</p></li></ul>" options:nil];
	NSString *plainText = [output string];
	
	NSRange firstRange = [plainText rangeOfString:@"First"];
	
	STAssertTrue(firstRange.location>0, @"Location should be greater than 0");
	
	NSString *characterBeforeFirstRange = [plainText substringWithRange:NSMakeRange(firstRange.location-1, 1)];
	
	STAssertTrue([characterBeforeFirstRange isEqualToString:@"\t"], @"Character before First should be tab");
	STAssertTrue(![characterBeforeFirstRange isEqualToString:@"\n"], @"Character before First should not be \n");
}

// issue 617: extra \n causes paragraph break
- (void)testSuperfluousParagraphBreakAfterBR
{
	NSAttributedString *output = [self attributedStringFromHTMLString:@"<h1 style=\"font-variant: small-caps;\">one<br>\n\ttwo</h1>" options:nil];
	NSString *plainText = [output string];
	
	NSRange twoRange = [plainText rangeOfString:@"TWO"];
	
	NSString *charBeforeTwo = [plainText substringWithRange:NSMakeRange(twoRange.location-1, 1)];
	
	STAssertFalse([charBeforeTwo isEqualToString:@"\n"], @"Superfluous NL following BR");
}

#pragma mark - General Tests

// tests functionality of dir attribute
- (void)testWritingDirection
{
	NSAttributedString *output = [self attributedStringFromHTMLString:@"<p dir=\"rtl\">rtl</p><p dir=\"ltr\">ltr</p><p>normal</p>" options:nil];
	
	CTParagraphStyleRef paragraphStyleRTL = (__bridge CTParagraphStyleRef)([output attribute:(id)kCTParagraphStyleAttributeName atIndex:0 effectiveRange:NULL]);
	DTCoreTextParagraphStyle *styleRTL = [DTCoreTextParagraphStyle paragraphStyleWithCTParagraphStyle:paragraphStyleRTL];
	
	STAssertTrue(styleRTL.baseWritingDirection == NSWritingDirectionRightToLeft, @"Writing direction is not RTL");
	
	CTParagraphStyleRef paragraphStyleLTR = (__bridge CTParagraphStyleRef)([output attribute:(id)kCTParagraphStyleAttributeName atIndex:4 effectiveRange:NULL]);
	DTCoreTextParagraphStyle *styleLTR = [DTCoreTextParagraphStyle paragraphStyleWithCTParagraphStyle:paragraphStyleLTR];
	
	STAssertTrue(styleLTR.baseWritingDirection == NSWritingDirectionLeftToRight, @"Writing direction is not LTR");

	CTParagraphStyleRef paragraphStyleNatural = (__bridge CTParagraphStyleRef)([output attribute:(id)kCTParagraphStyleAttributeName atIndex:8 effectiveRange:NULL]);
	DTCoreTextParagraphStyle *styleNatural = [DTCoreTextParagraphStyle paragraphStyleWithCTParagraphStyle:paragraphStyleNatural];
	
	STAssertTrue(styleNatural.baseWritingDirection == NSWritingDirectionNatural, @"Writing direction is not Natural");
}



// parser should get the displaySize and originalSize from local image
- (void)testAttachmentDisplaySize
{
	NSString *string = [NSString stringWithFormat:@"<img src=\"Oliver.jpg\" style=\"foo:bar\">"];
	NSAttributedString *output = [self attributedStringFromHTMLString:string options:nil];

	STAssertEquals([output length],(NSUInteger)1 , @"Output length should be 1");

	DTTextAttachment *attachment = [output attribute:NSAttachmentAttributeName atIndex:0 effectiveRange:NULL];
	
	STAssertNotNil(attachment, @"No attachment found in output");
	
	CGSize expectedSize = CGSizeMake(150, 150);
	STAssertEquals(attachment.originalSize, expectedSize, @"Non-expected originalSize");
	STAssertEquals(attachment.displaySize, expectedSize, @"Non-expected displaySize");
}

// parser should ignore "auto" value for height
- (void)testAttachmentAutoSize
{
	NSString *string = [NSString stringWithFormat:@"<img src=\"Oliver.jpg\" style=\"width:260px; height:auto;\">"];
	NSAttributedString *output = [self attributedStringFromHTMLString:string options:nil];
	
	STAssertEquals([output length],(NSUInteger)1 , @"Output length should be 1");
	
	DTTextAttachment *attachment = [output attribute:NSAttachmentAttributeName atIndex:0 effectiveRange:NULL];
	
	STAssertNotNil(attachment, @"No attachment found in output");
	
	CGSize expectedOriginalSize = CGSizeMake(150, 150);
	CGSize expectedDisplaySize = CGSizeMake(260, 260);
	
	STAssertEquals(attachment.originalSize, expectedOriginalSize, @"Non-expected originalSize");
	STAssertEquals(attachment.displaySize, expectedDisplaySize, @"Non-expected displaySize");
}

// parser should recover from no end element being sent for this img
- (void)testMissingClosingBracket
{
	NSString *string = [NSString stringWithFormat:@"<img src=\"Oliver.jpg\""];
	NSAttributedString *output = [self attributedStringFromHTMLString:string options:nil];
	
	STAssertEquals([output length],(NSUInteger)1 , @"Output length should be 1");
	
	DTTextAttachment *attachment = [output attribute:NSAttachmentAttributeName atIndex:0 effectiveRange:NULL];
	
	STAssertNotNil(attachment, @"No attachment found in output");
}


- (void)testRTLParsing
{
	NSAttributedString *output = [self attributedStringFromTestFileName:@"RTL"];

	NSUInteger paraEndIndex;
	NSRange firstParagraphRange = [[output string] rangeOfParagraphsContainingRange:NSMakeRange(0, 0) parBegIndex:NULL parEndIndex:&paraEndIndex];
	STAssertEquals(NSMakeRange(0, 22), firstParagraphRange, @"First Paragraph Range should be {0,14}");

	NSRange secondParagraphRange = [[output string] rangeOfParagraphsContainingRange:NSMakeRange(paraEndIndex, 0) parBegIndex:NULL parEndIndex:NULL];
	STAssertEquals(NSMakeRange(22, 24), secondParagraphRange, @"Second Paragraph Range should be {14,14}");

	CTParagraphStyleRef firstParagraphStyle = (__bridge CTParagraphStyleRef)([output attribute:(id)kCTParagraphStyleAttributeName atIndex:firstParagraphRange.location effectiveRange:NULL]);
	CTParagraphStyleRef secondParagraphStyle = (__bridge CTParagraphStyleRef)([output attribute:(id)kCTParagraphStyleAttributeName atIndex:secondParagraphRange.location effectiveRange:NULL]);
	
	DTCoreTextParagraphStyle *firstParaStyle = [DTCoreTextParagraphStyle paragraphStyleWithCTParagraphStyle:firstParagraphStyle];
	DTCoreTextParagraphStyle *secondParaStyle = [DTCoreTextParagraphStyle paragraphStyleWithCTParagraphStyle:secondParagraphStyle];
	
	STAssertTrue(firstParaStyle.baseWritingDirection==kCTWritingDirectionRightToLeft, @"First Paragraph Style is not RTL");
	STAssertTrue(secondParaStyle.baseWritingDirection==kCTWritingDirectionRightToLeft, @"Second Paragraph Style is not RTL");
}

- (void)testEmptyParagraphAndFontAttribute
{
	NSAttributedString *output = [self attributedStringFromTestFileName:@"EmptyLinesAndFontAttribute"];
	
	NSUInteger paraEndIndex;
	NSRange firstParagraphRange = [[output string] rangeOfParagraphsContainingRange:NSMakeRange(0, 0) parBegIndex:NULL parEndIndex:&paraEndIndex];
	STAssertEquals(NSMakeRange(0, 2), firstParagraphRange, @"First Paragraph Range should be {0,14}");
	
	NSRange secondParagraphRange = [[output string] rangeOfParagraphsContainingRange:NSMakeRange(paraEndIndex, 0) parBegIndex:NULL parEndIndex:&paraEndIndex];
	STAssertEquals(NSMakeRange(2, 1), secondParagraphRange, @"Second Paragraph Range should be {14,14}");

	NSRange thirdParagraphRange = [[output string] rangeOfParagraphsContainingRange:NSMakeRange(paraEndIndex, 0) parBegIndex:NULL parEndIndex:NULL];
	STAssertEquals(NSMakeRange(3, 1), thirdParagraphRange, @"Second Paragraph Range should be {14,14}");
	
	CTFontRef firstParagraphFont;
	NSRange firstParagraphFontRange = [self _effectiveRangeOfFontAtIndex:firstParagraphRange.location inAttributedString:output font:&firstParagraphFont];
	
	STAssertNotNil((__bridge id)firstParagraphFont, @"First paragraph font is missing");
	
	if (firstParagraphFont)
	{
		STAssertEquals(firstParagraphRange, firstParagraphFontRange, @"Range Font in first paragraph is not full paragraph");
	}

	CTFontRef secondParagraphFont;
	NSRange secondParagraphFontRange = [self _effectiveRangeOfFontAtIndex:secondParagraphRange.location inAttributedString:output font:&secondParagraphFont];
	
	STAssertNotNil((__bridge id)secondParagraphFont, @"Second paragraph font is missing");
	
	if (secondParagraphFont)
	{
		STAssertEquals(secondParagraphFontRange, secondParagraphRange, @"Range Font in second paragraph is not full paragraph");
	}
	
	CTFontRef thirdParagraphFont;
	NSRange thirdParagraphFontRange = [self _effectiveRangeOfFontAtIndex:thirdParagraphRange.location inAttributedString:output font:&thirdParagraphFont];
	
	STAssertNotNil((__bridge id)secondParagraphFont, @"Third paragraph font is missing");
	
	if (thirdParagraphFont)
	{
		STAssertEquals(thirdParagraphFontRange, thirdParagraphRange, @"Range Font in third paragraph is not full paragraph");
	}
}

// if there is a text attachment contained in a HREF then the URL of that needs to be transferred to the image because it is needed for affixing a custom subview for a link button over the image or
- (void)testTransferOfHyperlinkURLToAttachment
{
	NSAttributedString *string = [self attributedStringFromHTMLString:@"<a href=\"https://www.cocoanetics.com\"><img class=\"Bla\" style=\"width:150px; height:150px\" src=\"Oliver.jpg\"></a>" options:nil];
	
	STAssertEquals([string length], (NSUInteger)1, @"Output length should be 1");
	
	// get the attachment
	DTTextAttachment *attachment = [string attribute:NSAttachmentAttributeName atIndex:0 effectiveRange:NULL];
	
	STAssertNotNil(attachment, @"Attachment is missing");
	
	// get the link
	NSURL *URL = [string attribute:DTLinkAttribute atIndex:0 effectiveRange:NULL];
	
	STAssertNotNil(URL, @"Element URL is nil");
	
	STAssertEqualObjects(URL, attachment.hyperLinkURL, @"Attachment URL and element URL should match!");
}


// setting ordered list starting number
- (void)testOrderedListStartingNumber
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<ol start=\"5\">\n<li>Item #5</li>\n<li>Item #6</li>\n<li>etc.</li>\n</ol>" options:nil];
	NSString *string = [attributedString string];
	
	NSArray *lines = [string componentsSeparatedByString:@"\n"];
	
	STAssertEquals([lines count], (NSUInteger)4, @"There should be 4 lines"); // last one is empty
	
	NSString *line1 = lines[0];
	STAssertTrue([line1 hasPrefix:@"\t5."], @"String should have prefix 5. on first item");
	
	NSString *line2 = lines[1];
	STAssertTrue([line2 hasPrefix:@"\t6."], @"String should have prefix 6. on third item");
	
	NSString *line3 = lines[2];
	STAssertTrue([line3 hasPrefix:@"\t7."], @"String should have prefix 7. on third item");
}

- (void)testHeaderLevelTransfer
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<h3>Header</h3>" options:nil];
	
	NSNumber *headerLevelNum = [attributedString attribute:DTHeaderLevelAttribute atIndex:0 effectiveRange:NULL];
	
	STAssertNotNil(headerLevelNum, @"No Header Level Attribute");

	NSInteger level = [headerLevelNum integerValue];
	
	STAssertEquals(level, (NSInteger)3, @"Level should be 3");
}

// Issue 437, strikethrough bleeding into NL
- (void)testBleedingOutAttributes
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<p><del>abc</del></p>" options:nil];
	
	STAssertTrue([attributedString length] == 4, @"Attributed String should be 4 characters long");
	
	NSRange effectiveRange;
	NSNumber *strikethroughStyle = [attributedString attribute:DTStrikeOutAttribute atIndex:0 effectiveRange:&effectiveRange];
	
	STAssertNotNil(strikethroughStyle, @"There should be a strikethrough style");
	
	NSRange expectedRange = NSMakeRange(0, 3);
	
	STAssertEquals(effectiveRange, expectedRange, @"Strikethrough style should only contain abc, not the NL");
}

// Issue 441, display size ignored if img has width/height
- (void)testImageDisplaySize
{
	NSDictionary *options = @{DTMaxImageSize: [NSValue valueWithCGSize:CGSizeMake(200, 200)]};
	
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<img width=\"300\" height=\"300\" src=\"Oliver.jpg\">" options:options];
	
	STAssertTrue([attributedString length]==1, @"Output length should be 1");
	
	DTImageTextAttachment *imageAttachment = [attributedString attribute:NSAttachmentAttributeName atIndex:0 effectiveRange:NULL];
	
	CGSize expectedSize = CGSizeMake(200, 200);
	
	STAssertEquals(expectedSize, imageAttachment.displaySize, @"Expected size should be equal to display size");
}

#pragma mark - Non-Wellformed Content

// issue 462: Assertion Failure when attempting to parse beyond final </html> tag
- (void)testCharactersAfterEndOfHTML
{
	STAssertTrueNoThrow([self attributedStringFromHTMLString:@"<html><body><p>text</p></body></html>bla bla bla" options:nil]!=nil, @"Should be able to parse without crash");
}

// issue 447: EXC_BAD_ACCESS on Release build when accessing -[DTHTMLElement parentElement] with certain HTML data
- (void)testTagAfterEndOfHTML
{
	STAssertTrueNoThrow([self attributedStringFromHTMLString:@"<html><body><p>text</p></body></html><img>" options:nil]!=nil, @"Should be able to parse without crash");
}

#pragma mark - Fonts

// Issue 443: crash on combining font-family:inherit with small caps
- (void)testFontFamilySmallCapsCrash
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<p style=\"font-variant:small-caps; font-family:inherit;\">Test</p>" options:nil];
	
	STAssertTrue([attributedString length]==5, @"Should be 5 characters");
}

- (void)testFallbackFontFamily
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<p style=\"font-family:Calibri\">Text</p>" options:nil];
	
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:NULL];
	
	DTCoreTextFontDescriptor *fontDescriptor = [attributes fontDescriptor];
	
	STAssertEqualObjects(fontDescriptor.fontFamily, @"Times New Roman", @"Incorrect fallback font family");
}

- (void)testInvalidFontSize
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<span style=\"font-size:30px\"><p style=\"font-size:normal\">Bla</p></span>" options:nil];
	
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:NULL];
	
	DTCoreTextFontDescriptor *fontDescriptor = [attributes fontDescriptor];
	
	STAssertEquals(fontDescriptor.pointSize, (CGFloat)30, @"Should ignore invalid CSS length");
}

- (void)testFontTagWithStyle
{
	NSAttributedString *output = [self attributedStringFromHTMLString:@"<font style=\"font-size: 17pt;\"> <u>BOLUS DOSE&nbsp;&nbsp; = xx.x mg&nbsp;</u> </font>" options:nil];
	
	CTFontRef font = (__bridge CTFontRef)([output attribute:(id)kCTFontAttributeName atIndex:0 effectiveRange:NULL]);
	
	CGFloat pointSize = CTFontGetSize(font);
	
	STAssertEquals(pointSize, (CGFloat)23.0f, @"Font Size should be 23 px (= 17 pt)");
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
				STAssertEquals(fontDescriptor.pointSize, paragraphFontSize, @"Font in range %@ does not match paragraph font size of %.1fpx", NSStringFromRange(range), paragraphFontSize);
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
		
		STAssertEquals(enclosingRange, fontRange, @"Font should be on entire string");
		
		DTCoreTextFontDescriptor *fontDescriptor = [DTCoreTextFontDescriptor fontDescriptorForCTFont:font];
		
		switch (lineNumber) {
			case 0:
			{
				STAssertEqualObjects(fontDescriptor.fontFamily, @"Helvetica", @"Font family should be Helvetica");
				STAssertEqualObjects(fontDescriptor.fontName, @"Helvetica", @"Font face should be Helvetica");
				break;
			}
				
			case 1:
			{
				STAssertEqualObjects(fontDescriptor.fontFamily, @"Helvetica", @"Font family should be Helvetica");
				STAssertEqualObjects(fontDescriptor.fontName, @"Helvetica-Bold", @"Font face should be Helvetica");
				break;
			}
			case 2:
			{
				STAssertEqualObjects(fontDescriptor.fontFamily, @"Helvetica", @"Font family should be Helvetica");
				STAssertEqualObjects(fontDescriptor.fontName, @"Helvetica-Oblique", @"Font face should be Helvetica-Oblique");
				break;
			}
			case 3:
			{
				STAssertEqualObjects(fontDescriptor.fontFamily, @"Helvetica", @"Font family should be Helvetica");
				STAssertEqualObjects(fontDescriptor.fontName, @"Helvetica-BoldOblique", @"Font face should be Helvetica-BoldOblique");
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
	STAssertTrueNoThrow([self attributedStringFromHTMLString:@"<p style=\"font-family:Helvetica,sans-serif\">Text</p>" options:nil]!=nil, @"Should be able to parse without crash");
}

// issue 538
- (void)testMultipleFontFamiliesSelection
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<p style=\"font-family:'American Typewriter',sans-serif\">Text</p>" options:nil];
	
	CTFontRef font;
	NSRange fontRange = [self _effectiveRangeOfFontAtIndex:0 inAttributedString:attributedString font:&font];
	
	NSRange expectedRange = NSMakeRange(0, [attributedString length]);
	STAssertEquals(fontRange, expectedRange, @"Font should be entire length");
	
	DTCoreTextFontDescriptor *descriptor = [DTCoreTextFontDescriptor fontDescriptorForCTFont:font];
	
	STAssertEqualObjects(descriptor.fontFamily, @"American Typewriter", @"Font Family should be 'American Typewriter'");
}

// issue 538
- (void)testMultipleFontFamiliesSelectionLaterPosition
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<p style=\"font-family:foo,'American Typewriter'\">Text</p>" options:nil];
	
	CTFontRef font;
	NSRange fontRange = [self _effectiveRangeOfFontAtIndex:0 inAttributedString:attributedString font:&font];
	
	NSRange expectedRange = NSMakeRange(0, [attributedString length]);
	STAssertEquals(fontRange, expectedRange, @"Font should be entire length");
	
	DTCoreTextFontDescriptor *descriptor = [DTCoreTextFontDescriptor fontDescriptorForCTFont:font];
	
	STAssertEqualObjects(descriptor.fontFamily, @"American Typewriter", @"Font Family should be 'American Typewriter'");
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
				STAssertEquals(numLists, (NSInteger)2, @"There should be two lists active on line 2, but %d found", numLists);
				
				NSString *subString = [[attributedSubstring string] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
				
				STAssertTrue([subString hasSuffix:@"Bullet 2"], @"The second line should have the 'Bullet 2' text");
				
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
		
		STAssertFalse(foundNL, @"Newline in prefix of line %d", lineNumber);
		
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
		STAssertTrue(characterIsCorrect, @"Bullet Character on UL level %d should be '%@' but is '%@'", lineNumber+1, expectedChar, bulletChar);
		
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
		STAssertTrue(prefixIsCorrect, @"Prefix level %d should be '%@' but is '%@'", lineNumber+1, expectedPrefix, prefix);
		
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
	
	STAssertNotNil(backgroundColor, @"Missing Background Color");
	
	NSRange expectedRange = NSMakeRange(3, 5);
	
	STAssertEquals(effectiveRange, expectedRange, @"Range is not correct");
	
	NSString *colorHex = DTHexStringFromDTColor(backgroundColor);
	
	STAssertEqualObjects(colorHex, @"ff0000", @"Color should be red");
}

- (void)testTextListRanges
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<ol><li>1a<ul><li>2a</li></ul></li><li>more</li><li>more</li></ol>" options:NULL];
	
	NSArray *lists = [attributedString attribute:DTTextListsAttribute atIndex:0 effectiveRange:NULL];
	
	STAssertTrue([lists count]==1, @"There should be 1 outer list");
	
	DTCSSListStyle *outerList = [lists lastObject];
	
	NSRange list1Range = [attributedString rangeOfTextList:outerList atIndex:0];
	
	STAssertTrue(!list1Range.location, @"lists should start at index 0");
	STAssertTrue(list1Range.length, @"lists should range for entire string");
	
	NSRange innerRange = [[attributedString string] rangeOfString:@"2a"];
	NSArray *innerLists = [attributedString attribute:DTTextListsAttribute atIndex:innerRange.location effectiveRange:NULL];
	
	STAssertTrue([innerLists count]==2, @"There should be 2 inner lists");
	
	if ([innerLists count])
	{
		STAssertTrue([innerLists objectAtIndex:0] == outerList , @"list at index 0 in inner lists should be same as outer list");
	}
	
	NSRange list2Range = [attributedString rangeOfTextList:[innerLists lastObject] atIndex:innerRange.location];
	NSRange innerParagraph = [[attributedString string] paragraphRangeForRange:innerRange];
	
	STAssertEquals(innerParagraph, list2Range, @"Inner list range should be equal to inner paragraph");
}


// issue 625
- (void)testEmptyListItemWithSubList
{
	// first paragraph should have one lists
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<ul>\n<li>\n<ol>\n<li>Foo</li>\n<li>Bar</li>\n</ol>\n</li>\n<li>BLAH</li>\n</ul>" options:NULL];
	NSRange firstParagraphRange = [[attributedString string] paragraphRangeForRange:NSMakeRange(0, 1)];
	NSArray *firstParagraphLists = [attributedString attribute:DTTextListsAttribute atIndex:firstParagraphRange.location effectiveRange:NULL];
	NSUInteger firstListsCount = [firstParagraphLists count];
	
	STAssertTrue(firstListsCount == 1, @"There should be two lists on the first paragraph");
	
	// all lists in the first paragraph should be at least covering the entire paragraph
	
	[firstParagraphLists enumerateObjectsUsingBlock:^(DTCSSListStyle *oneList, NSUInteger idx, BOOL *stop) {
		
		NSRange listRange = [attributedString rangeOfTextList:oneList atIndex:firstParagraphRange.location];
		
		NSRange commonRange = NSIntersectionRange(listRange, firstParagraphRange);
		
		STAssertTrue(NSEqualRanges(commonRange, firstParagraphRange), @"List %d does not cover entire paragraph", idx+1);
	}];
	
	// second paragraph should have two lists
	NSRange secondParagraphRange = [[attributedString string] paragraphRangeForRange:NSMakeRange(NSMaxRange(firstParagraphRange),1)];
	NSArray *secondParagraphLists = [attributedString attribute:DTTextListsAttribute atIndex:secondParagraphRange.location effectiveRange:NULL];
	NSUInteger secondListsCount = [secondParagraphLists count];
	
	STAssertTrue(secondListsCount == 2, @"There should be two lists on the first paragraph");
	
	// all lists in the second paragraph should be at least covering the entire paragraph
	
	[secondParagraphLists enumerateObjectsUsingBlock:^(DTCSSListStyle *oneList, NSUInteger idx, BOOL *stop) {
		
		NSRange listRange = [attributedString rangeOfTextList:oneList atIndex:secondParagraphRange.location];
		
		NSRange commonRange = NSIntersectionRange(listRange, secondParagraphRange);
		
		STAssertTrue(NSEqualRanges(commonRange, secondParagraphRange), @"List %d does not cover entire paragraph", idx+1);
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
	STAssertTrue([underLine1 integerValue]==1, @"First item should be underlined");
	DTColor *foreground1 = [attributes1 foregroundColor];
	NSString *foreground1HTML =  DTHexStringFromDTColor(foreground1);
	BOOL colorOk1 = ([foreground1HTML isEqualToString:@"008000"]);
	STAssertTrue(colorOk1, @"First item should be green");
	BOOL isBold1 = [[attributes1 fontDescriptor] boldTrait];
	STAssertTrue(isBold1, @"First item should be bold");
	BOOL isItalic1 = [[attributes1 fontDescriptor] italicTrait];
	STAssertFalse(isItalic1, @"First item should not be italic");

	// check first "buzz"
	NSDictionary *attributes2 = [output attributesAtIndex:index2 effectiveRange:NULL];
	NSNumber *underLine2 = [output attribute:(id)kCTUnderlineStyleAttributeName atIndex:index2 effectiveRange:NULL];
	STAssertTrue([underLine2 integerValue]==1, @"Second item should be underlined");
	DTColor *foreground2 = [attributes2 foregroundColor];
	NSString *foreground2HTML = DTHexStringFromDTColor(foreground2);
	BOOL colorOk2 = ([foreground2HTML isEqualToString:@"800080"]);
	STAssertTrue(colorOk2, @"Second item should be purple");
	BOOL isBold2 = [[attributes2 fontDescriptor] boldTrait];
	STAssertTrue(isBold2, @"Second item should be bold");

	// check second "owzers"
	NSDictionary *attributes3 = [output attributesAtIndex:index3 effectiveRange:NULL];
	NSNumber *underLine3 = [output attribute:(id)kCTUnderlineStyleAttributeName atIndex:index3 effectiveRange:NULL];
	STAssertTrue([underLine3 integerValue]==1, @"Third item should be underlined");
	NSNumber *strikeThrough3 = [output attribute:DTStrikeOutAttribute atIndex:index3 effectiveRange:NULL];
	STAssertTrue([strikeThrough3 integerValue]==1, @"Third item should have strike through");
	DTColor *foreground3 = [attributes3 foregroundColor];
	NSString *foreground3HTML = DTHexStringFromDTColor(foreground3);
	BOOL colorOk3 = ([foreground3HTML isEqualToString:@"ffa500"]);
	STAssertTrue(colorOk3, @"Third item should be orange");
	BOOL isBold3 = [[attributes3 fontDescriptor] boldTrait];
	STAssertFalse(isBold3, @"Third item should not be bold");
	BOOL isItalic3 = [[attributes3 fontDescriptor] italicTrait];
	STAssertTrue(isItalic3, @"Third item should be italic");
	
	// check second "Me"
	NSDictionary *attributes4 = [output attributesAtIndex:index4 effectiveRange:NULL];
	NSNumber *underLine4 = [output attribute:(id)kCTUnderlineStyleAttributeName atIndex:index4 effectiveRange:NULL];
	STAssertFalse([underLine4 integerValue]==1, @"Fourth item should be not underlined");
	DTColor *foreground4 = [attributes4 foregroundColor];
	NSString *foreground4HTML = DTHexStringFromDTColor(foreground4);
	BOOL colorOk4 = ([foreground4HTML isEqualToString:@"ff0000"]);
	STAssertTrue(colorOk4, @"Fourth item should be red");
	BOOL isBold4 = [[attributes4 fontDescriptor] boldTrait];
	STAssertFalse(isBold4, @"Fourth item should not be bold");
	BOOL isItalic4 = [[attributes4 fontDescriptor] italicTrait];
	STAssertFalse(isItalic4, @"Fourth item should not be italic");

	// check second "ow"
	NSDictionary *attributes5 = [output attributesAtIndex:index5 effectiveRange:NULL];
	NSNumber *underLine5 = [output attribute:(id)kCTUnderlineStyleAttributeName atIndex:index5 effectiveRange:NULL];
	STAssertTrue([underLine5 integerValue]==1, @"Fifth item should be underlined");
	DTColor *foreground5 = [attributes5 foregroundColor];
	NSString *foreground5HTML = DTHexStringFromDTColor(foreground5);
	BOOL colorOk5 = ([foreground5HTML isEqualToString:@"008000"]);
	STAssertTrue(colorOk5, @"Fifth item should be green");
	BOOL isBold5 = [[attributes5 fontDescriptor] boldTrait];
	STAssertTrue(isBold5, @"Fifth item should be bold");
	BOOL isItalic5 = [[attributes5 fontDescriptor] italicTrait];
	STAssertFalse(isItalic5, @"Fifth item should not be italic");

	// check second "this is a test of by tag name..."
	NSDictionary *attributes6 = [output attributesAtIndex:index6 effectiveRange:NULL];
	NSNumber *underLine6 = [output attribute:(id)kCTUnderlineStyleAttributeName atIndex:index6 effectiveRange:NULL];
	STAssertTrue([underLine6 integerValue]==1, @"Sixth item should be underlined");
	DTColor *foreground6 = [attributes6 foregroundColor];
	NSString *foreground6HTML = DTHexStringFromDTColor(foreground6);
	BOOL colorOk6 = ([foreground6HTML isEqualToString:@"ffa500"]);
	STAssertTrue(colorOk6, @"Sixth item should be orange");
	BOOL isBold6 = [[attributes6 fontDescriptor] boldTrait];
	STAssertFalse(isBold6, @"Sixth item should not be bold");
	BOOL isItalic6 = [[attributes6 fontDescriptor] italicTrait];
	STAssertTrue(isItalic6, @"Sixth item should be italic");

	// check second "i'm gray text"
	NSDictionary *attributes7 = [output attributesAtIndex:index7 effectiveRange:NULL];
	NSNumber *underLine7 = [output attribute:(id)kCTUnderlineStyleAttributeName atIndex:index7 effectiveRange:NULL];
	STAssertFalse([underLine7 integerValue]==1, @"Seventh item should not be underlined");
	DTColor *foreground7 = [attributes7 foregroundColor];
	NSString *foreground7HTML = DTHexStringFromDTColor(foreground7);
	BOOL colorOk7 = ([foreground7HTML isEqualToString:@"777777"]);
	STAssertTrue(colorOk7, @"Seventh item should be gray");
	BOOL isBold7 = [[attributes7 fontDescriptor] boldTrait];
	STAssertFalse(isBold7, @"Seventh item should not be bold");
	BOOL isItalic7 = [[attributes7 fontDescriptor] italicTrait];
	STAssertFalse(isItalic7, @"Seventh item should not be italic");
}

// issue 555
- (void)testCascadingOutOfMemory
{
	NSDate *startTime = [NSDate date];
	NSAttributedString *attributedString = [self attributedStringFromTestFileName:@"CSSOOMCrash"];
	STAssertTrueNoThrow(attributedString != nil, @"Should be able to parse without running out of memory");
	STAssertTrue(([[NSDate date] timeIntervalSinceDate:startTime]) < 0.5f, @"Test should run in less than 0.5 seconds. Prior to fix, it took 16.85 seconds to run this test.");
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
	
	STAssertEquals(text1FontDescriptor.pointSize, text2FontDescriptor.pointSize, @"Point size should be the same when font-size is cascaded and inherited.");
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

	STAssertEqualObjects(foreground1HTML, foreground2HTML, @"Color should be inherited via cascaded selector.");
}

- (void)testSubstringCascadedSelectorsBeingProperlyApplied
{
	NSString *html = @"<html><head><style> body .sample { color: red;} body .samples { color: green;}</style></head><body><div class=\"samples\">Text</div></html>";
	NSAttributedString *output = [self attributedStringFromHTMLString:html options:nil];
	
	NSDictionary *attributes = [output attributesAtIndex:1 effectiveRange:NULL];
	DTColor *foreground = [attributes foregroundColor];
	NSString *foregroundHTML = DTHexStringFromDTColor(foreground);
	STAssertEqualObjects(foregroundHTML, @"008000", @"Color should be green and not red.");
}

- (void)testCascadedSelectorSpecificity {
	NSString *html = @"<html><head><style> #foo .bar { font-size: 225px; color: green; } body #foo .bar { font-size: 24px; } #foo .bar { font-size: 100px; color: red; }</style> </head><body><div id=\"foo\"><div class=\"bar\">Text</div></div></body></html>";
	NSAttributedString *output = [self attributedStringFromHTMLString:html options:nil];
	
	NSDictionary *attributes = [output attributesAtIndex:1 effectiveRange:NULL];
	DTColor *foreground = [attributes foregroundColor];
	NSString *foregroundHTML = DTHexStringFromDTColor(foreground);
	STAssertEqualObjects(foregroundHTML, @"ff0000", @"Color should be red and not green.");

	DTCoreTextFontDescriptor *textFontDescriptor = [attributes fontDescriptor];
	STAssertTrue(textFontDescriptor.pointSize == 24.0f, @"Point size should 24 and not 225 or 100.");
}

- (void)testCascadedSelectorsWithEqualSpecificityLastDeclarationWins {
	NSString *html = @"<html><head><style>#foo .bar { color: red; } #foo .bar { color: green; }</style> </head><body><div id=\"foo\"><div class=\"bar\">Text</div></div></body></html>";
	NSAttributedString *output = [self attributedStringFromHTMLString:html options:nil];
	
	NSDictionary *attributes = [output attributesAtIndex:1 effectiveRange:NULL];
	DTColor *foreground = [attributes foregroundColor];
	NSString *foregroundHTML = DTHexStringFromDTColor(foreground);
	STAssertEqualObjects(foregroundHTML, @"008000", @"Color should be green and not red.");

	NSString *html2 = @"<html><head><style>.bar { color: red; } .foo { color: green; } </style> </head><body><div class=\"foo\"><div class=\"bar\"><div>Text</div></div></div></body></html>";
	NSAttributedString *output2 = [self attributedStringFromHTMLString:html2 options:nil];
	NSDictionary *attributes2 = [output2 attributesAtIndex:1 effectiveRange:NULL];
	DTColor *foreground2 = [attributes2 foregroundColor];
	NSString *foregroundHTML2 = DTHexStringFromDTColor(foreground2);
	STAssertEqualObjects(foregroundHTML2, @"ff0000", @"Color should be red and not green.");
}

// text should be green even though there is a span following the div-div.
- (void)testDivDivSpan
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<html><head><style>div div {color:green;}</style></head><body><div><div><span>FOO</span></div></div></body></html>" options:nil];
	
	NSDictionary *attributes1 = [attributedString attributesAtIndex:0 effectiveRange:NULL];
	DTColor *foreground1 = [attributes1 foregroundColor];
	NSString *foreground1HTML = DTHexStringFromDTColor(foreground1);
	BOOL colorOk1 = ([foreground1HTML isEqualToString:@"008000"]);
	STAssertTrue(colorOk1, @"First item should be green");
}

- (void)testLetterSpacing
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<h1 style=\"font-variant: small-caps; letter-spacing:10px\">one</h1>" options:NULL];
	
	NSDictionary *attributes1 = [attributedString attributesAtIndex:0 effectiveRange:NULL];
	
	CGFloat kerning = [attributes1 kerning];
	
	STAssertTrue(kerning == 10, @"Kerning should be 10px");
}

// issue 636
- (void)testDisplayStyleInheritance
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<html><head><style>	.container { display: block; }	span.test { font-style:italic; }</style></head><body><div class='container'>\n    before  <span class='test'>test</span> after\n</div></body></html>" options:NULL];
	
	
	NSArray *lines = [[[attributedString string] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsSeparatedByString:@"\n"];
	STAssertTrue([lines count]==1, @"There should only be one line, display style block should not be inherited");
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
	STAssertEquals(expectedRange, effectiveRange, @"Attributes should cover all text");
	
	DTColor *color = [attributes foregroundColor];
	NSString *hexColor = DTHexStringFromDTColor(color);
	
	STAssertEqualObjects(hexColor, @"ff0000", @"Color should be red because inline style should be ignored through option");
}

// issue 649
- (void)testProcessInlineStyle
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<html><head><style>.container { color: red }</style></head><body><span class='container' style=\"color: blue\">Text</span></body></html>" options:NULL];
	
	NSRange effectiveRange;
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:&effectiveRange];
	
	NSRange expectedRange = NSMakeRange(0, [attributedString length]);
	STAssertEquals(expectedRange, effectiveRange, @"Attributes should cover all text");
	
	DTColor *color = [attributes foregroundColor];
	NSString *hexColor = DTHexStringFromDTColor(color);
	
	STAssertEqualObjects(hexColor, @"0000ff", @"Color should be blue because inline style should be processed through lack of ignore option");
}

@end
