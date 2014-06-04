//
//  NSAttributedString+HTML.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <CoreText/CoreText.h>
#elif TARGET_OS_MAC
#import <ApplicationServices/ApplicationServices.h>
#endif

#import "DTCoreText.h"

@implementation NSAttributedString (HTML)

- (id)initWithHTMLData:(NSData *)data documentAttributes:(NSDictionary * __autoreleasing*)docAttributes
{
	return [self initWithHTMLData:data options:nil documentAttributes:docAttributes];
}

- (id)initWithHTMLData:(NSData *)data baseURL:(NSURL *)base documentAttributes:(NSDictionary * __autoreleasing*)docAttributes
{
	NSDictionary *optionsDict = nil;
	
	if (base)
	{
		optionsDict = [NSDictionary dictionaryWithObject:base forKey:NSBaseURLDocumentOption];
	}
	
	return [self initWithHTMLData:data options:optionsDict documentAttributes:docAttributes];
}

- (id)initWithHTMLData:(NSData *)data options:(NSDictionary *)options documentAttributes:(NSDictionary * __autoreleasing*)docAttributes
{
	// only with valid data
	if (![data length])
	{
		return nil;
	}
	
	DTHTMLAttributedStringBuilder *stringBuilder = [[DTHTMLAttributedStringBuilder alloc] initWithHTML:data options:options documentAttributes:docAttributes];

	void (^callBackBlock)(DTHTMLElement *element) = [options objectForKey:DTWillFlushBlockCallBack];
	
	if (callBackBlock)
	{
		[stringBuilder setWillFlushCallback:callBackBlock];
	}
	
	// This needs to be on a seprate line so that ARC can handle releasing the object properly
	// return [stringBuilder generatedAttributedString]; shows leak in instruments
	id string = [stringBuilder generatedAttributedString];
	
	return string;
}

#pragma mark - Working with Custom HTML Attributes

- (NSDictionary *)HTMLAttributesAtIndex:(NSUInteger)index
{
	return [self attribute:DTCustomAttributesAttribute atIndex:index effectiveRange:NULL];
}

- (NSRange)rangeOfHTMLAttribute:(NSString *)name atIndex:(NSUInteger)index
{
	NSRange rangeSoFar;
	
	NSDictionary *attributes = [self attribute:DTCustomAttributesAttribute atIndex:index effectiveRange:&rangeSoFar];
	
	NSAssert(attributes, @"No custom attribute '%@' at index %d", name, (int)index);
	
	// check if there is a value for this custom attribute name
	id value = [attributes objectForKey:name];
	
	if (!attributes || !value)
	{
		return NSMakeRange(NSNotFound, 0);
	}
	
	// search towards beginning
	while (rangeSoFar.location>0)
	{
		NSRange extendedRange;
		attributes = [self attribute:DTCustomAttributesAttribute atIndex:rangeSoFar.location-1 effectiveRange:&extendedRange];
		
		id extendedValue = [attributes objectForKey:name];
		
		// abort search if key not found or value not identical
		if (!extendedValue || ![extendedValue isEqual:value])
		{
			break;
		}
		
		rangeSoFar = NSUnionRange(rangeSoFar, extendedRange);
	}
	
	NSUInteger length = [self length];
	
	// search towards end
	while (NSMaxRange(rangeSoFar)<length)
	{
		NSRange extendedRange;
		attributes = [self attribute:DTCustomAttributesAttribute atIndex:NSMaxRange(rangeSoFar) effectiveRange:&extendedRange];
		
		id extendedValue = [attributes objectForKey:name];
		
		// abort search if key not found or value not identical
		if (!extendedValue || ![extendedValue isEqual:value])
		{
			break;
		}
		
		rangeSoFar = NSUnionRange(rangeSoFar, extendedRange);
	}
	
	return rangeSoFar;
}

@end
