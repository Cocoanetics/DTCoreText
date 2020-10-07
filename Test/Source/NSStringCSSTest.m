//
//  NSStringCSSTest.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/5/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "NSStringCSSTest.h"

@implementation NSStringCSSTest

- (void)testShadowColorFirst
{
	NSString *string = @"red 1px 2px 3px;";
	
	DTColor *color = (DTColor *)[DTColor blackColor];
	NSArray *shadows = [string arrayOfCSSShadowsWithCurrentTextSize:10.0 currentColor:color];
	
	XCTAssertTrue([shadows count]==1, @"Could not find one shadow");
	
	NSDictionary *oneShadow = [shadows lastObject];
	
	XCTAssertTrue([oneShadow count]==3, @"Could not find 3 sub-values for shadow");
	
	CGFloat blur = [[oneShadow objectForKey:@"Blur"] floatValue];
	XCTAssertTrue(blur==3.0f, @"Blur should be 3");
	
	CGSize offset = [[oneShadow objectForKey:@"Offset"] CGSizeValue];
	CGSize expectedOffset = CGSizeMake(1, 2);
	XCTAssertTrue(CGSizeEqualToSize(offset, expectedOffset), @"Offset should be 1,2");
	
	DTColor *shadowColor = [oneShadow objectForKey:@"Color"];
	DTColor *redColor = [DTColor redColor];

#if TARGET_OS_IPHONE
	XCTAssertEqualObjects(shadowColor, redColor, @"Shadow color is not red");
#else
	XCTAssertEqual([shadowColor redComponent], [redColor redComponent], @"Red component differs");
	XCTAssertEqual([shadowColor greenComponent], [redColor greenComponent], @"Green component differs");
	XCTAssertEqual([shadowColor blueComponent], [redColor blueComponent], @"Blue component differs");
#endif
}


- (void)testShadowColorLast
{
	NSString *string = @"1px 2px 3px red;";
	
	DTColor *color = (DTColor *)[DTColor blackColor];
	NSArray *shadows = [string arrayOfCSSShadowsWithCurrentTextSize:10.0 currentColor:color];
	
	XCTAssertTrue([shadows count]==1, @"Could not find one shadow");
	
	NSDictionary *oneShadow = [shadows lastObject];
	
	XCTAssertTrue([oneShadow count]==3, @"Could not find 3 sub-values for shadow");
	
	CGFloat blur = [[oneShadow objectForKey:@"Blur"] floatValue];
	XCTAssertTrue(blur==3.0f, @"Blur should be 3");
	
	CGSize offset = [[oneShadow objectForKey:@"Offset"] CGSizeValue];
	CGSize expectedOffset = CGSizeMake(1, 2);
	XCTAssertTrue(CGSizeEqualToSize(offset, expectedOffset), @"Offset should be 1,2");
	
	DTColor *shadowColor = [oneShadow objectForKey:@"Color"];
	DTColor *redColor = [DTColor redColor];
	
#if TARGET_OS_IPHONE
	XCTAssertEqualObjects(shadowColor, redColor, @"Shadow color is not red");
#else
	XCTAssertEqual([shadowColor redComponent], [redColor redComponent], @"Red component differs");
	XCTAssertEqual([shadowColor greenComponent], [redColor greenComponent], @"Green component differs");
	XCTAssertEqual([shadowColor blueComponent], [redColor blueComponent], @"Blue component differs");
#endif
}

- (void)testShadowInvalid
{
	NSString *string = @"bla";
	
	DTColor *color = (DTColor *)[DTColor blackColor];
	NSArray *shadows = [string arrayOfCSSShadowsWithCurrentTextSize:10.0 currentColor:color];
	
	XCTAssertNil(shadows, @"Got back an array with %ld entries instead of nil", (long)[shadows count]);
}

- (void)testShadowNone
{
	NSString *string = @"none";
	
	DTColor *color = (DTColor *)[DTColor blackColor];
	NSArray *shadows = [string arrayOfCSSShadowsWithCurrentTextSize:10.0 currentColor:color];
	
	XCTAssertNil(shadows, @"Got back an array with %ld entries instead of nil", (long)[shadows count]);
}

