//
//  DTCoreTextFontDescriptorTest.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 15.11.13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import <DTCoreText/DTCoreText.h>
#import "DTCoreTextTestCase.h"

@interface DTCoreTextFontDescriptorTest : DTCoreTextTestCase
{
	NSString *_previousFallbackFontFamily;
}

@end

@implementation DTCoreTextFontDescriptorTest

- (void)setUp
{
	[super setUp];
	
	_previousFallbackFontFamily = [DTCoreTextFontDescriptor fallbackFontFamily];
}

- (void)tearDown
{
	[super tearDown];
	
	[DTCoreTextFontDescriptor setFallbackFontFamily:_previousFallbackFontFamily];
}

#pragma mark - Fallback Font Family

- (void)testFallbackFamily
{
	[DTCoreTextFontDescriptor setFallbackFontFamily:@"Arial"];
	
	NSAttributedString *attributedString = [super attributedStringFromHTMLString:@"<span style=\"font-family:FooBar\">text</span>" options:nil];
	XCTAssertNotNil(attributedString, @"There should be an attributed string");
	
	NSRange effectiveRange;
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:&effectiveRange];
	
	NSRange expectedRange = NSMakeRange(0, [attributedString length]);
	XCTAssertEqual(expectedRange.length, effectiveRange.length, @"Attributes should be entire range");
	XCTAssertEqual(expectedRange.location, effectiveRange.location, @"Attributes should be entire range");
	
	DTCoreTextFontDescriptor *fontDescriptor = [attributes fontDescriptor];
	XCTAssertEqualObjects(fontDescriptor.fontFamily, @"Arial", @"Font should have fallen back to Arial");
}

#if TARGET_OS_IPHONE && !TARGET_OS_WATCH
- (void)testFontDescriptor
{
	UIFontDescriptor *descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
	UIFont *font = [UIFont fontWithDescriptor:descriptor size:descriptor.pointSize];
	
	NSDictionary *options = @{DTDefaultFontDescriptor: descriptor};

	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<html><body><p>Regular<b>Bold</b><i>Italic</i><p></body></html>" options:options];

	NSDictionary *attributesPlain = [attributedString attributesAtIndex:0 effectiveRange:NULL];

	DTCoreTextFontDescriptor *fontDescriptorPlain = [attributesPlain fontDescriptor];
	XCTAssertEqualObjects(fontDescriptorPlain.fontFamily, font.familyName, @"Incorrect font family");
	XCTAssertFalse(fontDescriptorPlain.boldTrait, @"Should not be bold");
	XCTAssertFalse(fontDescriptorPlain.italicTrait, @"Should not be italic");
	
	NSDictionary *attributesBold = [attributedString attributesAtIndex:7 effectiveRange:NULL];

	DTCoreTextFontDescriptor *fontDescriptorBold = [attributesBold fontDescriptor];
	XCTAssertEqualObjects(fontDescriptorBold.fontFamily, font.familyName, @"Incorrect font family");
	XCTAssertTrue(fontDescriptorBold.boldTrait, @"Should be bold");
	XCTAssertFalse(fontDescriptorBold.italicTrait, @"Should not be italic");
	
	NSDictionary *attributesItalic = [attributedString attributesAtIndex:11 effectiveRange:NULL];

	DTCoreTextFontDescriptor *fontDescriptorItalic = [attributesItalic fontDescriptor];
	XCTAssertEqualObjects(fontDescriptorItalic.fontFamily, font.familyName, @"Incorrect font family");
	XCTAssertFalse(fontDescriptorItalic.boldTrait, @"Should not be bold");
	XCTAssertTrue(fontDescriptorItalic.italicTrait, @"Should be italic");
}

- (void)testFallbackFontFamilyWithoutFontTraits
{
    [DTCoreTextFontDescriptor setFallbackFontFamily:@"Arial"];

    NSAttributedString *attributedString = [super attributedStringFromHTMLString:@"<span style=\"font-family:FooBar\"><p>text</p></span>" options:nil];
    XCTAssertNotNil(attributedString, @"There should be an attributed string");

	UIFont *font = [attributedString attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL];

	UIFontDescriptor *descriptor = [font fontDescriptor];
	BOOL isBold = (descriptor.symbolicTraits & UIFontDescriptorTraitBold) != 0;
	XCTAssertFalse(isBold);

	BOOL isItalic = (descriptor.symbolicTraits & UIFontDescriptorTraitItalic) != 0;
	XCTAssertFalse(isItalic);

	XCTAssertTrue([font.familyName isEqualToString:@"Arial"]);
}


- (void)testFallbackFontFamilyWithBoldFontTrait
{
	[DTCoreTextFontDescriptor setFallbackFontFamily:@"Arial"];

	NSAttributedString *attributedString = [super attributedStringFromHTMLString:@"<span style=\"font-family:FooBar\"><b>text</b></span>" options:nil];
	XCTAssertNotNil(attributedString, @"There should be an attributed string");

	UIFont *font = [attributedString attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL];

	UIFontDescriptor *descriptor = [font fontDescriptor];
	BOOL isBold = (descriptor.symbolicTraits & UIFontDescriptorTraitBold) != 0;
	XCTAssertTrue(isBold);

	BOOL isItalic = (descriptor.symbolicTraits & UIFontDescriptorTraitItalic) != 0;
	XCTAssertFalse(isItalic);

	XCTAssertTrue([font.familyName isEqualToString:@"Arial"]);
}

- (void)testFallbackFontFamilyWithItalicFontTrait
{
	[DTCoreTextFontDescriptor setFallbackFontFamily:@"Arial"];

	NSAttributedString *attributedString = [super attributedStringFromHTMLString:@"<span style=\"font-family:FooBar\"><em>text</em></span>" options:nil];
	XCTAssertNotNil(attributedString, @"There should be an attributed string");

	UIFont *font = [attributedString attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL];

	UIFontDescriptor *descriptor = [font fontDescriptor];
	BOOL isBold = (descriptor.symbolicTraits & UIFontDescriptorTraitBold) != 0;
	XCTAssertFalse(isBold);

	BOOL isItalic = (descriptor.symbolicTraits & UIFontDescriptorTraitItalic) != 0;
	XCTAssertTrue(isItalic);

	XCTAssertTrue([font.familyName isEqualToString:@"Arial"]);
}
#endif

- (void)testNilFallbackFamily
{
	XCTAssertThrows([DTCoreTextFontDescriptor setFallbackFontFamily:nil], @"Should not accept invalid fallback font family");
}

- (void)testInvalidFallbackFamily
{
	XCTAssertThrows([DTCoreTextFontDescriptor setFallbackFontFamily:@"HelveticaNeue"], @"Should not accept invalid fallback font family");
}

@end
