//
//  NSAttributedString+HTML.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#if TARGET_OS_IPHONE
#elif TARGET_OS_MAC
#import <ApplicationServices/ApplicationServices.h>
#endif

#import "DTHTMLElement.h"
#import "DTCoreTextConstants.h"
#import "DTHTMLAttributedStringBuilder.h"
#import "DTTextAttachment.h"
#import "NSAttributedStringRunDelegates.h"

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
	
	// This needs to be on a separate line so that ARC can handle releasing the object properly
	// return [stringBuilder generatedAttributedString]; shows leak in instruments
	id string = [stringBuilder generatedAttributedString];
	
	return string;
}

#pragma mark - NSAttributedString Archiving

- (NSData *)convertToData
{
	NSUInteger length = [self length];
	
	NSMutableAttributedString *appendString = [self mutableCopy];
	if (length)
	{
		[self enumerateAttributesInRange:NSMakeRange(0, length-1) options:0 usingBlock:^(NSDictionary<NSString *,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
			
			if (attrs[NSAttachmentAttributeName])
			{
				[appendString removeAttribute:(id)kCTRunDelegateAttributeName range:range];
			}
		}];
	}

	NSData *data = nil;
	@try
	{
		data = [NSKeyedArchiver archivedDataWithRootObject:appendString];
	}
	@catch (NSException *exception)
	{
		data = nil;
	}
	
	return data;
}

+ (NSAttributedString *)attributedStringWithData:(NSData *)data
{
	NSMutableAttributedString *appendString = nil;
	
	@try
	{
		appendString = (NSMutableAttributedString *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
	}
	@catch (NSException *exception)
	{
		appendString = nil;
	}
	
	NSUInteger length = [appendString length];
	
	if (length)
	{
		[appendString enumerateAttributesInRange:NSMakeRange(0, length-1) options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(NSDictionary<NSString *,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
			
			if (attrs[NSAttachmentAttributeName])
			{
				DTTextAttachment *attatchment = attrs[NSAttachmentAttributeName];
				CTRunDelegateRef embeddedObjectRunDelegate = createEmbeddedObjectRunDelegate(attatchment);
				
				[appendString addAttribute:(id)kCTRunDelegateAttributeName value:CFBridgingRelease(embeddedObjectRunDelegate) range:range];
			}
			
		}];
	}
	
	return [appendString copy];
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
