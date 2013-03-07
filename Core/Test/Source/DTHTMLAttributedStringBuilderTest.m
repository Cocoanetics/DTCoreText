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

- (NSAttributedString *)_attributedStringFromHTMLString:(NSString *)HTMLString
{
	NSData *data = [HTMLString dataUsingEncoding:NSUTF8StringEncoding];
	
	DTHTMLAttributedStringBuilder *builder = [[DTHTMLAttributedStringBuilder alloc] initWithHTML:data options:nil documentAttributes:NULL];
	return [builder generatedAttributedString];
}


#pragma mark - Tests

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

// tests functionality of dir attribute
- (void)testWritingDirection
{
	NSAttributedString *output = [self _attributedStringFromHTMLString:@"<p dir=\"rtl\">rtl</p><p dir=\"ltr\">ltr</p><p>normal</p>"];
	
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

- (void)testAttachmentDisplaySize
{
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *imagePath = [bundle pathForResource:@"Oliver" ofType:@"jpg"];
	NSString *string = [NSString stringWithFormat:@"<img src=\"file:%@\" style=\"foo:bar\">", imagePath];
	NSAttributedString *output = [self _attributedStringFromHTMLString:string];

	STAssertEquals([output length],(NSUInteger)1 , @"Output length should be 1");

	DTTextAttachment *attachment = [output attribute:NSAttachmentAttributeName atIndex:0 effectiveRange:NULL];
	
	STAssertNotNil(attachment, @"No attachment found in output");
	
	CGSize expectedSize = CGSizeMake(300, 300);
	STAssertEquals(attachment.originalSize, expectedSize, @"Expected displaySize to be 300x300");
	STAssertEquals(attachment.displaySize, expectedSize, @"Expected displaySize to be 300x300");
}

- (void)testFontTagWithStyle
{
	NSAttributedString *output = [self _attributedStringFromHTMLString:@"<font style=\"font-size: 17pt;\"> <u>BOLUS DOSE&nbsp;&nbsp; = xx.x mg&nbsp;</u> </font>"];
	
	CTFontRef font = (__bridge CTFontRef)([output attribute:(id)kCTFontAttributeName atIndex:0 effectiveRange:NULL]);
	
	CGFloat pointSize = CTFontGetSize(font);
	
	STAssertEquals(pointSize, (CGFloat)23.0f, @"Font Size should be 23 px (= 17 pt)");
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

- (void)testFontSizeInterpretation
{
	NSAttributedString *output = [self _attributedStringFromTestFileName:@"FontSizes"];

	NSUInteger paraEndIndex = 0;
	
	while (paraEndIndex<[output length])
	{
		NSRange paragraphRange = [[output string] rangeOfParagraphsContainingRange:NSMakeRange(paraEndIndex, 0) parBegIndex:NULL parEndIndex:&paraEndIndex];
		
		__block CGFloat paragraphFontSize = 0; // initialized from first font in paragraph
		
		[output enumerateAttribute:(id)kCTFontAttributeName inRange:paragraphRange options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
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


// if there is a text attachment contained in a HREF then the URL of that needs to be transferred to the image because it is needed for affixing a custom subview for a link button over the image or 
- (void)testTransferOfHyperlinkURLToAttachment
{
	NSAttributedString *string = [self _attributedStringFromHTMLString:@"<a href=\"https://www.cocoanetics.com\"><img class=\"Bla\" style=\"width:150px; height:150px\" src=\"Oliver.jpg\"></a>"];
	
	STAssertEquals([string length], (NSUInteger)1, @"Output length should be 1");
	
	// get the attachment
	DTTextAttachment *attachment = [string attribute:NSAttachmentAttributeName atIndex:0 effectiveRange:NULL];
	
	STAssertNotNil(attachment, @"Attachment is missing");
	
	// get the link
	NSURL *URL = [string attribute:DTLinkAttribute atIndex:0 effectiveRange:NULL];
	
	STAssertNotNil(URL, @"Element URL is nil");
	
	STAssertEqualObjects(URL, attachment.hyperLinkURL, @"Attachment URL and element URL should match!");
}


@end
