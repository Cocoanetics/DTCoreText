//
//  NSStringHTMLTest.m
//  DTCoreText
//
//  Created by Claus Broch on 11/01/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCoreTextConstants.h"
#import "NSStringHTMLTest.h"
#import "NSString+HTML.h"

@implementation NSStringHTMLTest

- (void)testEmojiEncodingAndDecoding
{
	NSString *string = @"😄";

	// check encoding
	NSString *encoded = [string stringByAddingHTMLEntities];
	XCTAssertTrue([encoded isEqualToString:@"&#128516;"], @"Smiley is not properly encoded");

	// check reverse
	NSString *decoded = [string stringByReplacingHTMLEntities];
	XCTAssertTrue([decoded isEqualToString:string], @"Smiley is not properly round trip decoded");
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
