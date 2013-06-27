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

- (NSAttributedString *)_attributedStringFromTestFileName:(NSString *)testFileName
{
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *path = [bundle pathForResource:testFileName ofType:@"html"];
	NSData *data = [NSData dataWithContentsOfFile:path];
	
	DTHTMLAttributedStringBuilder *builder = [[DTHTMLAttributedStringBuilder alloc] initWithHTML:data options:nil documentAttributes:NULL];
	return [builder generatedAttributedString];
}

- (NSAttributedString *)_attributedStringFromHTMLString:(NSString *)HTMLString options:(NSDictionary *)options
{
	NSData *data = [HTMLString dataUsingEncoding:NSUTF8StringEncoding];
	
	// set the base URL so that resources are found in the resource bundle
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSURL *baseURL = [bundle resourceURL];
	
	NSMutableDictionary *mutableOptions = [[NSMutableDictionary alloc] initWithDictionary:options];
	mutableOptions[NSBaseURLDocumentOption] = baseURL;
	
	
	DTHTMLAttributedStringBuilder *builder = [[DTHTMLAttributedStringBuilder alloc] initWithHTML:data options:mutableOptions documentAttributes:NULL];
	return [builder generatedAttributedString];
}

#pragma mark - Whitespace

- (void)testSpaceBetweenUnderlines
{
	NSAttributedString *output = [self _attributedStringFromTestFileName:@"SpaceBetweenUnderlines"];
	
	NSRange range_a;
	NSNumber *underLine = [output attribute:(id)kCTUnderlineStyleAttributeName atIndex:1 effectiveRange:&range_a];
	
	STAssertTrue([underLine integerValue]==0, @"Space between a and b should not be underlined");
}

// a block following an inline image should only cause a \n after the image, not whitespace
- (void)testWhitspaceAfterParagraphPromotedImage
{
	NSAttributedString *output = [self _attributedStringFromTestFileName:@"WhitespaceFollowingImagePromotedToParagraph"];
	
	STAssertTrue([output length]==6, @"Generated String should be 6 characters");
	
	NSMutableString *expectedOutput = [NSMutableString stringWithFormat:@"1\n%@\n2\n", UNICODE_OBJECT_PLACEHOLDER];
	
	STAssertTrue([expectedOutput isEqualToString:[output string]], @"Expected output not matching");
}

// This should come out as Keep_me_together with the _ being non-breaking spaces
- (void)testKeepMeTogether
{
	NSAttributedString *output = [self _attributedStringFromTestFileName:@"KeepMeTogether"];
	
	NSString *expectedOutput = @"Keep\u00a0me\u00a0together";
	
	STAssertTrue([expectedOutput isEqualToString:[output string]], @"Expected output not matching");
}

