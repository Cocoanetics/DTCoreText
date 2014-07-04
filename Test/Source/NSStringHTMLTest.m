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
	XCTAssertTrue([encoded isEqualToString:@"&#128516;"], @"Smiley is not properly encoded");

	// check reverse
	NSString *decoded = [string stringByReplacingHTMLEntities];
	XCTAssertTrue([decoded isEqualToString:string], @"Smiley is not properly round trip decoded");
}

@end
