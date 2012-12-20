//
//  DTCSSStyleSheetTest.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 20.12.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTCSSStyleSheetTest.h"

#import "DTCSSStylesheet.h"

@implementation DTCSSStyleSheetTest

- (void)testAttributeWithWhitespace
{
	NSString *string = @"span { font-family: 'Trebuchet MS'; font-size: 16px; font-style: italic }";
	
	DTCSSStylesheet *stylesheet = [[DTCSSStylesheet alloc] initWithStyleBlock:string];
	
	NSDictionary *styles = [stylesheet.styles objectForKey:@"span"];
	
	NSString *fontFamily = [styles objectForKey:@"font-family"];
	STAssertEqualObjects(fontFamily, @"Trebuchet MS", @"font-family should match");

	NSString *fontSize = [styles objectForKey:@"font-size"];
	STAssertEqualObjects(fontSize, @"16px", @"font-size should match");

	NSString *fontStyle = [styles objectForKey:@"font-style"];
	STAssertEqualObjects(fontStyle, @"italic", @"font-style should match");
}

@end
