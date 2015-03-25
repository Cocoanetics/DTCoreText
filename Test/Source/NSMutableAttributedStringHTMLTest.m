//
//  NSMutableAttributedStringHTMLTest.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 6/25/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "NSMutableAttributedStringHTMLTest.h"
#import "NSMutableAttributedString+HTML.h"
#import "NSAttributedString+HTML.h"


@implementation NSMutableAttributedStringHTMLTest



- (void)testAddCustomHTMLAttribute
{
	NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@"1234567890"];
	
	NSRange entireString = NSMakeRange(0, [attributedString length]);
	
	// have a range with an attribute
	[attributedString addHTMLAttribute:@"class" value:@"oli" range:NSMakeRange(3, 2) replaceExisting:YES];
	
	NSRange effectiveRange;
	NSDictionary *dict = [attributedString attribute:DTCustomAttributesAttribute atIndex:3 effectiveRange:&effectiveRange];
	
	NSRange expectedRange=NSMakeRange(3, 2);
	XCTAssertTrue(NSEqualRanges(expectedRange, effectiveRange), @"Effective Range does not match");
	
	NSString *value = [dict objectForKey:@"class"];
	XCTAssertEqualObjects(value, @"oli", @"Attribute should be oli");
	
	// add the same name attribute without replacing for the entire string
	[attributedString addHTMLAttribute:@"class" value:@"drops" range:entireString replaceExisting:NO];
	
	// part in the middle should still be oli
	dict = [attributedString attribute:DTCustomAttributesAttribute atIndex:3 effectiveRange:&effectiveRange];
	
	expectedRange=NSMakeRange(3, 2);
	XCTAssertTrue(NSEqualRanges(expectedRange, effectiveRange), @"Effective Range does not match");
	
	value = [dict objectForKey:@"class"];
	XCTAssertEqualObjects(value, @"oli", @"Attribute should be oli");
	
	// part at the start should be drops
	dict = [attributedString attribute:DTCustomAttributesAttribute atIndex:0 effectiveRange:&effectiveRange];
	
	expectedRange=NSMakeRange(0, 3);
	XCTAssertTrue(NSEqualRanges(expectedRange, effectiveRange), @"Effective Range does not match");
	
	value = [dict objectForKey:@"class"];
	XCTAssertEqualObjects(value, @"drops", @"Attribute should be drops");
	
	// part at the end should be drops
	dict = [attributedString attribute:DTCustomAttributesAttribute atIndex:5 effectiveRange:&effectiveRange];
	
	expectedRange=NSMakeRange(5, 5);
	XCTAssertTrue(NSEqualRanges(expectedRange, effectiveRange), @"Effective Range does not match");
	
	value = [dict objectForKey:@"class"];
	XCTAssertEqualObjects(value, @"drops", @"Attribute should be drops");
	
	// replace everything
	[attributedString addHTMLAttribute:@"class" value:@"foo" range:entireString replaceExisting:YES];
	
	effectiveRange = [attributedString rangeOfHTMLAttribute:@"class" atIndex:0];
	
	expectedRange=NSMakeRange(0, 10);
	XCTAssertTrue(NSEqualRanges(expectedRange, effectiveRange), @"Effective Range does not match");
	
	dict = [attributedString HTMLAttributesAtIndex:4];
	
	value = [dict objectForKey:@"class"];
	XCTAssertEqualObjects(value, @"foo", @"Attribute should be foo");
}

- (void)testRemoveCustomHTMLAttribute
{
	NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@"1234567890"];
	
	NSRange entireString = NSMakeRange(0, [attributedString length]);
	
	// have a range with an attribute
	[attributedString addHTMLAttribute:@"class" value:@"oli" range:entireString replaceExisting:YES];
	
	// remove a part at the end
	[attributedString removeHTMLAttribute:@"class" range:NSMakeRange(5, 10)];
	
	// tail should now be nil
	NSRange effectiveRange;
	NSDictionary *dict = [attributedString attribute:DTCustomAttributesAttribute atIndex:5 effectiveRange:&effectiveRange];
	
	NSRange expectedRange=NSMakeRange(5, 5);
	XCTAssertTrue(NSEqualRanges(expectedRange, effectiveRange), @"Effective Range does not match");
	
	XCTAssertNil(dict, @"There should be no dictionary in this range");
	
	// head should still be oli
	dict = [attributedString attribute:DTCustomAttributesAttribute atIndex:0 effectiveRange:&effectiveRange];
	
	expectedRange=NSMakeRange(0, 5);
	XCTAssertTrue(NSEqualRanges(expectedRange, effectiveRange), @"Effective Range does not match");
	
	id value = [dict objectForKey:@"class"];
	XCTAssertEqualObjects(value, @"oli", @"Attribute should be oli");
}

