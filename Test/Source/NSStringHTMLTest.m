//
//  NSStringHTMLTest.m
//  DTCoreText
//
//  Created by Claus Broch on 11/01/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "NSStringHTMLTest.h"
#import "NSString+HTML.h"

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
	NSString *expected = @"😄test";
	
	NSString *decoded = [encoded stringByReplacingHTMLEntities];
	XCTAssertEqualObjects(decoded, expected, @"String is not properly decoded");
}

- (void)testUnclosedHexDecoding
{
	NSString *encoded = @"&#x1F604test";
	NSString *expected = @"😄test";
	
	NSString *decoded = [encoded stringByReplacingHTMLEntities];
	XCTAssertEqualObjects(decoded, expected, @"String is not properly decoded");
}

/* Not implemented.

- (void)testUnclosedKnownEntityDecoding
{
	NSString *encoded = @"&lttest";
	NSString *expected = @"<test";
	
	NSString *decoded = [encoded stringByReplacingHTMLEntities];
	XCTAssertEqualObjects(decoded, expected, @"String is not properly decoded");
}
*/

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

@end
