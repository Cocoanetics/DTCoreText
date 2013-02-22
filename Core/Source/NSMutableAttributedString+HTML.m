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
	NSUInteger selfLengthBefore = [self length];
	
	[self.mutableString appendString:string];
	
	NSRange appendedStringRange = NSMakeRange(selfLengthBefore, [string length]);
	
	// we need to remove the image placeholder (if any) to prevent duplication
	[self removeAttribute:NSAttachmentAttributeName range:appendedStringRange];
	[self removeAttribute:(id)kCTRunDelegateAttributeName range:appendedStringRange];
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
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_5_1
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
			
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_5_1
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

// appends a string without any attributes
- (void)appendNakedString:(NSString *)string
{
	[self appendString:string withParagraphStyle:nil fontDescriptor:nil];
}

@end
