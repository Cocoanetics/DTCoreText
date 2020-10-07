//
//  NSNumberRomanNumeralsTest.m
//  DTCoreText
//
//  Created by Kai Maschke on 26.07.16.
//  Copyright © 2016 Drobnik.com. All rights reserved.
//

#import <DTCoreText/NSNumber+RomanNumerals.h>
#import <XCTest/XCTest.h>

@interface NSNumberRomanNumeralsTest : XCTestCase

@end

@implementation NSNumberRomanNumeralsTest

- (void)testRomanNumeralConversion {
	XCTAssertEqualObjects([@(1) romanNumeral], @"I");
	XCTAssertEqualObjects([@(5) romanNumeral], @"V");
	XCTAssertEqualObjects([@(9) romanNumeral], @"IX");
	XCTAssertEqualObjects([@(10) romanNumeral], @"X");
	XCTAssertEqualObjects([@(11) romanNumeral], @"XI");
	XCTAssertEqualObjects([@(49) romanNumeral], @"XLIX");
	XCTAssertEqualObjects([@(880) romanNumeral], @"DCCCLXXX");
	XCTAssertEqualObjects([@(3999) romanNumeral], @"MMMCMXCIX");
}

@end
