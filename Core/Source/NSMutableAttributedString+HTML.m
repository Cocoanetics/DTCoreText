//
//  NSMutableAttributedString+HTML.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 4/14/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "NSMutableAttributedString+HTML.h"

#import "DTCoreText.h"

@implementation NSMutableAttributedString (HTML)


// appends a plain string extending the attributes at this position
- (void)appendString:(NSString *)string
{
	NSParameterAssert(string);
	
	NSUInteger length = [self length];
	NSAttributedString *appendString = nil;
	
	if (length)
	{
		// get attributes at end of self
		NSMutableDictionary *attributes = [[self attributesAtIndex:length-1 effectiveRange:NULL] mutableCopy];
		
		// we need to remove the image placeholder (if any) to prevent duplication
		[attributes removeObjectForKey:NSAttachmentAttributeName];
		[attributes removeObjectForKey:(id)kCTRunDelegateAttributeName];
		
		// we also remove field attribute, because appending plain strings should never extend an field
		[attributes removeObjectForKey:DTFieldAttribute];
		
		// create a temp attributed string from the appended part
		appendString = [[NSAttributedString alloc] initWithString:string attributes:attributes];
	}
	else
	{
		// no attributes to extend
		appendString = [[NSAttributedString alloc] initWithString:string];
	}

	[self appendAttributedString:appendString];
}

- (void)appendString:(NSString *)string withParagraphStyle:(DTCoreTextParagraphStyle *)paragraphStyle fontDescriptor:(DTCoreTextFontDescriptor *)fontDescriptor
{
	NSUInteger selfLengthBefore = [self length];
	
	[self.mutableString appendString:string];
	
	NSRange appendedStringRange = NSMakeRange(selfLengthBefore, [string length]);

	if (paragraphStyle || fontDescriptor)
	{
		NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
		
		if (paragraphStyle)
		{
#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES
			if (___useiOS6Attributes)
			{
				NSParagraphStyle *style = [paragraphStyle NSParagraphStyle];
				[attributes setObject:style forKey:NSParagraphStyleAttributeName];
			}
			else
#endif
			{
				CTParagraphStyleRef newParagraphStyle = [paragraphStyle createCTParagraphStyle];
				[attributes setObject:CFBridgingRelease(newParagraphStyle) forKey:(id)kCTParagraphStyleAttributeName];
			}
		}
		
		if (fontDescriptor)
		{
			CTFontRef newFont = [fontDescriptor newMatchingFont];
			
#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES && TARGET_OS_IPHONE
			if (___useiOS6Attributes)
			{
				// convert to UIFont
				UIFont *uiFont = [UIFont fontWithCTFont:newFont];
				[attributes setObject:uiFont forKey:NSFontAttributeName];
			
				CFRelease(newFont);
			}
			else
#endif
			{
				[attributes setObject:CFBridgingRelease(newFont) forKey:(id)kCTFontAttributeName];
			}
		}
		
		// Replace attributes
		[self setAttributes:attributes range:appendedStringRange];
	}
	else
	{
		// Remove attributes
		[self setAttributes:[NSDictionary dictionary] range:appendedStringRange];
	}
}

