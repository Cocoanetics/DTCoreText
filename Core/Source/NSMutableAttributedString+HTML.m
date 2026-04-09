//
//  NSMutableAttributedString+HTML.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 4/14/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "NSMutableAttributedString+HTML.h"

#import "DTCoreTextFontDescriptor.h"
#import "DTCoreTextParagraphStyle.h"
#import "NSDictionary+DTCoreText.h"

#if TARGET_OS_IPHONE
#import "UIFont+DTCoreText.h"
#endif


@implementation NSMutableAttributedString (HTML)

// the same as appendString just to avoid method repeat problem in iOS18 . If everything works well for somethime , the original appendString can be removed
- (void)dt_appendString:(NSString *)string
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
			NSParagraphStyle *style = [paragraphStyle NSParagraphStyle];
			[attributes setObject:style forKey:NSParagraphStyleAttributeName];
		}
		
		if (fontDescriptor)
		{
			CTFontRef newFont = [fontDescriptor newMatchingFont];

			if (newFont)
			{
#if TARGET_OS_IPHONE
				UIFont *uiFont = [UIFont fontWithCTFont:newFont];
				[attributes setObject:uiFont forKey:NSFontAttributeName];
				CFRelease(newFont);
#else
				[attributes setObject:(__bridge id)(newFont) forKey:NSFontAttributeName];
				CFRelease(newFont);
#endif
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
	id foregroundColor = [attributes objectForKey:NSForegroundColorAttributeName];

	if (foregroundColor)
	{
		[appendAttributes setObject:foregroundColor forKey:NSForegroundColorAttributeName];
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
