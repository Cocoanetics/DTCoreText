//
//  NSStringCSSTest.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/5/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "NSStringCSSTest.h"
#import "NSString+CSS.h"
#import "DTColor+HTML.h"

@implementation NSStringCSSTest

- (void)testShadowColorFirst
{
	NSString *string = @"red 1px 2px 3px;";
	
	DTColor *color = (DTColor *)[UIColor blackColor];
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
	STAssertEqualObjects(shadowColor, [UIColor redColor], @"Color should be red");
}


- (void)testShadowColorLast
{
	NSString *string = @"1px 2px 3px red;";
	
	DTColor *color = (DTColor *)[UIColor blackColor];
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
	STAssertEqualObjects(shadowColor, [UIColor redColor], @"Color should be red");
}

@end
