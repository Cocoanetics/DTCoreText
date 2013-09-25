//
//  DTHTMLWriterTest.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 11.07.13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTHTMLWriterTest.h"
#import "DTCoreText.h"
#import "DTColorFunctions.h"

@implementation DTHTMLWriterTest

- (void)testBackgroundColor
{
	// create attributed string
	NSMutableAttributedString* attributedText = [[NSMutableAttributedString alloc] initWithString:@"Hello World"];
	NSRange range = [attributedText.string rangeOfString:@"World"];
	if (range.location != NSNotFound)
	{
		DTColor *color = DTColorCreateWithHexString(@"FFFF00");
		
		[attributedText addAttribute:DTBackgroundColorAttribute value:(id)color.CGColor range:range];
	}
	
	// generate html
	DTHTMLWriter *writer = [[DTHTMLWriter alloc] initWithAttributedString:attributedText];
	writer.useAppleConvertedSpace = NO;
	NSString *html = [writer HTMLFragment];
	
	NSRange colorRange = [html rangeOfString:@"background-color:#ffff00"];

	STAssertTrue(colorRange.location != NSNotFound,  @"html should contains background-color:#ffff00");
}

#pragma mark - List Output

- (void)testNestedListOutput
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<ol><li>1a<ul><li>2a</li></ul></li></ol>" options:NULL];
	
	// generate html
	DTHTMLWriter *writer = [[DTHTMLWriter alloc] initWithAttributedString:attributedString];
	NSString* html = [[writer HTMLFragment] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	
	NSRange rangeLILI = [html rangeOfString:@"</li></ul></li></ol>"];
	STAssertTrue(rangeLILI.location != NSNotFound, @"List Items should be closed next to each other");
	
	NSRange rangeLIUL = [html rangeOfString:@"</li><ul"];
	STAssertTrue(rangeLIUL.location == NSNotFound, @"List Items should not be closed before UL");
	
	NSRange rangeSpanUL = [html rangeOfString:@"</span></ul"];
	STAssertTrue(rangeSpanUL.location == NSNotFound, @"Missing LI between span and UL");
}

- (void)testNestedListOutputWithoutTextNode
{
	NSAttributedString *attributedString = [self attributedStringFromHTMLString:@"<ul><li><ol><li>2a</li><li>2b</li></ol></li><li>1a</li></ul>" options:NULL];
	
	// generate html
	DTHTMLWriter *writer = [[DTHTMLWriter alloc] initWithAttributedString:attributedString];
	NSString* html = [[writer HTMLFragment] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	
	NSRange twoAOutsideOL = [html rangeOfString:@"2a</span><ol"];
	STAssertTrue(twoAOutsideOL.location == NSNotFound, @"List item 2a should not be outside the ordered list");
}

@end
