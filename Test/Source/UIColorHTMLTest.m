//
//  UIColorHTMLTest.m
//  DTCoreText
//
//  Created by Claus Broch on 11/01/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "UIColorHTMLTest.h"

@implementation UIColorHTMLTest

- (void)testValidColorWithHexString
{
	DTColor *htmlColor;
	DTColor *namedColor;
	
	namedColor = [DTColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
	htmlColor = DTColorCreateWithHexString(@"000000");
	XCTAssertNotNil(htmlColor, @"Failed to create black color");
	XCTAssertEqualObjects(namedColor, htmlColor, @"Hmmm... black is not black");
	
	namedColor = [DTColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
	htmlColor = DTColorCreateWithHexString(@"FFFFFF");
	XCTAssertNotNil(htmlColor, @"Failed to create white color");
	XCTAssertEqualObjects(namedColor, htmlColor, @"Hmmm... white is not white");
	
	namedColor = [DTColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
	htmlColor = DTColorCreateWithHexString(@"FF0000");
	XCTAssertNotNil(htmlColor, @"Failed to create red color");
	XCTAssertEqualObjects(namedColor, htmlColor, @"Hmmm... red is not red");
	
	namedColor = [DTColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
	htmlColor = DTColorCreateWithHexString(@"00FF00");
	XCTAssertNotNil(htmlColor, @"Failed to create green color");
	XCTAssertEqualObjects(namedColor, htmlColor, @"Hmmm... green is not green");
	
	namedColor = [DTColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1.0];
	htmlColor = DTColorCreateWithHexString(@"0000FF");
	XCTAssertNotNil(htmlColor, @"Failed to create blue color");
	XCTAssertEqualObjects(namedColor, htmlColor, @"Hmmm... blue is not blue");
	
	namedColor = [DTColor colorWithRed:1.0 green:0.0 blue:1.0 alpha:1.0];
	htmlColor = DTColorCreateWithHexString(@"F0F");
	XCTAssertNotNil(htmlColor, @"Failed to create purple color");
	XCTAssertEqualObjects(namedColor, htmlColor, @"Hmmm... purple is not purple");
}

- (void)testColorHTMLHexString
{
	DTColor *red = [DTColor redColor];
	XCTAssertEqualObjects(DTHexStringFromDTColor(red), @"ff0000");
	
	DTColor *green = [DTColor greenColor];
	XCTAssertEqualObjects(DTHexStringFromDTColor(green), @"00ff00");
	
	DTColor *blue = [DTColor blueColor];
	XCTAssertEqualObjects(DTHexStringFromDTColor(blue), @"0000ff");
	
	DTColor *white = [DTColor whiteColor];
	XCTAssertEqualObjects(DTHexStringFromDTColor(white), @"ffffff");
}

@end
