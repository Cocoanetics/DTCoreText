//
//  DTHTMLWriterTest.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 11.07.13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTHTMLWriterTest.h"
#import "DTCoreText.h"

@implementation DTHTMLWriterTest

- (void)testBackgroundColor
{
	// create attributed string
	NSMutableAttributedString* attributedText = [[NSMutableAttributedString alloc] initWithString:@"Hello World"];
	NSRange range = [attributedText.string rangeOfString:@"World"];
	if (range.location != NSNotFound)
	{
		DTColor *color = [DTColor colorWithHexString:@"FFFF00"];
		[attributedText addAttribute:DTBackgroundColorAttribute
							   value:(id)color.CGColor
							   range:range];
	}
	
	// generate html
	DTHTMLWriter *writer = [[DTHTMLWriter alloc] initWithAttributedString:attributedText];
	writer.useAppleConvertedSpace = NO;
	NSString* html = [writer HTMLFragment];
	
	NSRange colorRange = [html rangeOfString:@"background-color:#ffff00"];

	STAssertTrue(colorRange.location != NSNotFound,  @"html should contains background-color:#ffff00");
}

@end