// issue 466: Support Encoding of Tabs in HTML
- (void)testTabDecodingAndPreservation
{
	NSAttributedString *output = [self _attributedStringFromHTMLString:@"Some text and then 2 encoded<span style=\"white-space:pre\">&#9;&#9</span>tabs and 2 non-encoded		tabs" options:nil];
	
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

#pragma mark - General Tests

// tests functionality of dir attribute
- (void)testWritingDirection
{
	NSAttributedString *output = [self _attributedStringFromHTMLString:@"<p dir=\"rtl\">rtl</p><p dir=\"ltr\">ltr</p><p>normal</p>" options:nil];
	
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
	NSAttributedString *output = [self _attributedStringFromHTMLString:string options:nil];

	STAssertEquals([output length],(NSUInteger)1 , @"Output length should be 1");

	DTTextAttachment *attachment = [output attribute:NSAttachmentAttributeName atIndex:0 effectiveRange:NULL];
	
	STAssertNotNil(attachment, @"No attachment found in output");
	
	CGSize expectedSize = CGSizeMake(300, 300);
	STAssertEquals(attachment.originalSize, expectedSize, @"Expected originalSize to be 300x300");
	STAssertEquals(attachment.displaySize, expectedSize, @"Expected displaySize to be 300x300");
}

// parser should ignore "auto" value for height
- (void)testAttachmentAutoSize
{
	NSString *string = [NSString stringWithFormat:@"<img src=\"Oliver.jpg\" style=\"width:260px; height:auto;\">"];
	NSAttributedString *output = [self _attributedStringFromHTMLString:string options:nil];
	
	STAssertEquals([output length],(NSUInteger)1 , @"Output length should be 1");
	
	DTTextAttachment *attachment = [output attribute:NSAttachmentAttributeName atIndex:0 effectiveRange:NULL];
	
	STAssertNotNil(attachment, @"No attachment found in output");
	
	CGSize expectedOriginalSize = CGSizeMake(300, 300);
	CGSize expectedDisplaySize = CGSizeMake(260, 260);
	
	STAssertEquals(attachment.originalSize, expectedOriginalSize, @"Expected originalSize to be 300x300");
	STAssertEquals(attachment.displaySize, expectedDisplaySize, @"Expected displaySize to be 260x260");
}

// parser should recover from no end element being sent for this img
- (void)testMissingClosingBracket
{
	NSString *string = [NSString stringWithFormat:@"<img src=\"Oliver.jpg\""];
	NSAttributedString *output = [self _attributedStringFromHTMLString:string options:nil];
	
	STAssertEquals([output length],(NSUInteger)1 , @"Output length should be 1");
	
	DTTextAttachment *attachment = [output attribute:NSAttachmentAttributeName atIndex:0 effectiveRange:NULL];
	
	STAssertNotNil(attachment, @"No attachment found in output");
}


- (void)testRTLParsing
{
	NSAttributedString *output = [self _attributedStringFromTestFileName:@"RTL"];

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
	NSAttributedString *output = [self _attributedStringFromTestFileName:@"EmptyLinesAndFontAttribute"];
	
	NSUInteger paraEndIndex;
	NSRange firstParagraphRange = [[output string] rangeOfParagraphsContainingRange:NSMakeRange(0, 0) parBegIndex:NULL parEndIndex:&paraEndIndex];
	STAssertEquals(NSMakeRange(0, 2), firstParagraphRange, @"First Paragraph Range should be {0,14}");
	
	NSRange secondParagraphRange = [[output string] rangeOfParagraphsContainingRange:NSMakeRange(paraEndIndex, 0) parBegIndex:NULL parEndIndex:&paraEndIndex];
	STAssertEquals(NSMakeRange(2, 1), secondParagraphRange, @"Second Paragraph Range should be {14,14}");

	NSRange thirdParagraphRange = [[output string] rangeOfParagraphsContainingRange:NSMakeRange(paraEndIndex, 0) parBegIndex:NULL parEndIndex:NULL];
	STAssertEquals(NSMakeRange(3, 1), thirdParagraphRange, @"Second Paragraph Range should be {14,14}");
	
	NSRange firstParagraphFontRange;
	CTFontRef firstParagraphFont = (__bridge CTFontRef)([output attribute:(id)kCTFontAttributeName atIndex:firstParagraphRange.location effectiveRange:&firstParagraphFontRange]);
	
	STAssertNotNil((__bridge id)firstParagraphFont, @"First paragraph font is missing");
	
	if (firstParagraphFont)
	{
		STAssertEquals(firstParagraphRange, firstParagraphFontRange, @"Range Font in first paragraph is not full paragraph");
	}

	NSRange secondParagraphFontRange;
	CTFontRef secondParagraphFont = (__bridge CTFontRef)([output attribute:(id)kCTFontAttributeName atIndex:secondParagraphRange.location effectiveRange:&secondParagraphFontRange]);
	
	STAssertNotNil((__bridge id)secondParagraphFont, @"Second paragraph font is missing");
	
	if (secondParagraphFont)
	{
		STAssertEquals(secondParagraphFontRange, secondParagraphRange, @"Range Font in second paragraph is not full paragraph");
	}
	
	NSRange thirdParagraphFontRange;
	CTFontRef thirdParagraphFont = (__bridge CTFontRef)([output attribute:(id)kCTFontAttributeName atIndex:thirdParagraphRange.location effectiveRange:&thirdParagraphFontRange]);
	
	STAssertNotNil((__bridge id)secondParagraphFont, @"Third paragraph font is missing");
	
	if (thirdParagraphFont)
	{
		STAssertEquals(thirdParagraphFontRange, thirdParagraphRange, @"Range Font in third paragraph is not full paragraph");
	}
}

// if there is a text attachment contained in a HREF then the URL of that needs to be transferred to the image because it is needed for affixing a custom subview for a link button over the image or
- (void)testTransferOfHyperlinkURLToAttachment
{
	NSAttributedString *string = [self _attributedStringFromHTMLString:@"<a href=\"https://www.cocoanetics.com\"><img class=\"Bla\" style=\"width:150px; height:150px\" src=\"Oliver.jpg\"></a>" options:nil];
	
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
	NSAttributedString *attributedString = [self _attributedStringFromHTMLString:@"<ol start=\"5\">\n<li>Item #5</li>\n<li>Item #6</li>\n<li>etc.</li>\n</ol>" options:nil];
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
	NSAttributedString *attributedString = [self _attributedStringFromHTMLString:@"<h3>Header</h3>" options:nil];
	
	NSNumber *headerLevelNum = [attributedString attribute:DTHeaderLevelAttribute atIndex:0 effectiveRange:NULL];
	
	STAssertNotNil(headerLevelNum, @"No Header Level Attribute");

	NSInteger level = [headerLevelNum integerValue];
	
	STAssertEquals(level, (NSInteger)3, @"Level should be 3");
}

// Issue 437, strikethrough bleeding into NL
- (void)testBleedingOutAttributes
{
	NSAttributedString *attributedString = [self _attributedStringFromHTMLString:@"<p><del>abc</del></p>" options:nil];
	
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
	
	NSAttributedString *attributedString = [self _attributedStringFromHTMLString:@"<img width=\"300\" height=\"300\" src=\"Oliver.jpg\">" options:options];
	
	STAssertTrue([attributedString length]==1, @"Output length should be 1");
	
	DTImageTextAttachment *imageAttachment = [attributedString attribute:NSAttachmentAttributeName atIndex:0 effectiveRange:NULL];
	
	CGSize expectedSize = CGSizeMake(200, 200);
	
	STAssertEquals(expectedSize, imageAttachment.displaySize, @"Expected size should be equal to display size");
}

#pragma mark - Non-Wellformed Content

// issue 462: Assertion Failure when attempting to parse beyond final </html> tag
- (void)testCharactersAfterEndOfHTML
{
	STAssertTrueNoThrow([self _attributedStringFromHTMLString:@"<html><body><p>text</p></body></html>bla bla bla" options:nil]!=nil, @"Should be able to parse without crash");
}

// issue 447: EXC_BAD_ACCESS on Release build when accessing -[DTHTMLElement parentElement] with certain HTML data
- (void)testTagAfterEndOfHTML
{
	STAssertTrueNoThrow([self _attributedStringFromHTMLString:@"<html><body><p>text</p></body></html><img>" options:nil]!=nil, @"Should be able to parse without crash");
}

#pragma mark - Fonts

// Issue 443: crash on combining font-family:inherit with small caps
- (void)testFontFamilySmallCapsCrash
{
	NSAttributedString *attributedString;
	
	STAssertTrueNoThrow((attributedString = [self _attributedStringFromHTMLString:@"<p style=\"font-variant:small-caps; font-family:inherit;\">Test</p>" options:nil]), @"Should be able to parse without crash");
	
	STAssertTrue([attributedString length]==5, @"Should be 5 characters");
}

- (void)testFallbackFontFamily
{
	NSAttributedString *attributedString = [self _attributedStringFromHTMLString:@"<p style=\"font-family:Calibri\">Text</p>" options:nil];
	
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:NULL];
	
	DTCoreTextFontDescriptor *fontDescriptor = [attributes fontDescriptor];
	
	STAssertEqualObjects(fontDescriptor.fontFamily, @"Times New Roman", @"Incorrect fallback font family");
}

