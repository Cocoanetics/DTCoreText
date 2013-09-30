//
//  NSAttributedStringDTCoreTextTest.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 30.09.13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "NSAttributedStringDTCoreTextTest.h"
#import "NSAttributedString+DTCoreText.h"

@implementation NSAttributedStringDTCoreTextTest

- (void)testRangeOfAnchor
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<p>some text</p><a name=\"anchor\">anchor</a><p>more text</p>" options:NULL];
	
	NSRange range = [attributedString rangeOfAnchorNamed:@"anchor"];
	NSRange expectedRange = NSMakeRange(10, 7);
	STAssertEquals(range, expectedRange, @"Incorrect Result for findable anchor");
	
	range = [attributedString rangeOfAnchorNamed:@"something"];
	expectedRange = NSMakeRange(NSNotFound, 0);
	STAssertEquals(range, expectedRange, @"Incorrect Result for non-findable anchor");
}

@end