- (void)testOneNoteStyle
{
	NSString *style = @"background-image:none;background-attachment:scroll;background-color:transparent;background-position-x:0%;background-position-y:0%;background-repeat:repeat;border-bottom-color:#000000;border-bottom-style:none;border-bottom-width:medium;border-left-color:#000000;border-left-style:none;border-left-width:medium;border-right-color:#000000;border-right-style:none;border-right-width:medium;border-top-color:#000000;border-top-style:none;border-top-width:medium;border-width:medium;clear:none;color:#000000;display:inline;font-family:Times New Roman;font-size:7pt;font-style:normal;font-variant:normal;letter-spacing:normal;line-height:normal;list-style-image:none;list-style-position:outside;list-style-type:disc;overflow:visible;padding:0px;padding-bottom:0px;padding-left:0px;padding-right:0px;padding-top:0px;position:static;float:none;text-align:left;text-decoration:none;text-indent:-0.25in;text-transform:none;visibility:inherit; FONT: 7pt &amp;quot;Times New Roman&amp;quot;";
	
	NSDictionary *styles = [style dictionaryOfCSSStyles];
	
	NSString *fontFamily = styles[@"font-family"];
	XCTAssertTrue([fontFamily isEqualToString:@"Times New Roman"], @"Font Family should be Times");
	
	NSString *fontAttribute = styles[@"font"];
	XCTAssertNil(fontAttribute, @"Uppercase FONT attribute shoudl be ignored");
}

- (void)testInvalidFontSize
{
	NSString *style = @"normal";
	
	BOOL isCSSLength = [style isCSSLengthValue];
	XCTAssertFalse(isCSSLength, @"Should not be a normal font value");
	
	style = @"10px";
	isCSSLength = [style isCSSLengthValue];
	XCTAssertTrue(isCSSLength, @"Should be a valid font size value");
}

- (void)testMultiFontFamily
{
	NSString *style = @"font-family: 'Courier New', Courier, 'Lucida Sans Typewriter', 'Lucida Typewriter', Times New Roman, monospace";
	NSDictionary *dictionary = [style dictionaryOfCSSStyles];
	
	id font =  dictionary[@"font-family"];
	
	XCTAssertTrue([font isKindOfClass:[NSArray class]], @"Font count should be an array");
	XCTAssertTrue([font count] == 6, @"6 fonts should be returned");
}

- (void)testSimpleQuotedFontFamily
{
	NSString *style = @"font-family: 'Courier New'";
	NSDictionary *dictionary = [style dictionaryOfCSSStyles];
	
	id font =  dictionary[@"font-family"];
	
	XCTAssertEqualObjects(@"Courier New", font, @"Font count should be \"Courier New\"");
}

- (void)testSimpleUnquotedFontFamily
{
	NSString *style = @"font-family: Courier New";
	NSDictionary *dictionary = [style dictionaryOfCSSStyles];
	
	id font =  dictionary[@"font-family"];
	
	XCTAssertEqualObjects(@"Courier New", font, @"Font count should be \"Courier New\"");
}

- (void)testMultiFontFamilyWithSize
{
	NSString *style = @"font-family: 'Courier New', Courier, 'Lucida Sans Typewriter', 'Lucida Typewriter', Times New Roman, monospace; font-size: 60px;";
	NSDictionary *dictionary = [style dictionaryOfCSSStyles];
	
	id font =  dictionary[@"font-family"];
	NSString *size = dictionary[@"font-size"];
	
	XCTAssertTrue([font isKindOfClass:[NSArray class]], @"Font count should be an array");
	XCTAssertTrue([font count] == 6, @"6 fonts should be returned");
	XCTAssertTrue([size isEqualToString:@"60px"], @"Font size should be 60px");
}

- (void)testTextShadow
{
	NSString *style = @"font-family:Helvetica;font-weight:bold;font-size:30px; color:#FFF; text-shadow: -1px -1px #555, 1px 1px #EEE";
	NSDictionary *dictionary = [style dictionaryOfCSSStyles];
	id shadow = dictionary[@"text-shadow"];
	
	XCTAssertEqualObjects(@"-1px -1px #555, 1px 1px #EEE", shadow, @"Shadow should be \"-1px -1px #555, 1px 1px #EEE\"");
	XCTAssertTrue([shadow isKindOfClass:[NSString class]], @"shadow count should be a string");
}

