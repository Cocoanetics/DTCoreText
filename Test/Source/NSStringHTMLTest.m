//
//  NSStringHTMLTest.m
//  DTCoreText
//
//  Created by Claus Broch on 11/01/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "NSStringHTMLTest.h"

@implementation NSStringHTMLTest

- (void)testEmojiEncodingAndDecoding
{
	NSString *string = @"😄";

	// check encoding
	NSString *encoded = [string stringByAddingHTMLEntities];
	XCTAssertEqualObjects(encoded, @"&#128516;", @"Smiley is not properly encoded");

	// check reverse
	NSString *decoded = [encoded stringByReplacingHTMLEntities];
	XCTAssertEqualObjects(decoded, string, @"Smiley is not properly round trip decoded");
}

- (void)testHexDecoding
{
	NSString *encoded = @"&#x1F604;";
	NSString *expected = @"😄";
	
	NSString *decoded = [encoded stringByReplacingHTMLEntities];
	XCTAssertEqualObjects(decoded, expected, @"String is not properly decoded");
}

- (void)testKnownEntityDecoding
{
	NSString *encoded = @"&lt;&gt;";
	NSString *expected = @"<>";
	
	NSString *decoded = [encoded stringByReplacingHTMLEntities];
	XCTAssertEqualObjects(decoded, expected, @"String is not properly decoded");
}

- (void)testUnclosedDecoding
{
	NSString *encoded = @"&#128516test";
	NSString *expected = encoded;
	
	NSString *decoded = [encoded stringByReplacingHTMLEntities];
	XCTAssertEqualObjects(decoded, expected, @"String is not properly decoded");
}

- (void)testUnclosedHexDecoding
{
	NSString *encoded = @"&#x1F604test";
	NSString *expected = encoded;
	
	NSString *decoded = [encoded stringByReplacingHTMLEntities];
	XCTAssertEqualObjects(decoded, expected, @"String is not properly decoded");
}

- (void)testUnclosedKnownEntityDecoding
{
	NSString *encoded = @"&lttest";
	NSString *expected = encoded;
	
	NSString *decoded = [encoded stringByReplacingHTMLEntities];
	XCTAssertEqualObjects(decoded, expected, @"String is not properly decoded");
}

- (void)testInvalidDecoding
{
	NSString *encoded = @"&#hello;";
	NSString *expected = encoded;
	
	NSString *decoded = [encoded stringByReplacingHTMLEntities];
	XCTAssertEqualObjects(decoded, expected, @"String is not properly decoded");
}

- (void)testInvalidHexDecoding
{
	NSString *encoded = @"&#xsup;";
	NSString *expected = encoded;
	
	NSString *decoded = [encoded stringByReplacingHTMLEntities];
	XCTAssertEqualObjects(decoded, expected, @"String is not properly decoded");
}

- (void)testUnknownEntityDecoding
{
	NSString *encoded = @"&unknowncode;";
	NSString *expected = encoded;
	
	NSString *decoded = [encoded stringByReplacingHTMLEntities];
	XCTAssertEqualObjects(decoded, expected, @"String is not properly decoded");
}

- (void)testStringByAddingAppleConvertedSpace
{
	NSMutableString *convertedStringExpected = [NSMutableString string];
	
	// One space
	NSString *string = @"1 1";
	[convertedStringExpected setString:@"1 1"];
	NSString *convertedString = [string stringByAddingAppleConvertedSpace];
	XCTAssertTrue([convertedString isEqualToString:convertedStringExpected], @"Spaces do not get converted properly");
	
	// Two spaces
	string = @"2  2";
	[convertedStringExpected setString:@"2 <span class=\"Apple-converted-space\">"];
	[convertedStringExpected appendString:UNICODE_NON_BREAKING_SPACE];
	[convertedStringExpected appendString:@"</span>2"];
	convertedString = [string stringByAddingAppleConvertedSpace];
	XCTAssertTrue([convertedString isEqualToString:convertedStringExpected], @"Spaces do not get converted properly");

	// Three spaces
	string = @"3   3";
	[convertedStringExpected setString:@"3 <span class=\"Apple-converted-space\">"];
	[convertedStringExpected appendString:UNICODE_NON_BREAKING_SPACE];
	[convertedStringExpected appendString:@" </span>3"];
	convertedString = [string stringByAddingAppleConvertedSpace];
	XCTAssertTrue([convertedString isEqualToString:convertedStringExpected], @"Spaces do not get converted properly");

	// Four spaces
	string = @"4    4";
	[convertedStringExpected setString:@"4 <span class=\"Apple-converted-space\">"];
	[convertedStringExpected appendString:UNICODE_NON_BREAKING_SPACE];
	[convertedStringExpected appendString:@" "];
	[convertedStringExpected appendString:UNICODE_NON_BREAKING_SPACE];
	[convertedStringExpected appendString:@"</span>4"];
	convertedString = [string stringByAddingAppleConvertedSpace];
	XCTAssertTrue([convertedString isEqualToString:convertedStringExpected], @"Spaces do not get converted properly");
}

@end
