//
//  DTCoreTextTestCase.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 25.09.13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTCoreTextTestCase.h"
#import <Foundation/Foundation.h>

@import DTCoreText;

@implementation DTCoreTextTestCase

- (NSBundle*) testBundle {
#if SWIFT_PACKAGE
    return SWIFTPM_MODULE_BUNDLE;
#else
    return [NSBundle bundleForClass:[self class]];
#endif
}

- (NSAttributedString *)attributedStringFromTestFileName:(NSString *)testFileName
{
	NSString *path = [[self testBundle] pathForResource:testFileName ofType:@"html"];
	NSData *data = [NSData dataWithContentsOfFile:path];
	
	DTHTMLAttributedStringBuilder *builder = [[DTHTMLAttributedStringBuilder alloc] initWithHTML:data options:nil documentAttributes:NULL];
	return [builder generatedAttributedString];
}

- (NSAttributedString *)attributedStringFromHTMLString:(NSString *)HTMLString options:(NSDictionary *)options
{
	NSData *data = [HTMLString dataUsingEncoding:NSUTF8StringEncoding];
    
    // set the base URL so that resources are found in the resource bundle
	NSURL *baseURL = [[self testBundle] resourceURL];
	
	NSMutableDictionary *mutableOptions = [[NSMutableDictionary alloc] initWithDictionary:options];
	mutableOptions[NSBaseURLDocumentOption] = baseURL;
	
	// register a custom class for a tag
	[DTTextAttachment registerClass:[DTObjectTextAttachment class] forTagName:@"oliver"];

	DTHTMLAttributedStringBuilder *builder = [[DTHTMLAttributedStringBuilder alloc] initWithHTML:data options:mutableOptions documentAttributes:NULL];
	return [builder generatedAttributedString];
}

@end
