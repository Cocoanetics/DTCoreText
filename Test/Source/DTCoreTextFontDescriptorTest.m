//
//  DTCoreTextFontDescriptorTest.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 15.11.13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTCoreTextTestCase.h"
#import "DTCoreTextFontDescriptor.h"

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
	[DTCoreTextFontDescriptor setFallbackFontFamily:@"Helvetica"];
	
	NSAttributedString *attributedString = [super attributedStringFromHTMLString:@"<span style=\"font-family:FooBar\">text</span>" options:nil];
	STAssertNotNil(attributedString, @"There should be an attributed string");
	
	NSRange effectiveRange;
	NSDictionary *attributes = [attributedString attributesAtIndex:0 effectiveRange:&effectiveRange];
	
	NSRange expectedRange = NSMakeRange(0, [attributedString length]);
	STAssertEquals(expectedRange, effectiveRange, @"Attributes should be entire range");
	
	DTCoreTextFontDescriptor *fontDescriptor = [attributes fontDescriptor];
	STAssertEqualObjects(fontDescriptor.fontFamily, @"Helvetica", @"Font should have fallen back to Helvetica");
}

- (void)testNilFallbackFamily
{
	STAssertThrows([DTCoreTextFontDescriptor setFallbackFontFamily:nil], @"Should not accept invalid fallback font family");
}

- (void)testInvalidFallbackFamily
{
	STAssertThrows([DTCoreTextFontDescriptor setFallbackFontFamily:@"HelveticaNeue"], @"Should not accept invalid fallback font family");
}

@end