- (void)testInvalidFontSize
{
	NSAttributedString *attributedString = [self _attributedStringFromHTMLString:@"<span style=\"font-size:30px\"><p style=\"font-size:normal\">Bla</p></span>" options:nil];
	
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:NULL];
	
	DTCoreTextFontDescriptor *fontDescriptor = [attributes fontDescriptor];
	
	STAssertEquals(fontDescriptor.pointSize, (CGFloat)30, @"Should ignore invalid CSS length");
}

- (void)testFontTagWithStyle
{
	NSAttributedString *output = [self _attributedStringFromHTMLString:@"<font style=\"font-size: 17pt;\"> <u>BOLUS DOSE&nbsp;&nbsp; = xx.x mg&nbsp;</u> </font>" options:nil];
	
	CTFontRef font = (__bridge CTFontRef)([output attribute:(id)kCTFontAttributeName atIndex:0 effectiveRange:NULL]);
	
	CGFloat pointSize = CTFontGetSize(font);
	
	STAssertEquals(pointSize, (CGFloat)23.0f, @"Font Size should be 23 px (= 17 pt)");
}

- (void)testFontSizeInterpretation
{
	NSAttributedString *output = [self _attributedStringFromTestFileName:@"FontSizes"];
	
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
	NSAttributedString *attributedString = [self _attributedStringFromHTMLString:@"<p style=\"font-family:Helvetica\">Regular</p><p style=\"font-family:Helvetica;font-weight:bold;\">Bold</p><p style=\"font-family:Helvetica;font-style:italic;}\">Italic</p><p style=\"font-family:Helvetica;font-style:italic;font-weight:bold;}\">Bold+Italic</p>" options:nil];
	
	NSString *string = [attributedString string];
	NSRange entireStringRange = NSMakeRange(0, [string length]);
	
	__block NSUInteger lineNumber = 0;
	
	[string enumerateSubstringsInRange:entireStringRange options:NSStringEnumerationByParagraphs usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
		
		NSRange fontRange;
		CTFontRef font = (__bridge CTFontRef)([attributedString attribute:(id)kCTFontAttributeName atIndex:substringRange.location effectiveRange:&fontRange]);
		
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

#pragma mark - Nested Lists

- (void)testNestedListWithStyleNone
{
	NSAttributedString *attributedString = [self _attributedStringFromHTMLString:@"<ul><li>Bullet</li><li style=\"list-style: none\"><ul><li>Bullet 2</li></ul></li></ul>" options:nil];
	
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
	NSAttributedString *attributedString = [self _attributedStringFromHTMLString:@"<ul><li>Bullet</li><li><ul><li>Bullet 2</li></ul></li></ul>" options:nil];
	
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

@end
