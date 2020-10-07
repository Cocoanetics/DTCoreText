//
//  DTCSSListStyleTest.m
//  DTCoreText
//
//  Created by Ryan Johnson on 2/19/14.
//  Copyright (c) 2014 Drobnik.com. All rights reserved.
//

#import <DTCoreText/DTCoreText.h>
#import <XCTest/XCTest.h>

@interface DTCSSListStyleTest : XCTestCase

@end

@implementation DTCSSListStyleTest

- (void)testNSCodingEqual {
	NSDictionary *styles = @{@"list-style-type":@"none", @"list-style-position":@"inherit"};
	DTCSSListStyle *listStyle = [[DTCSSListStyle alloc] initWithStyles:styles];

	NSData *listStyleData = [NSKeyedArchiver archivedDataWithRootObject:listStyle];
	DTCSSListStyle *unarchivedListStyle = [NSKeyedUnarchiver unarchiveObjectWithData:listStyleData];

	XCTAssertTrue([listStyle isEqualToListStyle:unarchivedListStyle], @"Unarchived list styles should be equal to original");
}

- (void)testNSCodingNotEqual {
	NSDictionary *styles1 = @{@"list-style-type":@"none", @"list-style-position":@"inherit"};
	DTCSSListStyle *listStyle1 = [[DTCSSListStyle alloc] initWithStyles:styles1];

	NSDictionary *styles2 = @{@"list-style-type":@"circle", @"list-style-position":@"inherit"};
	DTCSSListStyle *listStyle2 = [[DTCSSListStyle alloc] initWithStyles:styles2];

	XCTAssertFalse([listStyle1 isEqualToListStyle:listStyle2], @"Sanity check");

	NSData *listStyle1Data = [NSKeyedArchiver archivedDataWithRootObject:listStyle1];
	DTCSSListStyle *unarchivedListStyle1 = [NSKeyedUnarchiver unarchiveObjectWithData:listStyle1Data];

	XCTAssertFalse([unarchivedListStyle1 isEqualToListStyle:listStyle2], @"Different list styles should remain different");

}

@end
