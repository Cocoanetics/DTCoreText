//
//  NSDictionaryDTCoreText.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 02.10.13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "NSDictionary+DTCoreText.h"
#import "DTCoreTextTestCase.h"
#import "DTCompatibility.h"

@interface NSDictionaryDTCoreText : DTCoreTextTestCase
@end

@implementation NSDictionaryDTCoreText

- (void)testBold
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<b>bold</b>" options:NULL];
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:NULL];
	
	STAssertTrue([attributes isBold], @"Attributes should be bold");
}

- (void)testItalic
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<i>italic</i>" options:NULL];
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:NULL];
	
	STAssertTrue([attributes isItalic], @"Attributes should be italic");
}

- (void)testUnderline
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<u>underline</u>" options:NULL];
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:NULL];
	
	STAssertTrue([attributes isUnderline], @"Attributes should be underlined");
}

- (void)testStrikethrough
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<del>strikethrough</del>" options:NULL];
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:NULL];
	
	STAssertTrue([attributes isStrikethrough], @"Attributes should be strikethrough");
}

- (void)testHeaderLevel
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<h3>header</h3>" options:NULL];
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:NULL];
	
	STAssertTrue([attributes headerLevel]==3, @"Header level should be 3");
}

- (void)testHasAttachment
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<img src=\"Oliver.jpg\">" options:NULL];
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:NULL];
	
	STAssertTrue([attributes hasAttachment], @"There should be a text attachment");
}

- (void)testParagraphStyle
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<p>Paragraph</p>" options:NULL];
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:NULL];
	
	STAssertTrue([attributes paragraphStyle], @"There should be a paragraph style");
}

- (void)testParagraphStyleNil
{
	NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:@"string" attributes:NULL];
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:NULL];
	
	STAssertNil([attributes paragraphStyle], @"There should be no paragraph style");
}

- (void)testFontDescriptor
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<p>Paragraph</p>" options:NULL];
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:NULL];
	
	STAssertTrue([attributes fontDescriptor], @"There should be a font descriptor");
}

- (void)testFontDescriptorNil
{
	NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:@"string" attributes:NULL];
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:NULL];
	
	STAssertNil([attributes fontDescriptor], @"There should be no font descriptor");
}

- (void)testForegroundColorDefault
{
	NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:@"string" attributes:NULL];
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:NULL];
	
	DTColor *color = [attributes foregroundColor];
	NSString *hexColor = DTHexStringFromDTColor(color);
	
	STAssertTrue([hexColor isEqualToString:@"000000"], @"Default Color should be black");
}

@end
