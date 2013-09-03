//
//  DTCoreTextParagraphStyleTest.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 2/25/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTCoreTextParagraphStyleTest.h"
#import "DTCoreTextParagraphStyle.h"

@implementation DTCoreTextParagraphStyleTest

// issue 498: loss of tab stops
- (void)testLossOfTabStops
{
	DTCoreTextParagraphStyle *paragraphStyle = [[DTCoreTextParagraphStyle alloc] init];
	[paragraphStyle addTabStopAtPosition:10 alignment:kCTTextAlignmentLeft];
	
	// create a CTParagraphStyle from it
	CTParagraphStyleRef ctParagraphStyle = [paragraphStyle createCTParagraphStyle];
	
	// create a new DT style from it
	DTCoreTextParagraphStyle *newParagraphStyle = [[DTCoreTextParagraphStyle alloc] initWithCTParagraphStyle:ctParagraphStyle];
	
	STAssertNotNil(newParagraphStyle.tabStops, @"There are no tab stops in newly created paragraph style");
}

@end
