//
//  NSMutableAttributedStringHTMLTest.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 6/25/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "NSMutableAttributedStringHTMLTest.h"
#import "NSMutableAttributedString+HTML.h"


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
	STAssertEquals(expectedRange, effectiveRange, @"Effective Range does not match");
	
	NSString *value = [dict objectForKey:@"class"];
	STAssertEqualObjects(value, @"oli", @"Attribute should be oli");
	
	// add the same name attribute without replacing for the entire string
	[attributedString addHTMLAttribute:@"class" value:@"drops" range:entireString replaceExisting:NO];
	
	// part in the middle should still be oli
	dict = [attributedString attribute:DTCustomAttributesAttribute atIndex:3 effectiveRange:&effectiveRange];
	
	expectedRange=NSMakeRange(3, 2);
	STAssertEquals(expectedRange, effectiveRange, @"Effective Range does not match");
	
	value = [dict objectForKey:@"class"];
	STAssertEqualObjects(value, @"oli", @"Attribute should be oli");
	
	// part at the start should be drops
	dict = [attributedString attribute:DTCustomAttributesAttribute atIndex:0 effectiveRange:&effectiveRange];
	
	expectedRange=NSMakeRange(0, 3);
	STAssertEquals(expectedRange, effectiveRange, @"Effective Range does not match");
	
	value = [dict objectForKey:@"class"];
	STAssertEqualObjects(value, @"drops", @"Attribute should be drops");
	
	// part at the end should be drops
	dict = [attributedString attribute:DTCustomAttributesAttribute atIndex:5 effectiveRange:&effectiveRange];
	
	expectedRange=NSMakeRange(5, 5);
	STAssertEquals(expectedRange, effectiveRange, @"Effective Range does not match");
	
	value = [dict objectForKey:@"class"];
	STAssertEqualObjects(value, @"drops", @"Attribute should be drops");
	
	// replace everything
	[attributedString addHTMLAttribute:@"class" value:@"foo" range:entireString replaceExisting:YES];
	
	effectiveRange = [attributedString rangeOfHTMLAttribute:@"class" atIndex:0];
	
	expectedRange=NSMakeRange(0, 10);
	STAssertEquals(expectedRange, effectiveRange, @"Effective Range does not match");
	
	dict = [attributedString HTMLAttributesAtIndex:4];
	
	value = [dict objectForKey:@"class"];
	STAssertEqualObjects(value, @"foo", @"Attribute should be foo");
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
	STAssertEquals(expectedRange, effectiveRange, @"Effective Range does not match");
	
	STAssertNil(dict, @"There should be no dictionary in this range");
	
	// head should still be oli
	dict = [attributedString attribute:DTCustomAttributesAttribute atIndex:0 effectiveRange:&effectiveRange];
	
	expectedRange=NSMakeRange(0, 5);
	STAssertEquals(expectedRange, effectiveRange, @"Effective Range does not match");
	
	id value = [dict objectForKey:@"class"];
	STAssertEqualObjects(value, @"oli", @"Attribute should be oli");
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
	
	NSRange expectedRange = NSMakeRange(3, 2);
	NSRange queriedRange = [attributedString rangeOfHTMLAttribute:@"class" atIndex:3];
	
	STAssertEquals(expectedRange, queriedRange, @"Range should be entire string");
	
	queriedRange = [attributedString rangeOfHTMLAttribute:@"foo" atIndex:3];
	
	STAssertEquals(queriedRange, entireString, @"Range should be entire string");
}

@end
