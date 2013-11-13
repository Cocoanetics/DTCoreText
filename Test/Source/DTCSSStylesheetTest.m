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

@interface DTCSSStylesheet()
- (NSInteger)_weightForSelector:(NSString *)selector;
- (void)_uncompressShorthands:(NSMutableDictionary *)styles;
@end

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

// the !important CSS tag should be ignored
- (void)testImportant
{
	NSString *string = @"p {align: center !IMPORTANT;color:blue;}";
	
	DTCSSStylesheet *stylesheet = [[DTCSSStylesheet alloc] initWithStyleBlock:string];
	
	NSDictionary *styles = [stylesheet.styles objectForKey:@"p"];
	
	STAssertEquals([styles count], (NSUInteger)2, @"There should be 2 styles");
	
	NSString *alignStyle = [styles objectForKey:@"align"];
	
	STAssertEqualObjects(alignStyle, @"center", @"Align should be 'center', but is '%@'", alignStyle);
	
	NSString *colorStyle = [styles objectForKey:@"color"];
	
	STAssertEqualObjects(colorStyle, @"blue", @"Color should be 'blue', but is '%@'", colorStyle);
}

- (void)testMerging
{
	DTCSSStylesheet *stylesheet = [[DTCSSStylesheet defaultStyleSheet] copy];
	DTCSSStylesheet *otherStyleSheet = [[DTCSSStylesheet alloc] initWithStyleBlock:@"p {margin-bottom:30px;font-size:40px;}"];
	[stylesheet mergeStylesheet:otherStyleSheet];
	
	DTHTMLElement *element = [DTHTMLElement elementWithName:@"p" attributes:nil options:nil];
	element.fontDescriptor = [[DTCoreTextFontDescriptor alloc] init]; // need to have just any font descriptor
	element.textScale = 1.0;
	
	NSDictionary *styles = [stylesheet mergedStyleDictionaryForElement:element matchedSelectors:NULL];
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

// issue 535

- (void)testMultipleFontFamiliesCrash
{
	STAssertTrueNoThrow([[DTCSSStylesheet alloc] initWithStyleBlock:@"p {font-family:Helvetica,sans-serif;}"]!=nil, @"Should be able to parse without crash");
}

- (void)testMultipleFontFamilies
{
	DTCSSStylesheet *stylesheet = [[DTCSSStylesheet alloc] initWithStyleBlock:@"p {font-family:Helvetica,sans-serif !important;}"];
	NSDictionary *styles = [stylesheet.styles objectForKey:@"p"];
	NSArray *expected = @[@"Helvetica", @"sans-serif"];
	STAssertEqualObjects(styles[@"font-family"], expected, @"Font Family should be [Helvetica, sans-serif]");
}

- (void)testMergeByID
{
	DTCSSStylesheet *stylesheet = [[DTCSSStylesheet alloc] initWithStyleBlock:@"#foo {color:red;} #bar {color:blue;} .foo {color:yellow;}"];

	NSDictionary *attributes = [NSDictionary dictionaryWithObject:@"foo" forKey:@"id"];
	DTHTMLElement *element = [[DTHTMLElement alloc] initWithName:@"dummy" attributes:attributes];
	
	NSSet *matchedSelectors;
	NSDictionary *styles = [stylesheet mergedStyleDictionaryForElement:element matchedSelectors:&matchedSelectors];
	
	STAssertTrue([styles count]==1, @"There should be exactly one style");
	STAssertTrue([matchedSelectors count]==1, @"There should be exactly one matched selector");
	
	if ([matchedSelectors count]==1)
	{
		NSString *selector = [matchedSelectors anyObject];
		STAssertTrue([selector isEqualToString:@"#foo"], @"Matched Selector should be foo");
	}
	
	NSString *style = [styles objectForKey:@"color"];
	STAssertTrue([style isEqualToString:@"red"], @"Applied style should be color:red");
}

#pragma mark - CSS Cascading

- (void)testInvalidSelectorHasNoWeight
{
	DTCSSStylesheet *stylesheet = [[DTCSSStylesheet alloc] initWithStyleBlock:@""];
	
	NSInteger weight = [stylesheet _weightForSelector:@""];
	STAssertTrue((weight == 0), @"Weight should be 0");

	NSInteger weight2 = [stylesheet _weightForSelector:nil];
	STAssertTrue((weight2 == 0), @"Weight should be 0");
}

- (void)testClassesWeighTen
{
	DTCSSStylesheet *stylesheet = [[DTCSSStylesheet alloc] initWithStyleBlock:@""];
	
	NSInteger weight = [stylesheet _weightForSelector:@".foo"];
	STAssertTrue((weight == 10), @"Weight should be 10");

	NSInteger weight2 = [stylesheet _weightForSelector:@".foo .bar"];
	STAssertTrue((weight2 == 20), @"Weight should be 20");
}

- (void)testIdsWeightOneHundred
{
	DTCSSStylesheet *stylesheet = [[DTCSSStylesheet alloc] initWithStyleBlock:@""];
	
	NSInteger weight = [stylesheet _weightForSelector:@"#foo"];
	STAssertTrue((weight == 100), @"Weight should be 100");
	
	NSInteger weight2 = [stylesheet _weightForSelector:@"#foo #bar"];
	STAssertTrue((weight2 == 200), @"Weight should be 200");
}

- (void)testElementNamesWeightOne
{
	DTCSSStylesheet *stylesheet = [[DTCSSStylesheet alloc] initWithStyleBlock:@""];
	
	NSInteger weight = [stylesheet _weightForSelector:@"div"];
	STAssertTrue((weight == 1), @"Weight should be 1");
	
	NSInteger weight2 = [stylesheet _weightForSelector:@"span div"];
	STAssertTrue((weight2 == 2), @"Weight should be 2");
}

- (void)testWeightsAreSummed
{
	DTCSSStylesheet *stylesheet = [[DTCSSStylesheet alloc] initWithStyleBlock:@""];
	
	NSInteger weight = [stylesheet _weightForSelector:@".foo #div bar"];
	STAssertTrue((weight == 111), @"Weight should be 111");
}

- (void)testSpacesDoNotAffectWeight
{
	DTCSSStylesheet *stylesheet = [[DTCSSStylesheet alloc] initWithStyleBlock:@""];
	
	NSInteger weight = [stylesheet _weightForSelector:@" .foo  #div    bar  "];
	STAssertTrue((weight == 111), @"Weight should be 111");
}

#pragma mark - Shorthands

- (void)testUncompressFontShorthand
{
	DTCSSStylesheet *stylesheet = [DTCSSStylesheet defaultStyleSheet];
	
	NSMutableDictionary *styles = [NSMutableDictionary dictionary];
	
	[styles setObject:@"italic bold 12px/30px Georgia caption" forKey:@"font"];
	
	[stylesheet _uncompressShorthands:styles];
	
	STAssertTrue([styles count]==6, @"There should be 6 entries in style");
	
	NSString *fontFamily = [styles objectForKey:@"font-family"];
	STAssertTrue([fontFamily isEqualToString:@"Georgia"], @"font-family should be Georgia");
	
	NSString *fontStyle = [styles objectForKey:@"font-style"];
	STAssertTrue([fontStyle isEqualToString:@"italic"], @"font-style should be italic");

	NSString *fontVariant = [styles objectForKey:@"font-variant"];
	STAssertTrue([fontVariant isEqualToString:@"normal"], @"font-variant should be normal");

	NSString *fontWeight = [styles objectForKey:@"font-weight"];
	STAssertTrue([fontWeight isEqualToString:@"bold"], @"font-weight should be bold");

	NSString *fontSize = [styles objectForKey:@"font-size"];
	STAssertTrue([fontSize isEqualToString:@"12px"], @"font-size should be 12px");

	NSString *fontLineHeight = [styles objectForKey:@"line-height"];
	STAssertTrue([fontLineHeight isEqualToString:@"30px"], @"line-height should be 30px");
}

- (void)testUncompressFontShorthandWordSize
{
	DTCSSStylesheet *stylesheet = [DTCSSStylesheet defaultStyleSheet];
	
	NSMutableDictionary *styles = [NSMutableDictionary dictionary];
	
	[styles setObject:@"xx-small Georgia icon" forKey:@"font"];
	
	[stylesheet _uncompressShorthands:styles];
	
	STAssertTrue([styles count]==6, @"There should be 6 entries in style");
	
	NSString *fontFamily = [styles objectForKey:@"font-family"];
	STAssertTrue([fontFamily isEqualToString:@"Georgia"], @"font-family should be Georgia");
	
	NSString *fontVariant = [styles objectForKey:@"font-variant"];
	STAssertTrue([fontVariant isEqualToString:@"normal"], @"font-variant should be normal");
	
	NSString *fontWeight = [styles objectForKey:@"font-weight"];
	STAssertTrue([fontWeight isEqualToString:@"normal"], @"font-weight should be normal");
	
	NSString *fontSize = [styles objectForKey:@"font-size"];
	STAssertTrue([fontSize isEqualToString:@"xx-small"], @"font-size should be xx-small");
	
	NSString *fontLineHeight = [styles objectForKey:@"line-height"];
	STAssertTrue([fontLineHeight isEqualToString:@"normal"], @"line-height should be normal");
}

- (void)testUncompressFontShorthandLengthFirst
{
	DTCSSStylesheet *stylesheet = [DTCSSStylesheet defaultStyleSheet];
	
	NSMutableDictionary *styles = [NSMutableDictionary dictionary];
	
	[styles setObject:@"1.0em Georgia menu" forKey:@"font"];
	
	[stylesheet _uncompressShorthands:styles];
	
	STAssertTrue([styles count]==6, @"There should be 6 entries in style");
	
	NSString *fontFamily = [styles objectForKey:@"font-family"];
	STAssertTrue([fontFamily isEqualToString:@"Georgia"], @"font-family should be Georgia");
	
	NSString *fontVariant = [styles objectForKey:@"font-variant"];
	STAssertTrue([fontVariant isEqualToString:@"normal"], @"font-variant should be normal");
	
	NSString *fontWeight = [styles objectForKey:@"font-weight"];
	STAssertTrue([fontWeight isEqualToString:@"normal"], @"font-weight should be normal");
	
	NSString *fontSize = [styles objectForKey:@"font-size"];
	STAssertTrue([fontSize isEqualToString:@"1.0em"], @"font-size should be 1.0em");
	
	NSString *fontLineHeight = [styles objectForKey:@"line-height"];
	STAssertTrue([fontLineHeight isEqualToString:@"normal"], @"line-height should be normal");
}

- (void)testUncompressListShorthand
{
	DTCSSStylesheet *stylesheet = [DTCSSStylesheet defaultStyleSheet];
	
	NSMutableDictionary *styles = [NSMutableDictionary dictionary];
	
	[styles setObject:@"inherit" forKey:@"list-style"];
	[styles setObject:@"url('sqpurple.gif')" forKey:@"list-style-image"];
	
	[stylesheet _uncompressShorthands:styles];
	
	NSString *stylePosition = [styles objectForKey:@"list-style-position"];
	NSString *styleType = [styles objectForKey:@"list-style-type"];
	
	STAssertTrue([stylePosition isEqualToString:@"inherit"], @"list-style-position should be inherit");
	STAssertTrue([styleType isEqualToString:@"inherit"], @"list-style-type should be inherit");
}

- (void)testUncompressListImageShorthand
{
	DTCSSStylesheet *stylesheet = [DTCSSStylesheet defaultStyleSheet];
	
	NSMutableDictionary *styles = [NSMutableDictionary dictionary];
	
	[styles setObject:@"image" forKey:@"list-style"];
	[styles setObject:@"image url('sqpurple.gif')" forKey:@"list-style"];
	
	[stylesheet _uncompressShorthands:styles];
	
	NSString *styleImage = [styles objectForKey:@"list-style-image"];
	NSString *styleType = [styles objectForKey:@"list-style-type"];
	
	STAssertTrue([styleImage isEqualToString:@"url('sqpurple.gif')"], @"list-style-position should be inherit");
	STAssertTrue([styleType isEqualToString:@"image"], @"list-style-type should be inherit");
}

- (void)testUncompressMarginShorthandOne
{
	DTCSSStylesheet *stylesheet = [DTCSSStylesheet defaultStyleSheet];
	NSMutableDictionary *styles = [NSMutableDictionary dictionary];

	[styles setObject:@"10px" forKey:@"margin"];
	[stylesheet _uncompressShorthands:styles];
	
	NSString *marginTop = [styles objectForKey:@"margin-top"];
	STAssertTrue([marginTop isEqualToString:@"10px"], @"margin-top should be 10px");

	NSString *marginBottom = [styles objectForKey:@"margin-bottom"];
	STAssertTrue([marginBottom isEqualToString:@"10px"], @"margin-bottom should be 10px");

	NSString *marginLeft = [styles objectForKey:@"margin-left"];
	STAssertTrue([marginLeft isEqualToString:@"10px"], @"margin-left should be 10px");

	NSString *marginRight = [styles objectForKey:@"margin-right"];
	STAssertTrue([marginRight isEqualToString:@"10px"], @"margin-right should be 10px");
}

- (void)testUncompressMarginShorthandTwo
{
	DTCSSStylesheet *stylesheet = [DTCSSStylesheet defaultStyleSheet];
	NSMutableDictionary *styles = [NSMutableDictionary dictionary];
	
	[styles setObject:@"10px 20px" forKey:@"margin"];
	[stylesheet _uncompressShorthands:styles];
	
	NSString *marginTop = [styles objectForKey:@"margin-top"];
	STAssertTrue([marginTop isEqualToString:@"10px"], @"margin-top should be 10px");
	
	NSString *marginBottom = [styles objectForKey:@"margin-bottom"];
	STAssertTrue([marginBottom isEqualToString:@"10px"], @"margin-bottom should be 10px");
	
	NSString *marginLeft = [styles objectForKey:@"margin-left"];
	STAssertTrue([marginLeft isEqualToString:@"20px"], @"margin-left should be 20px");
	
	NSString *marginRight = [styles objectForKey:@"margin-right"];
	STAssertTrue([marginRight isEqualToString:@"20px"], @"margin-right should be 20px");
}

- (void)testUncompressMarginShorthandThree
{
	DTCSSStylesheet *stylesheet = [DTCSSStylesheet defaultStyleSheet];
	NSMutableDictionary *styles = [NSMutableDictionary dictionary];
	
	[styles setObject:@"10px 20px 30px" forKey:@"margin"];
	[stylesheet _uncompressShorthands:styles];
	
	NSString *marginTop = [styles objectForKey:@"margin-top"];
	STAssertTrue([marginTop isEqualToString:@"10px"], @"margin-top should be 10px");
	
	NSString *marginBottom = [styles objectForKey:@"margin-bottom"];
	STAssertTrue([marginBottom isEqualToString:@"30px"], @"margin-bottom should be 30px");
	
	NSString *marginLeft = [styles objectForKey:@"margin-left"];
	STAssertTrue([marginLeft isEqualToString:@"20px"], @"margin-left should be 20px");
	
	NSString *marginRight = [styles objectForKey:@"margin-right"];
	STAssertTrue([marginRight isEqualToString:@"20px"], @"margin-right should be 20px");
}

- (void)testUncompressMarginShorthandFour
{
	DTCSSStylesheet *stylesheet = [DTCSSStylesheet defaultStyleSheet];
	NSMutableDictionary *styles = [NSMutableDictionary dictionary];
	
	[styles setObject:@"10px 20px 30px 40px" forKey:@"margin"];
	[stylesheet _uncompressShorthands:styles];
	
	NSString *marginTop = [styles objectForKey:@"margin-top"];
	STAssertTrue([marginTop isEqualToString:@"10px"], @"margin-top should be 10px");
	
	NSString *marginBottom = [styles objectForKey:@"margin-bottom"];
	STAssertTrue([marginBottom isEqualToString:@"30px"], @"margin-bottom should be 30px");
	
	NSString *marginLeft = [styles objectForKey:@"margin-left"];
	STAssertTrue([marginLeft isEqualToString:@"40px"], @"margin-left should be 40px");
	
	NSString *marginRight = [styles objectForKey:@"margin-right"];
	STAssertTrue([marginRight isEqualToString:@"20px"], @"margin-right should be 20px");
}

- (void)testUncompressPaddingShorthandOne
{
	DTCSSStylesheet *stylesheet = [DTCSSStylesheet defaultStyleSheet];
	NSMutableDictionary *styles = [NSMutableDictionary dictionary];
	
	[styles setObject:@"10px" forKey:@"padding"];
	[stylesheet _uncompressShorthands:styles];
	
	NSString *paddingTop = [styles objectForKey:@"padding-top"];
	STAssertTrue([paddingTop isEqualToString:@"10px"], @"padding-top should be 10px");
	
	NSString *paddingBottom = [styles objectForKey:@"padding-bottom"];
	STAssertTrue([paddingBottom isEqualToString:@"10px"], @"padding-bottom should be 10px");
	
	NSString *paddingLeft = [styles objectForKey:@"padding-left"];
	STAssertTrue([paddingLeft isEqualToString:@"10px"], @"padding-left should be 10px");
	
	NSString *paddingRight = [styles objectForKey:@"padding-right"];
	STAssertTrue([paddingRight isEqualToString:@"10px"], @"padding-right should be 10px");
}

- (void)testUncompressPaddingShorthandTwo
{
	DTCSSStylesheet *stylesheet = [DTCSSStylesheet defaultStyleSheet];
	NSMutableDictionary *styles = [NSMutableDictionary dictionary];
	
	[styles setObject:@"10px 20px" forKey:@"padding"];
	[stylesheet _uncompressShorthands:styles];
	
	NSString *paddingTop = [styles objectForKey:@"padding-top"];
	STAssertTrue([paddingTop isEqualToString:@"10px"], @"padding-top should be 10px");
	
	NSString *paddingBottom = [styles objectForKey:@"padding-bottom"];
	STAssertTrue([paddingBottom isEqualToString:@"10px"], @"padding-bottom should be 10px");
	
	NSString *paddingLeft = [styles objectForKey:@"padding-left"];
	STAssertTrue([paddingLeft isEqualToString:@"20px"], @"padding-left should be 20px");
	
	NSString *paddingRight = [styles objectForKey:@"padding-right"];
	STAssertTrue([paddingRight isEqualToString:@"20px"], @"padding-right should be 20px");
}

- (void)testUncompressPaddingShorthandThree
{
	DTCSSStylesheet *stylesheet = [DTCSSStylesheet defaultStyleSheet];
	NSMutableDictionary *styles = [NSMutableDictionary dictionary];
	
	[styles setObject:@"10px 20px 30px" forKey:@"padding"];
	[stylesheet _uncompressShorthands:styles];
	
	NSString *paddingTop = [styles objectForKey:@"padding-top"];
	STAssertTrue([paddingTop isEqualToString:@"10px"], @"padding-top should be 10px");
	
	NSString *paddingBottom = [styles objectForKey:@"padding-bottom"];
	STAssertTrue([paddingBottom isEqualToString:@"30px"], @"padding-bottom should be 30px");
	
	NSString *paddingLeft = [styles objectForKey:@"padding-left"];
	STAssertTrue([paddingLeft isEqualToString:@"20px"], @"padding-left should be 20px");
	
	NSString *paddingRight = [styles objectForKey:@"padding-right"];
	STAssertTrue([paddingRight isEqualToString:@"20px"], @"padding-right should be 20px");
}

- (void)testUncompressPaddingShorthandFour
{
	DTCSSStylesheet *stylesheet = [DTCSSStylesheet defaultStyleSheet];
	NSMutableDictionary *styles = [NSMutableDictionary dictionary];
	
	[styles setObject:@"10px 20px 30px 40px" forKey:@"padding"];
	[stylesheet _uncompressShorthands:styles];
	
	NSString *paddingTop = [styles objectForKey:@"padding-top"];
	STAssertTrue([paddingTop isEqualToString:@"10px"], @"padding-top should be 10px");
	
	NSString *paddingBottom = [styles objectForKey:@"padding-bottom"];
	STAssertTrue([paddingBottom isEqualToString:@"30px"], @"padding-bottom should be 30px");
	
	NSString *paddingLeft = [styles objectForKey:@"padding-left"];
	STAssertTrue([paddingLeft isEqualToString:@"40px"], @"padding-left should be 40px");
	
	NSString *paddingRight = [styles objectForKey:@"padding-right"];
	STAssertTrue([paddingRight isEqualToString:@"20px"], @"margin-right should be 20px");
}

@end
