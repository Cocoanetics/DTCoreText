//
//  DTCSSStyleSheetTest.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 20.12.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTCSSStyleSheetTest.h"

#import "DTCSSStylesheet.h"
#import "DTHTMLElement.h"
#import "DTCoreTextFontDescriptor.h"
#import "DTCoreTextParagraphStyle.h"

@implementation DTCSSStyleSheetTest

- (void)testAttributeWithWhitespace
{
	NSString *string = @"span { font-family: 'Trebuchet MS'; empty: ; empty2:; font-size: 16px; line-height: 20 px; font-style: italic }";
	
	DTCSSStylesheet *stylesheet = [[DTCSSStylesheet alloc] initWithStyleBlock:string];
	
	NSDictionary *styles = [stylesheet.styles objectForKey:@"span"];
	
	NSString *fontFamily = [styles objectForKey:@"font-family"];
	STAssertEqualObjects(fontFamily, @"Trebuchet MS", @"font-family should match");

	NSString *fontSize = [styles objectForKey:@"font-size"];
	STAssertEqualObjects(fontSize, @"16px", @"font-size should match");

	NSString *lineHeight = [styles objectForKey:@"line-height"];
	STAssertEqualObjects(lineHeight, @"20 px", @"line-height should match");

	NSString *fontStyle = [styles objectForKey:@"font-style"];
	STAssertEqualObjects(fontStyle, @"italic", @"font-style should match");
	
	NSString *empty = [styles objectForKey:@"empty"];
	STAssertEqualObjects(empty, @"", @"empty should match");

	NSString *empty2 = [styles objectForKey:@"empty2"];
	STAssertEqualObjects(empty2, @"", @"empty2 should match");
}

- (void)testMerging
{
	DTCSSStylesheet *stylesheet = [[DTCSSStylesheet defaultStyleSheet] copy];
	DTCSSStylesheet *otherStyleSheet = [[DTCSSStylesheet alloc] initWithStyleBlock:@"p {margin-bottom:30px;font-size:40px;}"];
	[stylesheet mergeStylesheet:otherStyleSheet];
	
	DTHTMLElement *element = [DTHTMLElement elementWithName:@"p" attributes:nil options:nil];
	element.fontDescriptor = [[DTCoreTextFontDescriptor alloc] init]; // need to have just any font descriptor
	element.textScale = 1.0;
	
	NSDictionary *styles = [stylesheet mergedStyleDictionaryForElement:element];
	[element applyStyleDictionary:styles];
	
	STAssertEquals(element.displayStyle, DTHTMLElementDisplayStyleBlock, @"Style merging lost block display style");

	STAssertEquals((float)element.fontDescriptor.pointSize, (float)40.0f, @"font size should be 40px");
}

// merge a stylesheet into one that has to decompress a font shorthand
- (void)testMergingWithDecompression
{
	DTCSSStylesheet *stylesheet = [[DTCSSStylesheet alloc] initWithStyleBlock:@"p {font: italic small-caps bold 14.0px/100px \"Times New Roman\", serif;}"];
	DTCSSStylesheet *otherStyleSheet = [[DTCSSStylesheet alloc] initWithStyleBlock:@"p {margin-bottom:30px;font-size:40px;}"];
	[stylesheet mergeStylesheet:otherStyleSheet];
	
	NSDictionary *styles = [stylesheet.styles objectForKey:@"p"];
	
	STAssertEqualObjects(styles[@"font-size"], @"40px", @"Font Size should be 40px");
	STAssertEqualObjects(styles[@"font-family"], @"\"Times New Roman\", serif", @"Font Family is wrong");
	STAssertEqualObjects(styles[@"font-style"], @"italic", @"Font Style should be italic");
	STAssertEqualObjects(styles[@"font-variant"], @"small-caps", @"Font Variant should be small-caps");
	STAssertEqualObjects(styles[@"line-height"], @"100px", @"Line Height should be 100px");
	STAssertEqualObjects(styles[@"margin-bottom"], @"30px", @"Margin Bottom should be 30px");
}

@end
