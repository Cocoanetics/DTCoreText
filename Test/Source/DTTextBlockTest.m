//
//  DTTextBlockTest.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 9/29/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTTextBlockTest.h"

@implementation DTTextBlockTest

- (void)testEquals
{
	DTTextBlock *block1 = [[DTTextBlock alloc] init];
	block1.padding = DTEdgeInsetsMake(10, 20, 30, 40);
	block1.backgroundColor = DTColorCreateWithHTMLName(@"red");
	
	DTTextBlock *block2 = [[DTTextBlock alloc] init];
	block2.padding = DTEdgeInsetsMake(10, 20, 30, 40);
	block2.backgroundColor = DTColorCreateWithHTMLName(@"red");

	XCTAssertTrue([block1 isEqual:block2], @"Both blocks should be equal");
	XCTAssertTrue([block1 isEqual:block1], @"Should be true against itself");
	
	// different color
	block2.backgroundColor = DTColorCreateWithHTMLName(@"blue");
	XCTAssertFalse([block1 isEqual:block2], @"same padding different color should be different");
	
	XCTAssertFalse([block1 isEqual:nil], @"isEqual:nil should be false");
	XCTAssertFalse([block1 isEqual:@"bla"], @"isEqual: to string should be false");
	
	// exactly same color
	block2.backgroundColor = block1.backgroundColor;
	XCTAssertTrue([block1 isEqual:block2], @"Should be true against with exactly same color");
	
	// same color different padding
	block2.padding = DTEdgeInsetsMake(10, 20, 30, 50);
	block2.backgroundColor = DTColorCreateWithHTMLName(@"red");
	XCTAssertFalse([block1 isEqual:block2], @"different padding same color should be different");
}

- (void)testHash
{
	DTTextBlock *block1 = [[DTTextBlock alloc] init];
	block1.padding = DTEdgeInsetsMake(10, 20, 30, 40);
	
	NSUInteger hash = [block1 hash];
	
	XCTAssertEqual(hash, (NSUInteger)201010757, @"hash should be 201010757");
}

- (void)testNSCodingEqual {
	DTTextBlock *block = [[DTTextBlock alloc] init];
	block.padding = DTEdgeInsetsMake(10, 20, 30, 40);
	block.backgroundColor = DTColorCreateWithHTMLName(@"red");

	NSData *blockData = [NSKeyedArchiver archivedDataWithRootObject:block];
	DTTextBlock *blockUnarchived = [NSKeyedUnarchiver unarchiveObjectWithData:blockData];

	XCTAssertTrue([block isEqual:blockUnarchived], @"Unarchived block should be equal to original");
}

- (void)testNSCodingNotEqual {
	DTTextBlock *block1 = [[DTTextBlock alloc] init];
	block1.padding = DTEdgeInsetsMake(10, 20, 30, 40);
	block1.backgroundColor = DTColorCreateWithHTMLName(@"red");

	DTTextBlock *block2 = [[DTTextBlock alloc] init];
	block2.padding = DTEdgeInsetsMake(20, 30, 40, 50);
	block2.backgroundColor = DTColorCreateWithHTMLName(@"blue");

	XCTAssertFalse([block1 isEqual:block2], @"Sanity check");

	NSData *block1Data = [NSKeyedArchiver archivedDataWithRootObject:block1];
	DTTextBlock *block1Unarchived = [NSKeyedUnarchiver unarchiveObjectWithData:block1Data];

	XCTAssertFalse([block1Unarchived isEqual:block2], @"Different blocks should remain different");
}

@end
