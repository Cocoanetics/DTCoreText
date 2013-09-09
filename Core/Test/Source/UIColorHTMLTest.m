//
//  UIColorHTMLTest.m
//  DTCoreText
//
//  Created by Claus Broch on 11/01/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCoreText.h"
#import "UIColorHTMLTest.h"
#import "DTCoreText.h"
#import "DTColorFunctions.h"

@implementation UIColorHTMLTest

- (void)testValidColorWithHexString
{
	DTColor *htmlColor;
	DTColor *namedColor;
	
	namedColor = [DTColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
	htmlColor = DTColorCreateWithHexString(@"000000");
	STAssertNotNil(htmlColor, @"Failed to create black color");
	STAssertEqualObjects(namedColor, htmlColor, @"Hmmm... black is not black");
	
	namedColor = [DTColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
	htmlColor = DTColorCreateWithHexString(@"FFFFFF");
	STAssertNotNil(htmlColor, @"Failed to create white color");
	STAssertEqualObjects(namedColor, htmlColor, @"Hmmm... white is not white");
	
	namedColor = [DTColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
	htmlColor = DTColorCreateWithHexString(@"FF0000");
	STAssertNotNil(htmlColor, @"Failed to create red color");
	STAssertEqualObjects(namedColor, htmlColor, @"Hmmm... red is not red");
	
	namedColor = [DTColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
	htmlColor = DTColorCreateWithHexString(@"00FF00");
	STAssertNotNil(htmlColor, @"Failed to create green color");
	STAssertEqualObjects(namedColor, htmlColor, @"Hmmm... green is not green");
	
	namedColor = [DTColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1.0];
	htmlColor = DTColorCreateWithHexString(@"0000FF");
	STAssertNotNil(htmlColor, @"Failed to create blue color");
	STAssertEqualObjects(namedColor, htmlColor, @"Hmmm... blue is not blue");
	
	namedColor = [DTColor colorWithRed:1.0 green:0.0 blue:1.0 alpha:1.0];
	htmlColor = DTColorCreateWithHexString(@"F0F");
	STAssertNotNil(htmlColor, @"Failed to create purple color");
	STAssertEqualObjects(namedColor, htmlColor, @"Hmmm... purple is not purple");
}

- (void)testColorHTMLHexString
{
	DTColor *red = [DTColor redColor];
	STAssertEqualObjects(DTHexStringFromDTColor(red), @"ff0000", nil);
	
	DTColor *green = [DTColor greenColor];
	STAssertEqualObjects(DTHexStringFromDTColor(green), @"00ff00", nil);
	
	DTColor *blue = [DTColor blueColor];
	STAssertEqualObjects(DTHexStringFromDTColor(blue), @"0000ff", nil);
	
	DTColor *white = [DTColor whiteColor];
	STAssertEqualObjects(DTHexStringFromDTColor(white), @"ffffff", nil);
}

@end
