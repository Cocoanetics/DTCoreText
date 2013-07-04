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
	
	[indexesToSetThis enumerateRangesInRange:safeRange options:0 usingBlock:^(NSRange indexRange, BOOL *stop) {
		
		// for each such range, we need to add this to the attribute
		[self enumerateAttribute:DTCustomAttributesAttribute inRange:indexRange options:0 usingBlock:^(NSDictionary *dictionary, NSRange effectiveRange, BOOL *stop) {
			
			if (dictionary)
			{
				// need to make it mutable and add the value
				NSMutableDictionary *mutableDictionary = [dictionary mutableCopy];
				[mutableDictionary setObject:value forKey:name];
				
				// substitute attribute
				[self removeAttribute:DTCustomAttributesAttribute range:effectiveRange];
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
			[self removeAttribute:DTCustomAttributesAttribute range:effectiveRange];
			
			// only re-add modified dictionary if it is not empty
			if ([mutableDictionary count])
			{
				[self addAttribute:DTCustomAttributesAttribute value:[mutableDictionary copy] range:effectiveRange];
			}
		}
	}];
	
	[self endEditing];
}

@end
