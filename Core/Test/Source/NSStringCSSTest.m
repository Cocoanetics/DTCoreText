//
//  NSStringCSSTest.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/5/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTCompatibility.h"
#import "NSStringCSSTest.h"
#import "NSString+CSS.h"
#import "DTColor+HTML.h"

@implementation NSStringCSSTest

- (void)testShadowColorFirst
{
	NSString *string = @"red 1px 2px 3px;";
	
	DTColor *color = (DTColor *)[DTColor blackColor];
	NSArray *shadows = [string arrayOfCSSShadowsWithCurrentTextSize:10.0 currentColor:color];
	
	STAssertTrue([shadows count]==1, @"Could not find one shadow");
	
	NSDictionary *oneShadow = [shadows lastObject];
	
	STAssertTrue([oneShadow count]==3, @"Could not find 3 sub-values for shadow");
	
	CGFloat blur = [[oneShadow objectForKey:@"Blur"] floatValue];
	STAssertTrue(blur==3.0f, @"Blur should be 3");
	
	CGSize offset = [[oneShadow objectForKey:@"Offset"] CGSizeValue];
	CGSize expectedOffset = CGSizeMake(1, 2);
	STAssertTrue(CGSizeEqualToSize(offset, expectedOffset), @"Offset should be 1,2");
	
	DTColor *shadowColor = [oneShadow objectForKey:@"Color"];
	DTColor *redColor = [DTColor redColor];

#if TARGET_OS_IPHONE
	STAssertEqualObjects(shadowColor, redColor, @"Shadow color is not red");
#else
	STAssertEquals([shadowColor redComponent], [redColor redComponent], @"Red component differs");
	STAssertEquals([shadowColor greenComponent], [redColor greenComponent], @"Green component differs");
	STAssertEquals([shadowColor blueComponent], [redColor blueComponent], @"Blue component differs");
#endif
}


- (void)testShadowColorLast
{
	NSString *string = @"1px 2px 3px red;";
	
	DTColor *color = (DTColor *)[DTColor blackColor];
	NSArray *shadows = [string arrayOfCSSShadowsWithCurrentTextSize:10.0 currentColor:color];
	
	STAssertTrue([shadows count]==1, @"Could not find one shadow");
	
	NSDictionary *oneShadow = [shadows lastObject];
	
	STAssertTrue([oneShadow count]==3, @"Could not find 3 sub-values for shadow");
	
	CGFloat blur = [[oneShadow objectForKey:@"Blur"] floatValue];
	STAssertTrue(blur==3.0f, @"Blur should be 3");
	
	CGSize offset = [[oneShadow objectForKey:@"Offset"] CGSizeValue];
	CGSize expectedOffset = CGSizeMake(1, 2);
	STAssertTrue(CGSizeEqualToSize(offset, expectedOffset), @"Offset should be 1,2");
	
	DTColor *shadowColor = [oneShadow objectForKey:@"Color"];
	DTColor *redColor = [DTColor redColor];
	
#if TARGET_OS_IPHONE
	STAssertEqualObjects(shadowColor, redColor, @"Shadow color is not red");
#else
	STAssertEquals([shadowColor redComponent], [redColor redComponent], @"Red component differs");
	STAssertEquals([shadowColor greenComponent], [redColor greenComponent], @"Green component differs");
	STAssertEquals([shadowColor blueComponent], [redColor blueComponent], @"Blue component differs");
#endif
}

- (void)testShadowInvalid
{
	NSString *string = @"bla";
	
	DTColor *color = (DTColor *)[DTColor blackColor];
	NSArray *shadows = [string arrayOfCSSShadowsWithCurrentTextSize:10.0 currentColor:color];
	
	STAssertNil(shadows, @"Got back an array with %d entries instead of nil", [shadows count]);
}

- (void)testShadowNone
{
	NSString *string = @"none";
	
	DTColor *color = (DTColor *)[DTColor blackColor];
	NSArray *shadows = [string arrayOfCSSShadowsWithCurrentTextSize:10.0 currentColor:color];
	
	STAssertNil(shadows, @"Got back an array with %d entries instead of nil", [shadows count]);
}

- (void)testOneNoteStyle
{
	NSString *style = @"background-image:none;background-attachment:scroll;background-color:transparent;background-position-x:0%;background-position-y:0%;background-repeat:repeat;border-bottom-color:#000000;border-bottom-style:none;border-bottom-width:medium;border-left-color:#000000;border-left-style:none;border-left-width:medium;border-right-color:#000000;border-right-style:none;border-right-width:medium;border-top-color:#000000;border-top-style:none;border-top-width:medium;border-width:medium;clear:none;color:#000000;display:inline;font-family:Times New Roman;font-size:7pt;font-style:normal;font-variant:normal;letter-spacing:normal;line-height:normal;list-style-image:none;list-style-position:outside;list-style-type:disc;overflow:visible;padding:0px;padding-bottom:0px;padding-left:0px;padding-right:0px;padding-top:0px;position:static;float:none;text-align:left;text-decoration:none;text-indent:-0.25in;text-transform:none;visibility:inherit; FONT: 7pt &amp;quot;Times New Roman&amp;quot;";
	
	NSDictionary *styles = [style dictionaryOfCSSStyles];
	
	NSString *fontFamily = styles[@"font-family"];
	STAssertTrue([fontFamily isEqualToString:@"Times New Roman"], @"Font Family should be Times");
	
	NSString *fontAttribute = styles[@"font"];
	STAssertNil(fontAttribute, @"Uppercase FONT attribute shoudl be ignored");
}

- (void)testInvalidFontSize
{
	NSString *style = @"normal";
	
	BOOL isCSSLength = [style isCSSLengthValue];
	STAssertFalse(isCSSLength, @"Should not be a normal font value");
	
	style = @"10px";
	isCSSLength = [style isCSSLengthValue];
	STAssertTrue(isCSSLength, @"Should be a valid font size value");
}


@end
