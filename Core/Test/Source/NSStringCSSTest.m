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

@end
