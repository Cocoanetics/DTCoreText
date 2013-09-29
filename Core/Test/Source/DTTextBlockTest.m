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

	DTTextBlock *block2 = [[DTTextBlock alloc] init];
	block2.padding = DTEdgeInsetsMake(10, 20, 30, 40);

	STAssertEqualObjects(block1, block2, @"Both blocks should be equal");
	
	STAssertFalse([block1 isEqual:nil], @"isEqual:nil should be false");
	STAssertFalse([block1 isEqual:@"bla"], @"isEqual: to string should be false");
}

- (void)testHash
{
	DTTextBlock *block1 = [[DTTextBlock alloc] init];
	block1.padding = DTEdgeInsetsMake(10, 20, 30, 40);
	
	NSUInteger hash = [block1 hash];
	
	STAssertEquals(hash, (NSUInteger)201010757, @"hash should be 201010757");
}

@end
