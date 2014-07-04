//
//  DTCoreTextTestCase.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 25.09.13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTCoreTextTestCase.h"

@implementation DTCoreTextTestCase

- (NSAttributedString *)attributedStringFromTestFileName:(NSString *)testFileName
{
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *path = [bundle pathForResource:testFileName ofType:@"html"];
	NSData *data = [NSData dataWithContentsOfFile:path];
	
	DTHTMLAttributedStringBuilder *builder = [[DTHTMLAttributedStringBuilder alloc] initWithHTML:data options:nil documentAttributes:NULL];
	return [builder generatedAttributedString];
}

- (NSAttributedString *)attributedStringFromHTMLString:(NSString *)HTMLString options:(NSDictionary *)options
{
	NSData *data = [HTMLString dataUsingEncoding:NSUTF8StringEncoding];
	
	// set the base URL so that resources are found in the resource bundle
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSURL *baseURL = [bundle resourceURL];
	
	NSMutableDictionary *mutableOptions = [[NSMutableDictionary alloc] initWithDictionary:options];
	mutableOptions[NSBaseURLDocumentOption] = baseURL;
	
	// register a custom class for a tag
	[DTTextAttachment registerClass:[DTObjectTextAttachment class] forTagName:@"oliver"];

	DTHTMLAttributedStringBuilder *builder = [[DTHTMLAttributedStringBuilder alloc] initWithHTML:data options:mutableOptions documentAttributes:NULL];
	return [builder generatedAttributedString];
}

@end
