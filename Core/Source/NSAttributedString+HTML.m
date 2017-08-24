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

#if TARGET_OS_IPHONE
#import "NSAttributedStringRunDelegates.h"
#endif

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
+ (NSMutableDictionary *)getArchivingDictionaryWith:(NSDictionary *)attrs
{
	
	NSDictionary *archiveDict = attrs[DTArchivingAttribute];
	NSMutableDictionary *dict = nil;
	
	if (![archiveDict isKindOfClass:[NSDictionary class]])
	{
		dict = [NSMutableDictionary dictionary];
	}
	else
	{
		dict = [archiveDict mutableCopy];
	}
	
	
	return dict;
}

- (NSData *)convertToData
{
	NSMutableAttributedString *appendString = [self mutableCopy];
#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES && TARGET_OS_IPHONE
	NSUInteger length = [self length];
	if (length)
	{
		[self enumerateAttributesInRange:NSMakeRange(0, length-1) options:0 usingBlock:^(NSDictionary<NSString *,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
			
			NSMutableDictionary *dict = [[self class] getArchivingDictionaryWith:attrs];
			
			if (attrs[NSAttachmentAttributeName])
			{
				DTTextAttachment *attatchment = attrs[NSAttachmentAttributeName];
				
				NSString *imgPath = nil;
				
				if ([[attatchment.contentURL scheme] isEqualToString:@"file"])
				{
					imgPath = [attatchment.contentURL path];
					NSUInteger homeDirLength = [NSHomeDirectory() length];
					
					if ([imgPath hasPrefix:NSHomeDirectory()] && [imgPath length] > homeDirLength)
					{
						imgPath = [imgPath substringFromIndex:homeDirLength];
					}
				}
				else
				{
					imgPath = [attatchment.contentURL absoluteString];
				}
				
				if (imgPath)
				{
					[dict setObject:imgPath forKey:NSAttachmentAttributeName];
					[appendString addAttribute:DTArchivingAttribute value:dict range:range];
				}
				
				[appendString removeAttribute:(id)kCTRunDelegateAttributeName range:range];
			}
			// if there will others attribute to archiving , implement like this.
			if (attrs[DTBackgroundStrokeColorAttribute])
			{
				CGColorRef strokeColor = (__bridge CGColorRef)(attrs[DTBackgroundStrokeColorAttribute]);
				
				UIColor *stoke = [[UIColor alloc] initWithCGColor:strokeColor];
				[dict setObject:stoke forKey:DTBackgroundStrokeColorAttribute];
				
				[appendString addAttribute:DTArchivingAttribute value:dict range:range];
				[appendString removeAttribute:(id)DTBackgroundStrokeColorAttribute range:range];
			}
			
		}];
	}
#endif
	
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
			
#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES && TARGET_OS_IPHONE
			
			if (attrs[NSAttachmentAttributeName])
			{
				DTTextAttachment *attatchment = attrs[NSAttachmentAttributeName];
				
				if ([[attatchment.contentURL scheme] isEqualToString:@"file"])
				{
					NSMutableDictionary *dict = [[self class] getArchivingDictionaryWith:attrs];
					
					NSString *imgPath = dict[NSAttachmentAttributeName];
					if (imgPath)
					{
						if (![imgPath hasPrefix:NSHomeDirectory()])
						{
							imgPath = [NSHomeDirectory() stringByAppendingPathComponent:imgPath];
						}
						attatchment.contentURL =  [NSURL fileURLWithPath:imgPath];
					}
				}
				
				CTRunDelegateRef embeddedObjectRunDelegate = createEmbeddedObjectRunDelegate(attatchment);
				
				[appendString addAttribute:(id)kCTRunDelegateAttributeName value:CFBridgingRelease(embeddedObjectRunDelegate) range:range];
			}
			// if there will others attribute to archiving , implement like this.
			if (attrs[DTBackgroundStrokeColorAttribute])
			{
				NSMutableDictionary *dict = [self getArchivingDictionaryWith:attrs];
				UIColor *stroke = dict[DTBackgroundStrokeColorAttribute];
				CGColorRef strokeColor = stroke.CGColor;
				
				[appendString addAttribute:DTBackgroundStrokeColorAttribute value:(__bridge id)strokeColor range:range];
			}
#endif
			
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
