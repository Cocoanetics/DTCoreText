//
//  NSDictionary+DTCoreText.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 7/21/11.
//  Copyright 2011 Cocoanetics. All rights reserved.
//


#import <CoreText/CoreText.h>

#import "NSDictionary+DTCoreText.h"
#import "DTCoreTextFontDescriptor.h"
#import "DTCoreTextConstants.h"
#import "DTCoreTextFunctions.h"
#import "DTCoreTextParagraphStyle.h"

@implementation NSDictionary (DTCoreText)

- (BOOL)isBold
{
	DTCoreTextFontDescriptor *desc = [self fontDescriptor];
	
	return desc.boldTrait;
}

- (BOOL)isItalic
{
	DTCoreTextFontDescriptor *desc = [self fontDescriptor];
	
	return desc.italicTrait;
}

- (BOOL)isUnderline
{
	NSNumber *underlineStyle = [self objectForKey:(id)kCTUnderlineStyleAttributeName];
	
	if (underlineStyle)
	{
		return [underlineStyle integerValue] != kCTUnderlineStyleNone;
	}
	
	if (DTCoreTextModernAttributesPossible())
	{
		underlineStyle = [self objectForKey:NSUnderlineStyleAttributeName];
	
		if (underlineStyle)
		{
			return [underlineStyle integerValue] != NSUnderlineStyleNone;
		}
	}
	
	return NO;
}

- (BOOL)isStrikethrough
{
	NSNumber *strikethroughStyle = [self objectForKey:DTStrikeOutAttribute];
	
	if (strikethroughStyle)
	{
		return [strikethroughStyle boolValue];
	}

	if (DTCoreTextModernAttributesPossible())
	{
		strikethroughStyle = [self objectForKey:NSStrikethroughStyleAttributeName];
		
		if (strikethroughStyle)
		{
			return [strikethroughStyle boolValue];
		}
	}
	
	return NO;
}

- (NSUInteger)headerLevel
{
	NSNumber *headerLevelNum = [self objectForKey:DTHeaderLevelAttribute];
	
	return [headerLevelNum integerValue];
}

- (BOOL)hasAttachment
{
	return [self objectForKey:NSAttachmentAttributeName]!=nil;
}

- (DTCoreTextParagraphStyle *)paragraphStyle
{
	if (DTCoreTextModernAttributesPossible())
	{
		NSParagraphStyle *nsParagraphStyle = [self objectForKey:NSParagraphStyleAttributeName];
		
		if (nsParagraphStyle && [nsParagraphStyle isKindOfClass:[NSParagraphStyle class]])
		{
			return [DTCoreTextParagraphStyle paragraphStyleWithNSParagraphStyle:nsParagraphStyle];
		}
	}
	
	CTParagraphStyleRef ctParagraphStyle = (__bridge CTParagraphStyleRef)[self objectForKey:(id)kCTParagraphStyleAttributeName];
	
	if (ctParagraphStyle)
	{
		return [DTCoreTextParagraphStyle paragraphStyleWithCTParagraphStyle:ctParagraphStyle];
	}
	
	return nil;
}

- (DTCoreTextFontDescriptor *)fontDescriptor
{
	CTFontRef ctFont = (__bridge CTFontRef)[self objectForKey:(id)kCTFontAttributeName];
	
	if (ctFont)
	{
		return [DTCoreTextFontDescriptor fontDescriptorForCTFont:ctFont];
	}
	
	if (DTCoreTextModernAttributesPossible())
	{
#if TARGET_OS_IPHONE
		UIFont *uiFont = [self objectForKey:NSFontAttributeName];
		
		if (!uiFont)
		{
			return nil;
		}
		
		// convert font
		ctFont = DTCTFontCreateWithUIFont(uiFont);
		
		if (ctFont)
		{
			DTCoreTextFontDescriptor *fontDescriptor = [DTCoreTextFontDescriptor fontDescriptorForCTFont:ctFont];
			
			CFRelease(ctFont);
			
			return fontDescriptor;
		}
#else
#warning Creating an NSFont in modern style for Mac not implemented yet
#endif
	}
	
	return nil;
}

- (DTColor *)foregroundColor
{
	if (DTCoreTextModernAttributesPossible())
	{
		DTColor *color = [self objectForKey:NSForegroundColorAttributeName];
		
		if (color)
		{
			return color;
		}
	}
	
	CGColorRef cgColor = (__bridge CGColorRef)[self objectForKey:(id)kCTForegroundColorAttributeName];
	
	if (cgColor)
	{
#if DTCORETEXT_FIX_14684188
		// test if this a valid color, workaround for iOS 7 bug
		size_t componentCount = CGColorGetNumberOfComponents(cgColor);
		
		if (componentCount)

		{
			return [DTColor colorWithCGColor:cgColor];
		}
#else
		return [DTColor colorWithCGColor:cgColor];
#endif
	}
	
	// default foreground is black
	return [DTColor blackColor];
}

- (DTColor *)backgroundColor
{
	CGColorRef cgColor = (__bridge CGColorRef)[self objectForKey:DTBackgroundColorAttribute];
	
	if (cgColor)
	{
		return [DTColor colorWithCGColor:cgColor];
	}
	
	if (DTCoreTextModernAttributesPossible())
	{
		DTColor *color = [self objectForKey:NSBackgroundColorAttributeName];
	
		if (color)
		{
			return color;
		}
	}
	
	// default background is nil
	return nil;
}

- (CGFloat)kerning
{
	if (DTCoreTextModernAttributesPossible())
	{
		NSNumber *kerningNum = [self objectForKey:NSKernAttributeName];
		
		if (kerningNum)
		{
			return [kerningNum floatValue];
		}
	}
	
	NSNumber *kerningNum = [self objectForKey:(id)kCTKernAttributeName];
	
	return [kerningNum floatValue];
}

- (DTColor *)backgroundStrokeColor
{
	CGColorRef cgColor = (__bridge CGColorRef)[self objectForKey:DTBackgroundStrokeColorAttribute];
	
	if (cgColor)
	{
		return [DTColor colorWithCGColor:cgColor];
	}
	return nil;
}

- (CGFloat)backgroundStrokeWidth
{
	NSNumber *num = [self objectForKey:DTBackgroundStrokeWidthAttribute];
	
	if (num)
	{
		return [num floatValue];
	}

	return 0.0f;
}

- (CGFloat)backgroundCornerRadius
{
	NSNumber *num = [self objectForKey:DTBackgroundCornerRadiusAttribute];
	
	if (num)
	{
		return [num floatValue];
	}
	
	return 0.0f;
}

@end
