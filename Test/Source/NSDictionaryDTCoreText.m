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

- (void)testNSUnderline
{
	if (!DTCoreTextModernAttributesPossible())
	{
		return;
	}

	
	NSDictionary *buildAttributes = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSUnderlineStyleAttributeName];
	NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:@"string" attributes:buildAttributes];
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:NULL];
	
	STAssertTrue([attributes isUnderline], @"Attributes should be underlined");
}

- (void)testStrikethrough
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<del>strikethrough</del>" options:NULL];
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:NULL];
	
	STAssertTrue([attributes isStrikethrough], @"Attributes should be strikethrough");
}

- (void)testNSStrikethrough
{
	if (!DTCoreTextModernAttributesPossible())
	{
		return;
	}

	NSDictionary *buildAttributes = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSStrikethroughStyleAttributeName];
	NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:@"string" attributes:buildAttributes];
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
	
	DTCoreTextParagraphStyle *paragraphStyle = [attributes paragraphStyle];
	
	STAssertNotNil(paragraphStyle, @"There should be a paragraph style");
	STAssertTrue([paragraphStyle isKindOfClass:[DTCoreTextParagraphStyle class]], @"Should be a DTCoreTextParagraphStyle");
}

- (void)testParagraphStyleNil
{
	NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:@"string" attributes:NULL];
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:NULL];
	
	STAssertNil([attributes paragraphStyle], @"There should be no paragraph style");
}

- (void)testNSParagraphStyle
{
	if (!DTCoreTextModernAttributesPossible())
	{
		return;
	}


	NSMutableParagraphStyle *nsParagraphStyle = [[NSMutableParagraphStyle alloc] init];
	NSDictionary *buildAttributes = [NSDictionary dictionaryWithObject:nsParagraphStyle forKey:NSParagraphStyleAttributeName];
	
	NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:@"string" attributes:buildAttributes];
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:NULL];
	
	DTCoreTextParagraphStyle *paragraphStyle = [attributes paragraphStyle];
	
	STAssertNotNil(paragraphStyle, @"There should be a paragraph style");
	STAssertTrue([paragraphStyle isKindOfClass:[DTCoreTextParagraphStyle class]], @"Should be a DTCoreTextParagraphStyle");
}


- (void)testFontDescriptor
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<p>Paragraph</p>" options:NULL];
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:NULL];
	
	STAssertNotNil([attributes fontDescriptor], @"There should be a font descriptor");
}

- (void)testFontDescriptorNil
{
	NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:@"string" attributes:NULL];
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:NULL];
	
	STAssertNil([attributes fontDescriptor], @"There should be no font descriptor");
}

- (void)testColorDefaults
{
	NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:@"string" attributes:NULL];
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:NULL];
	
	DTColor *color = [attributes foregroundColor];
	NSString *hexColor = DTHexStringFromDTColor(color);
	
	STAssertTrue([hexColor isEqualToString:@"000000"], @"Default Color should be black");
	
	color = [attributes backgroundColor];
	
	STAssertNil(color, @"Background Color should be nil");
}

- (void)testValidColors
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<span style=\"color:red;background-color:blue;\">Paragraph</span>" options:NULL];
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:NULL];
	
	DTColor *color = [attributes foregroundColor];
	NSString *hexColor = DTHexStringFromDTColor(color);
	
	STAssertTrue([hexColor isEqualToString:@"ff0000"], @"Default Color should be red");
	
	color = [attributes backgroundColor];
	hexColor = DTHexStringFromDTColor(color);
	
	STAssertTrue([hexColor isEqualToString:@"0000ff"], @"Default Color should be blue");
}

- (void)testNSValidColors
{
	if (!DTCoreTextModernAttributesPossible())
	{
		return;
	}
	
	NSDictionary *buildAttributes = [NSDictionary dictionaryWithObjectsAndKeys:DTColorCreateWithHTMLName(@"red"), NSForegroundColorAttributeName, DTColorCreateWithHTMLName(@"blue"), NSBackgroundColorAttributeName, nil];
	NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:@"string" attributes:buildAttributes];
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:NULL];
	
	DTColor *color = [attributes foregroundColor];
	NSString *hexColor = DTHexStringFromDTColor(color);
	
	STAssertTrue([hexColor isEqualToString:@"ff0000"], @"Default Color should be red");
	
	color = [attributes backgroundColor];
	hexColor = DTHexStringFromDTColor(color);
	
	STAssertTrue([hexColor isEqualToString:@"0000ff"], @"Default Color should be blue");
}
 
// this crashes or hangs issue #648
- (void)testNSValidColorsFromHTML
{
	if (!DTCoreTextModernAttributesPossible())
	{
		return;
	}
	
	NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:DTUseiOS6Attributes];
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<span style=\"color:red;background-color:blue;\">Paragraph</span>" options:options];
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:NULL];
	
	DTColor *color = [attributes foregroundColor];
	NSString *hexColor = DTHexStringFromDTColor(color);
	
	STAssertTrue([hexColor isEqualToString:@"ff0000"], @"Default Color should be red");
	
	color = [attributes backgroundColor];
	hexColor = DTHexStringFromDTColor(color);
	
	STAssertTrue([hexColor isEqualToString:@"0000ff"], @"Default Color should be blue");
}

- (void)testKerning
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<p style=\"letter-spacing:10px\">Paragraph</p>" options:NULL];
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:NULL];
	
	CGFloat kerning = [attributes kerning];
	
	STAssertEquals(kerning, (CGFloat)10.0, @"Kerning incorrect");
}

@end