- (void)testColor
{
	NSString *style = @"font-family:Helvetica;font-weight:bold;color:rgb(255, 0, 0);font-size:30px;";
	NSDictionary *dictionary = [style dictionaryOfCSSStyles];
	id color = dictionary[@"color"];
	
	XCTAssertEqualObjects(@"rgb(255, 0, 0)", color, @"Color should be \"rgb(255, 0, 0)\"");
	XCTAssertTrue([color isKindOfClass:[NSString class]], @"shadow count should be a string");	
}

- (void)testBackgroundColor
{
	NSString *style = @"font-family:Helvetica;font-weight:bold;background-color:rgb(255, 88, 44);font-size:30px;";
	NSDictionary *dictionary = [style dictionaryOfCSSStyles];
	id color = dictionary[@"background-color"];
	
	XCTAssertEqualObjects(@"rgb(255, 88, 44)", color, @"Background color should be \"rgb(255, 88, 44)\"");
	XCTAssertTrue([color isKindOfClass:[NSString class]], @"background-color should be a string");
}

- (void)testBackgroundRGB
{
	NSString *style = @"font-family:Helvetica;font-weight:bold;background:rgb(255, 88, 44);font-size:30px;";
	NSDictionary *dictionary = [style dictionaryOfCSSStyles];
	id color = dictionary[@"background"];

	XCTAssertEqualObjects(@"rgb(255, 88, 44)", color, @"Background color should be \"rgb(255, 88, 44)\"");
	XCTAssertTrue([color isKindOfClass:[NSString class]], @"background rgb should be a string");
}

- (void)testEdgeInsets
{
	// 4 values
	NSString *style = @"10px 20px 30px 40px";
	DTEdgeInsets insets = [style DTEdgeInsetsRelativeToCurrentTextSize:12.0 textScale:1.0];
	
	XCTAssertEqual(insets.top, (CGFloat)10, @"top should be 10");
	XCTAssertEqual(insets.left, (CGFloat)40, @"top should be 40");
	XCTAssertEqual(insets.bottom, (CGFloat)30, @"top should be 30");
	XCTAssertEqual(insets.right, (CGFloat)20, @"top should be 20");

	// 3 values
	style = @"10px 20px 30px";
	insets = [style DTEdgeInsetsRelativeToCurrentTextSize:12.0 textScale:1.0];
	
	XCTAssertEqual(insets.top, (CGFloat)10, @"top should be 10");
	XCTAssertEqual(insets.left, (CGFloat)20, @"top should be 20");
	XCTAssertEqual(insets.bottom, (CGFloat)30, @"top should be 30");
	XCTAssertEqual(insets.right, (CGFloat)20, @"top should be 20");
	
	// 2 values
	style = @"10px 20px";
	insets = [style DTEdgeInsetsRelativeToCurrentTextSize:12.0 textScale:1.0];
	
	XCTAssertEqual(insets.top, (CGFloat)10, @"top should be 10");
	XCTAssertEqual(insets.left, (CGFloat)20, @"top should be 20");
	XCTAssertEqual(insets.bottom, (CGFloat)10, @"top should be 10");
	XCTAssertEqual(insets.right, (CGFloat)20, @"top should be 20");

	// 1 value
	style = @"10px";
	insets = [style DTEdgeInsetsRelativeToCurrentTextSize:12.0 textScale:1.0];
	
	XCTAssertEqual(insets.top, (CGFloat)10, @"top should be 10");
	XCTAssertEqual(insets.left, (CGFloat)10, @"top should be 10");
	XCTAssertEqual(insets.bottom, (CGFloat)10, @"top should be 10");
	XCTAssertEqual(insets.right, (CGFloat)10, @"top should be 10");
}

// issue #774: rgb( should not cause function to return an array
- (void)testStyleWithRGB
{
	NSString *style = @"background:foo bar rgb(255, 255, 255)";
	
	NSDictionary *dictionary = [style dictionaryOfCSSStyles];
	
	id result = dictionary[@"background"];
	XCTAssertTrue([result isKindOfClass:[NSString class]], @"Result should be single string");
}

@end
