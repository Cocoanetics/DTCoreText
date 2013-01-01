//
//  DTHTMLAttributedStringBuilderTest.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 25.12.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTHTMLAttributedStringBuilderTest.h"

#import "DTHTMLAttributedStringBuilder.h"
#import "DTCoreTextConstants.h"

@implementation DTHTMLAttributedStringBuilderTest

- (void)testSpaceBetweenUnderlines
{
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *path = [bundle pathForResource:@"SpaceBetweenUnderlines" ofType:@"html"];
	
	NSData *data = [NSData dataWithContentsOfFile:path];
	
	DTHTMLAttributedStringBuilder *builder = [[DTHTMLAttributedStringBuilder alloc] initWithHTML:data options:nil documentAttributes:NULL];
	
	NSAttributedString *output = [builder generatedAttributedString];
	
	NSRange range_a;
	NSNumber *underLine = [output attribute:(id)kCTUnderlineStyleAttributeName atIndex:1 effectiveRange:&range_a];
	
	STAssertTrue([underLine integerValue]==0, @"Space between a and b should not be underlined");
}

// a block following an inline image should only cause a \n after the image, not whitespace
- (void)testWhitspaceAfterParagraphPromotedImage
{
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *path = [bundle pathForResource:@"WhitespaceFollowingImagePromotedToParagraph" ofType:@"html"];
	
	NSData *data = [NSData dataWithContentsOfFile:path];
	
	DTHTMLAttributedStringBuilder *builder = [[DTHTMLAttributedStringBuilder alloc] initWithHTML:data options:nil documentAttributes:NULL];
	
	NSAttributedString *output = [builder generatedAttributedString];
	
	STAssertTrue([output length]==6, @"Generated String should be 6 characters");
	
	NSMutableString *expectedOutput = [NSMutableString stringWithFormat:@"1\n%@\n2\n", UNICODE_OBJECT_PLACEHOLDER];
	
	STAssertTrue([expectedOutput isEqualToString:[output string]], @"Expected output not matching");
}

// This should come out as Keep_me_together with the _ being non-breaking spaces
- (void)testKeepMeTogether
{
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *path = [bundle pathForResource:@"KeepMeTogether" ofType:@"html"];
	
	NSData *data = [NSData dataWithContentsOfFile:path];
	
	DTHTMLAttributedStringBuilder *builder = [[DTHTMLAttributedStringBuilder alloc] initWithHTML:data options:nil documentAttributes:NULL];
	
	NSAttributedString *output = [builder generatedAttributedString];
	
	NSString *expectedOutput = @"Keep\u00a0me\u00a0together";
	
	STAssertTrue([expectedOutput isEqualToString:[output string]], @"Expected output not matching");
}

@end