- (void)appendEndOfParagraph
{
	NSUInteger length = [self length];
	
	NSAssert(length, @"Cannot append end of paragraph to empty string");

	NSRange effectiveRange;
	NSDictionary *attributes = [self attributesAtIndex:length-1 effectiveRange:&effectiveRange];
	
	
	NSMutableDictionary *appendAttributes = [NSMutableDictionary dictionary];

	
#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES
	if (___useiOS6Attributes)
	{
		id font = [attributes objectForKey:NSFontAttributeName];
		
		if (font)
		{
			[appendAttributes setObject:font forKey:NSFontAttributeName];
		}
		
		id paragraphStyle = [attributes objectForKey:NSParagraphStyleAttributeName];
		
		if (paragraphStyle)
		{
			[appendAttributes setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
		}
	}
	else
#endif
	{
		CTFontRef font = (__bridge CTFontRef)[attributes objectForKey:(id)kCTFontAttributeName];
		
		if (font)
		{
			[appendAttributes setObject:(__bridge id)(font) forKey:(id)kCTFontAttributeName];
		}
		
		CTParagraphStyleRef paragraphStyle = (__bridge CTParagraphStyleRef)[attributes objectForKey:(id)kCTParagraphStyleAttributeName];
		
		if (paragraphStyle)
		{
			[appendAttributes setObject:(__bridge id)(paragraphStyle) forKey:(id)kCTParagraphStyleAttributeName];
		}
	}
	
	// transfer blocks
	NSArray *blocks = [attributes objectForKey:DTTextBlocksAttribute];
	
	if (blocks)
	{
		[appendAttributes setObject:blocks forKey:DTTextBlocksAttribute];
	}
	
	// transfer lists
	NSArray *lists = [attributes objectForKey:DTTextListsAttribute];
	
	if (lists)
	{
		[appendAttributes setObject:lists forKey:DTTextListsAttribute];
	}

	// transfer foreground color
	id foregroundColor = [attributes objectForKey:(id)kCTForegroundColorAttributeName];
	
	if (foregroundColor)
	{
		[appendAttributes setObject:foregroundColor forKey:(id)kCTForegroundColorAttributeName];
	}
	
	NSAttributedString *newlineString = [[NSAttributedString alloc] initWithString:@"\n" attributes:appendAttributes];
	[self appendAttributedString:newlineString];
}


#pragma mark - Working with Custom HTML Attributes

- (void)addHTMLAttribute:(NSString *)name value:(id)value range:(NSRange)range replaceExisting:(BOOL)replaceExisting
{
	NSRange safeRange = NSIntersectionRange(range, NSMakeRange(0, [self length]));

	[self beginEditing];
	
	NSMutableIndexSet *indexesToSetThis = [NSMutableIndexSet indexSetWithIndexesInRange:range];
	
	[self enumerateAttribute:DTCustomAttributesAttribute inRange:safeRange options:0 usingBlock:^(NSDictionary *dictionary, NSRange effectiveRange, BOOL *stop) {
		
		id existingValue = [dictionary objectForKey:name];
		
		if (existingValue && !replaceExisting)
		{
			// exempt this range
			[indexesToSetThis removeIndexesInRange:effectiveRange];
		}
	}];
	
	// now our mutable index set should contain the ranges where we want to set this
	
	[indexesToSetThis enumerateRangesInRange:safeRange options:0 usingBlock:^(NSRange indexRange, BOOL *stopEnumerateRanges) {
		
		// for each such range, we need to add this to the attribute
		[self enumerateAttribute:DTCustomAttributesAttribute inRange:indexRange options:0 usingBlock:^(NSDictionary *dictionary, NSRange effectiveRange, BOOL *stopEnumerateAttribute) {
			
			if (dictionary)
			{
				// need to make it mutable and add the value
				NSMutableDictionary *mutableDictionary = [dictionary mutableCopy];
				[mutableDictionary setObject:value forKey:name];
				
				// substitute attribute
#if DTCORETEXT_NEEDS_ATTRIBUTE_REPLACEMENT_LEAK_FIX
				if (NSFoundationVersionNumber <=  NSFoundationVersionNumber10_6_8)  // less than OS X 10.7 and less than iOS 5
				{
					// remove old (works around iOS 4.3 leak)
					[self removeAttribute:DTCustomAttributesAttribute range:effectiveRange];
				}
#endif

				[self addAttribute:DTCustomAttributesAttribute value:[mutableDictionary copy] range:effectiveRange];
			}
			else
			{
				// create new dictionary with the value
				dictionary = [NSDictionary dictionaryWithObject:value forKey:name];
				[self addAttribute:DTCustomAttributesAttribute value:dictionary range:effectiveRange];
			}
		}];
	}];
	
	[self endEditing];
}

- (void)removeHTMLAttribute:(NSString *)name range:(NSRange)range
{
	NSRange safeRange = NSIntersectionRange(range, NSMakeRange(0, [self length]));
	
	[self beginEditing];
	
	[self enumerateAttribute:DTCustomAttributesAttribute inRange:safeRange options:0 usingBlock:^(NSDictionary *dictionary, NSRange effectiveRange, BOOL *stop) {
		
		id existingValue = [dictionary objectForKey:name];
		
		if (existingValue)
		{
			// need to make it mutable and remove the value
			NSMutableDictionary *mutableDictionary = [dictionary mutableCopy];
			[mutableDictionary removeObjectForKey:name];
			
			// substitute attribute
			
			// only re-add modified dictionary if it is not empty
			if ([mutableDictionary count])
			{
				if (NSFoundationVersionNumber <=  NSFoundationVersionNumber10_6_8)  // less than OS X 10.7 and less than iOS 5
				{
					// remove old (works around iOS 4.3 leak)
					[self removeAttribute:DTCustomAttributesAttribute range:effectiveRange];
				}
				
				[self addAttribute:DTCustomAttributesAttribute value:[mutableDictionary copy] range:effectiveRange];
			}
			else
			{
				[self removeAttribute:DTCustomAttributesAttribute range:effectiveRange];
			}
		}
	}];
	
	[self endEditing];
}

@end
