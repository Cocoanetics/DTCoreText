//
//  DTCoreTextLayoutFrameTest.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 14.11.13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTCoreTextTestCase.h"
#import "DTCoreTextLayouter.h"
#import "DTCoreTextLayoutFrame.h"

@interface DTCoreTextLayoutFrameTest : DTCoreTextTestCase

@end

@implementation DTCoreTextLayoutFrameTest

- (void)testVariableHeight
{
	NSAttributedString *attributedString = [super attributedStringFromHTMLString:@"<b>Some bold text</b>" options:nil];
	
	DTCoreTextLayouter *layouter = [[DTCoreTextLayouter alloc] initWithAttributedString:attributedString];
	
	CGRect maxRect = CGRectMake(10, 20, 1024, CGFLOAT_HEIGHT_UNKNOWN);
	NSRange entireString = NSMakeRange(0, [attributedString length]);
	DTCoreTextLayoutFrame *layoutFrame = [layouter layoutFrameWithRect:maxRect range:entireString];
	
	CGSize sizeNeeded = [layoutFrame frame].size;
	CGSize sizeExpected = CGSizeMake(1024, 16);
	
	STAssertEquals(sizeNeeded, sizeExpected, @"Size incorrect");
}

- (void)testVariableHeightAndWidth
{
	NSAttributedString *attributedString = [super attributedStringFromHTMLString:@"<b>Some bold text</b>" options:nil];
	
	DTCoreTextLayouter *layouter = [[DTCoreTextLayouter alloc] initWithAttributedString:attributedString];
	
	CGRect maxRect = CGRectMake(10, 20, CGFLOAT_WIDTH_UNKNOWN, CGFLOAT_HEIGHT_UNKNOWN);
	NSRange entireString = NSMakeRange(0, [attributedString length]);
	DTCoreTextLayoutFrame *layoutFrame = [layouter layoutFrameWithRect:maxRect range:entireString];
	
	CGSize sizeNeeded = [layoutFrame frame].size;
	CGSize sizeExpected = CGSizeMake(76, 16);
	
	STAssertEquals(sizeNeeded, sizeExpected, @"Size incorrect");
}

@end
