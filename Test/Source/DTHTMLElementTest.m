//
//  DTHTMLElementTest.m
//  DTCoreText
//
//  Created by Hubert SARRET on 11/04/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTHTMLElementTest.h"

#import "DTHTMLAttributedStringBuilder.h"

@implementation DTHTMLElementTest

- (void)testHTMLAlign
{
	NSDictionary *testValues = [NSDictionary dictionaryWithObjectsAndKeys:
								[NSNumber numberWithChar:kCTTextAlignmentJustified], @"<div align=\"justify\">text to align</div>",
								[NSNumber numberWithChar:kCTTextAlignmentLeft], @"<div align=\"left\">text to align</div>",
								[NSNumber numberWithChar:kCTTextAlignmentRight], @"<div align=\"right\">text to align</div>",
								[NSNumber numberWithChar:kCTTextAlignmentCenter], @"<div align=\"center\">text to align</div>",
								nil];

	[testValues enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		NSString *HTML = key;
		NSData *data = [HTML dataUsingEncoding:NSUTF8StringEncoding];
		DTHTMLAttributedStringBuilder *builder = [[DTHTMLAttributedStringBuilder alloc] initWithHTML:data options:nil documentAttributes:NULL];
		NSAttributedString *iosString = [builder generatedAttributedString];

		CTParagraphStyleRef paragraphStyle = (__bridge CTParagraphStyleRef)[iosString attribute:(id)kCTParagraphStyleAttributeName atIndex:0 effectiveRange:NULL];
		CTTextAlignment	alignment;
		CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierAlignment, sizeof(alignment), &alignment);

		STAssertTrue(alignment == [obj charValue], @"Text alignment should be justified");
	}];
}

@end
