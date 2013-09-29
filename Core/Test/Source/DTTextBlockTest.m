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
}

@end