- (void)testRemoveMultipleCustomHTMLAttribute
{
	NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@"1234567890"];
	
	NSRange entireString = NSMakeRange(0, [attributedString length]);
	
	// have a range with an attribute
	[attributedString addHTMLAttribute:@"class" value:@"oli" range:entireString replaceExisting:YES];
	[attributedString addHTMLAttribute:@"foo" value:@"bar" range:entireString replaceExisting:YES];
	
	// there should be two
	NSDictionary *attributes = [attributedString HTMLAttributesAtIndex:2];
	NSUInteger count = [attributes count];
	NSUInteger expectedCount = 2;
	
	XCTAssertEqual(count, expectedCount, @"There should be 2 custom attributes");

	// now remove one
	[attributedString removeHTMLAttribute:@"foo" range:entireString];
	
	// there should be one
	attributes = [attributedString HTMLAttributesAtIndex:2];
	count = [attributes count];
	expectedCount = 1;

	XCTAssertEqual(count, expectedCount, @"There should be only 1 custom attribute");
}

- (void)testRangeOfCustomHTMLAttribute
{
	NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@"1234567890"];
	
	NSRange entireString = NSMakeRange(0, [attributedString length]);
	
	// have a range with an attribute
	[attributedString addHTMLAttribute:@"class" value:@"oli" range:NSMakeRange(3, 2) replaceExisting:YES];
	
	// add longer range
	[attributedString addHTMLAttribute:@"class" value:@"bar" range:entireString replaceExisting:NO];
	
	// add a second one on top of it all
	[attributedString addHTMLAttribute:@"foo" value:@"bar" range:entireString replaceExisting:YES];
	
	// class element in middle is only valid for that range
	NSRange expectedRange = NSMakeRange(3, 2);
	NSRange queriedRange = [attributedString rangeOfHTMLAttribute:@"class" atIndex:3];
	
	XCTAssertTrue(NSEqualRanges(expectedRange, queriedRange), @"Range is incorrect");
	
	// global foo is entire range
	queriedRange = [attributedString rangeOfHTMLAttribute:@"foo" atIndex:3];
	
	XCTAssertTrue(NSEqualRanges(queriedRange, entireString), @"Range is incorrect");

	// global foo is entire range no matter where you query it
	queriedRange = [attributedString rangeOfHTMLAttribute:@"foo" atIndex:9];

	XCTAssertTrue(NSEqualRanges(queriedRange, entireString), @"Range is incorrect");

	// the right part of class (with 'bar')
	queriedRange = [attributedString rangeOfHTMLAttribute:@"class" atIndex:5];
	expectedRange = NSMakeRange(5, 5);

	XCTAssertTrue(NSEqualRanges(queriedRange, expectedRange), @"Range is incorrect");
	
	// the left part of class (with 'bar')
	queriedRange = [attributedString rangeOfHTMLAttribute:@"class" atIndex:1];
	expectedRange = NSMakeRange(0, 3);
	
	XCTAssertTrue(NSEqualRanges(queriedRange, expectedRange), @"Range is incorrect");
}

- (void)testForegroundColorAttributeNameAtEndOfParagraph
{
	NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@"1234567890"];
	NSMutableAttributedString *testingString = [[NSMutableAttributedString alloc] initWithAttributedString:attributedString];
	
	NSRange entireString = NSMakeRange(0, [attributedString length]);
	
	BOOL defaultValueForUseiOS6Attributes = ___useiOS6Attributes;
	___useiOS6Attributes = NO;
	
	// add a foreground color using the Core Text attribute name
	CGFloat components[4] = {1.0, 0.0, 0.0, 1.0};
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGColorRef redColorRef = CGColorCreate(colorSpace, components);
	[testingString addAttribute:(id)kCTForegroundColorAttributeName value:(id)CFBridgingRelease(redColorRef) range:entireString];
	
	// append the end of a paragraph tag
	[testingString appendEndOfParagraph];
	
	// check the foreground color
	id stringColorRef = [testingString attribute:(id)kCTForegroundColorAttributeName atIndex:([testingString length] - 1) effectiveRange:nil];
#if TARGET_OS_IPHONE
	if ([stringColorRef isKindOfClass:[UIColor class]]) {
		stringColorRef = (id)[(UIColor *)stringColorRef CGColor];
	}
#endif
	
	XCTAssertTrue(CGColorEqualToColor(redColorRef, (CGColorRef)stringColorRef), @"Foreground color should be red");
	
	CGColorSpaceRelease(colorSpace);
	
#if TARGET_OS_IPHONE && DTCORETEXT_SUPPORT_NS_ATTRIBUTES
	[testingString setAttributedString:attributedString];
	
	___useiOS6Attributes = YES;
	
	// add a foreground color using the NSAttributedString attribute name
	[testingString addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:entireString];
	
	// append the end of a paragraph tag
	[testingString appendEndOfParagraph];
	
	// check the foreground color
	id nsAttributesStringColor = [testingString attribute:NSForegroundColorAttributeName atIndex:([testingString length] - 1) effectiveRange:nil];

	if (![nsAttributesStringColor isKindOfClass:[UIColor class]]) {
		XCTFail(@"Color for NSForegroundColorAttributeName should be set as a valid UIColor"	);
	} else {
		XCTAssertTrue(CGColorEqualToColor([[UIColor redColor] CGColor], [nsAttributesStringColor CGColor]), @"Foreground color should be red");
	}
#endif
	
	___useiOS6Attributes = defaultValueForUseiOS6Attributes;
}

@end
