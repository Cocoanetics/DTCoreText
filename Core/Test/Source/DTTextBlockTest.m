//
//  DTTextBlockTest.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 9/29/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTTextBlockTest.h"

#import "DTTextBlock.h"

@implementation DTTextBlockTest

- (void)testEquals
{
	DTTextBlock *block1 = [[DTTextBlock alloc] init];
	block1.padding = DTEdgeInsetsMake(10, 20, 30, 40);
	block1.backgroundColor = DTColorCreateWithHTMLName(@"red");
	
	DTTextBlock *block2 = [[DTTextBlock alloc] init];
	block2.padding = DTEdgeInsetsMake(10, 20, 30, 40);
	block2.backgroundColor = DTColorCreateWithHTMLName(@"red");

	STAssertTrue([block1 isEqual:block2], @"Both blocks should be equal");
	STAssertTrue([block1 isEqual:block1], @"Should be true against itself");
	
	// different color
	block2.backgroundColor = DTColorCreateWithHTMLName(@"blue");
	STAssertFalse([block1 isEqual:block2], @"same padding different color should be different");
	
	STAssertFalse([block1 isEqual:nil], @"isEqual:nil should be false");
	STAssertFalse([block1 isEqual:@"bla"], @"isEqual: to string should be false");
	
	// exactly same color
	block2.backgroundColor = block1.backgroundColor;
	STAssertTrue([block1 isEqual:block2], @"Should be true against with exactly same color");
	
	// same color different padding
	block2.padding = DTEdgeInsetsMake(10, 20, 30, 50);
	block2.backgroundColor = DTColorCreateWithHTMLName(@"red");
	STAssertFalse([block1 isEqual:block2], @"different padding same color should be different");
}

- (void)testHash
{
	DTTextBlock *block1 = [[DTTextBlock alloc] init];
	block1.padding = DTEdgeInsetsMake(10, 20, 30, 40);
	
	NSUInteger hash = [block1 hash];
	
	STAssertEquals(hash, (NSUInteger)201010757, @"hash should be 201010757");
}

@end
