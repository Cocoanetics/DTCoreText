//
//  DTHTMLElementTest.m
//  DTCoreText
//
//  Created by Hubert SARRET on 11/04/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTHTMLElementTest.h"
#import "DTCoreText.h"

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

		XCTAssertTrue(alignment == [obj charValue], @"Text alignment should be justified");
	}];
}

// issue 780: Applying a style dictionary with both -webkit and normal margin
- (void)testCombiningWebKitAndNormalMargin
{
	DTHTMLElement *element = [[DTHTMLElement alloc] init];
	element.textScale = 1;
	element.paragraphStyle = [DTCoreTextParagraphStyle defaultParagraphStyle];
	CTFontRef font = CTFontCreateWithName(CFSTR("Helvetica"), 20, NULL);
	element.fontDescriptor = [DTCoreTextFontDescriptor fontDescriptorForCTFont:font];
	CFRelease(font);
	
	NSDictionary *styles = @{@"-webkit-margin-after" : @"1em",
									 @"-webkit-margin-before" : @"1em",
									 @"-webkit-margin-end" : @"0",
									 @"-webkit-margin-start" : @"0",
									 @"display" : @"block",
									 @"margin-left" : @"40px"};
	
	[element applyStyleDictionary:styles];
	
	XCTAssertEqual(element.margins.left, 40, @"Incorrect left margin");
	XCTAssertEqual(element.margins.right, 0, @"Incorrect right margin");
	XCTAssertEqual(element.margins.top, 20, @"Incorrect top margin");
	XCTAssertEqual(element.margins.bottom, 20, @"Incorrect bottom margin");
}

// issue 738: Attachments with display:none should not show
- (void)testAttachmentWithDisplayNone
{
	DTHTMLElement *element = [[DTHTMLElement alloc] init];
	element.textScale = 1;
	element.paragraphStyle = [DTCoreTextParagraphStyle defaultParagraphStyle];
	CTFontRef font = CTFontCreateWithName(CFSTR("Helvetica"), 20, NULL);
	element.fontDescriptor = [DTCoreTextFontDescriptor fontDescriptorForCTFont:font];
	CFRelease(font);
	
	DTObjectTextAttachment *object = [[DTObjectTextAttachment alloc] initWithElement:element options:nil];
	element.textAttachment = object;
	
	NSDictionary *styles = @{@"display" : @"none"};
	[element applyStyleDictionary:styles];
	
	NSAttributedString *attributedString = [element attributedString];
	
	XCTAssertNil(attributedString, @"Text attachment should be invisible");
}

@end
