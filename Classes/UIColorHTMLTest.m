//
//  UIColorHTMLTest.m
//  CoreTextExtensions
//
//  Created by Claus Broch on 11/01/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "UIColorHTMLTest.h"
#import "UIColor+HTML.h"

@implementation UIColorHTMLTest

- (void) testValidColorWithHexString
{
	UIColor *htmlColor;
	UIColor *namedColor;
	
	namedColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
	htmlColor = [UIColor colorWithHexString:@"000000"];
	STAssertNotNil(htmlColor, @"Failed to create black color");
	STAssertEqualObjects(namedColor, htmlColor, @"Hmmm... black is not black");
	
	namedColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
	htmlColor = [UIColor colorWithHexString:@"FFFFFF"];
	STAssertNotNil(htmlColor, @"Failed to create white color");
	STAssertEqualObjects(namedColor, htmlColor, @"Hmmm... white is not white");
	
	namedColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
	htmlColor = [UIColor colorWithHexString:@"FF0000"];
	STAssertNotNil(htmlColor, @"Failed to create red color");
	STAssertEqualObjects(namedColor, htmlColor, @"Hmmm... red is not red");
	
	namedColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
	htmlColor = [UIColor colorWithHexString:@"00FF00"];
	STAssertNotNil(htmlColor, @"Failed to create green color");
	STAssertEqualObjects(namedColor, htmlColor, @"Hmmm... green is not green");
	
	namedColor = [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1.0];
	htmlColor = [UIColor colorWithHexString:@"0000FF"];
	STAssertNotNil(htmlColor, @"Failed to create blue color");
	STAssertEqualObjects(namedColor, htmlColor, @"Hmmm... blue is not blue");
	
	namedColor = [UIColor colorWithRed:1.0 green:0.0 blue:1.0 alpha:1.0];
	htmlColor = [UIColor colorWithHexString:@"F0F"];
	STAssertNotNil(htmlColor, @"Failed to create purple color");
	STAssertEqualObjects(namedColor, htmlColor, @"Hmmm... purple is not purple");
}

@end
