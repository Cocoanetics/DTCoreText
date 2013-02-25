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

- (void)testCache
{
	// make a test style
	DTCoreTextParagraphStyle *paraStyle = [[DTCoreTextParagraphStyle alloc] init];
	paraStyle.lineHeightMultiple = 2.0f;
	paraStyle.headIndent = 30;
	
	CTParagraphStyleRef para1 = [paraStyle createCTParagraphStyle];
	CTParagraphStyleRef para2 = [paraStyle createCTParagraphStyle];
	
	STAssertEquals(para1, para2, @"Two successife Paragraph Styles should be identical");
	
	// change something
	
	paraStyle.tailIndent = -20;

	CTParagraphStyleRef para3 = [paraStyle createCTParagraphStyle];
	
	STAssertTrue(para2!=para3, @"Paragraph Styles should not be identical after change");
	
	// change back
	
	paraStyle.tailIndent = 0;
	
	CTParagraphStyleRef para4 = [paraStyle createCTParagraphStyle];
	
	STAssertEquals(para1, para4, @"Paragraph Styles should be identical after change back");
	
	// cleanup
	
	CFRelease(para1);
	CFRelease(para2);
	CFRelease(para3);
	CFRelease(para4);
}

@end
