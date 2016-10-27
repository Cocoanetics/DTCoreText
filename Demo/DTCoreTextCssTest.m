//
//  DTCoreTextCssTest.m
//  DTCoreText
//
//  Created by Claus Weymann on 27/10/16.
//  Copyright © 2016 Drobnik.com. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "DTCSSStylesheet.h"

@interface DTCoreTextCssTest : XCTestCase

@end

@implementation DTCoreTextCssTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
	NSString* mergedCSS = [NSString stringWithContentsOfURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"text" withExtension:@"css"] encoding:NSUTF8StringEncoding error:nil];
	__block DTCSSStylesheet* stylesheet;
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
		stylesheet = [[DTCSSStylesheet alloc] initWithStyleBlock: mergedCSS];
    }];
	NSLog(@"%@",stylesheet);
}

@end
