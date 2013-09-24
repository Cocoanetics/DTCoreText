//
//  DTHTMLWriterTest.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 11.07.13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTHTMLWriterTest.h"
#import "DTCoreText.h"
#import "DTColorFunctions.h"

@implementation DTHTMLWriterTest

- (NSAttributedString *)_attributedStringFromHTMLString:(NSString *)HTMLString options:(NSDictionary *)options
{
	NSData *data = [HTMLString dataUsingEncoding:NSUTF8StringEncoding];
	
	// set the base URL so that resources are found in the resource bundle
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSURL *baseURL = [bundle resourceURL];
	
	NSMutableDictionary *mutableOptions = [[NSMutableDictionary alloc] initWithDictionary:options];
	mutableOptions[NSBaseURLDocumentOption] = baseURL;
	
	
	DTHTMLAttributedStringBuilder *builder = [[DTHTMLAttributedStringBuilder alloc] initWithHTML:data options:mutableOptions documentAttributes:NULL];
	return [builder generatedAttributedString];
}

- (void)testBackgroundColor
{
	// create attributed string
	NSMutableAttributedString* attributedText = [[NSMutableAttributedString alloc] initWithString:@"Hello World"];
	NSRange range = [attributedText.string rangeOfString:@"World"];
	if (range.location != NSNotFound)
	{
		DTColor *color = DTColorCreateWithHexString(@"FFFF00");
		
		[attributedText addAttribute:DTBackgroundColorAttribute value:(id)color.CGColor range:range];
	}
	
	// generate html
	DTHTMLWriter *writer = [[DTHTMLWriter alloc] initWithAttributedString:attributedText];
	writer.useAppleConvertedSpace = NO;
	NSString* html = [writer HTMLFragment];
	
	NSRange colorRange = [html rangeOfString:@"background-color:#ffff00"];

	STAssertTrue(colorRange.location != NSNotFound,  @"html should contains background-color:#ffff00");
}
	
- (void)_testListIndentRoundTripFromHTML:(NSString *)HTML
{
	NSAttributedString *string1 = [self _attributedStringFromHTMLString:HTML options:nil];
	
	// generate html
	DTHTMLWriter *writer1 = [[DTHTMLWriter alloc] initWithAttributedString:string1];
	NSString* html1 = [writer1 HTMLFragment];
	
	NSAttributedString *string2 = [self _attributedStringFromHTMLString:html1 options:nil];
	
	STAssertTrue([string1 length] == [string2 length], @"Roundtripped string should be of equal length");

	[[string1 string] enumerateSubstringsInRange:NSMakeRange(0, [string1 length]) options:NSStringEnumerationByParagraphs usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
		
		NSDictionary *attributes1 = [string1 attributesAtIndex:substringRange.location effectiveRange:NULL];
		NSDictionary *attributes2 = [string2 attributesAtIndex:substringRange.location effectiveRange:NULL];
		
		DTCoreTextParagraphStyle *paraStyle1 = [attributes1 paragraphStyle];
		DTCoreTextParagraphStyle *paraStyle2 = [attributes2 paragraphStyle];
		
		BOOL equal = [paraStyle1 isEqual:paraStyle2];
		
		if (!equal)
		{
			NSLog(@"Hier");
		}
		
		STAssertTrue(equal, @"Paragraph Styles in range %@ should be equal", NSStringFromRange(substringRange));
		
		NSRange prefixRange;
		NSString *prefix1 = [string1 attribute:DTListPrefixField atIndex:substringRange.location effectiveRange:&prefixRange];
		NSString *prefix2 = [attributes1 objectForKey:DTListPrefixField];
		
		STAssertEqualObjects(prefix1, prefix2, @"List prefix fields should be equal in range %@", NSStringFromRange(substringRange));
		
		NSArray *lists1 = [attributes1 objectForKey:DTTextListsAttribute];
		NSArray *lists2 = [attributes2 objectForKey:DTTextListsAttribute];
		
		STAssertEqualObjects(lists1, lists2, @"Lists should be equal in range %@", NSStringFromRange(substringRange));
		
		
		if (NSMaxRange(prefixRange) < NSMaxRange(enclosingRange))
		{
			attributes1 = [string1 attributesAtIndex:NSMaxRange(prefixRange) effectiveRange:NULL];
			attributes2 = [string2 attributesAtIndex:NSMaxRange(prefixRange) effectiveRange:NULL];
			
			paraStyle1 = [attributes1 paragraphStyle];
			paraStyle2 = [attributes2 paragraphStyle];
			
			equal = [paraStyle1 isEqual:paraStyle2];
			
			
			STAssertTrue(equal, @"Paragraph Styles following prefix in range %@ should be equal", NSStringFromRange(substringRange));
		}
	}];
}

- (void)testSimpleListRoundTrip
{
	[self _testListIndentRoundTripFromHTML:@"<ul><li>fooo</li><li>fooo</li><li>fooo</li></ul>"];
}

/*
 --- needs fix for nested list writing first, the first LI gets closed before the UL opening
- (void)testNestedListRoundTrip
{
	[self _testListIndentRoundTripFromHTML:@"<ol><li>1a<ul><li>2a<ol><li>3a</li></ol></li></ul></li></ol>"];
}
 */

- (void)testNestedListWithPaddingRoundTrip
{
	[self _testListIndentRoundTripFromHTML:@"<ul style=\"padding-left:55px\"><li>fooo<ul style=\"padding-left:66px\"><li>bar</li></ul></li></ul>"];
}

@end
