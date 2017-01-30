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

- (NSInteger)headerLevel
{
	NSNumber *headerLevelNum = [self objectForKey:DTHeaderLevelAttribute];
	
	return [headerLevelNum integerValue];
}

- (BOOL)hasAttachment
{
	id attachment = [self objectForKey:NSAttachmentAttributeName];
	
	if (!attachment)
	{
		// could also be modern NS-style attachment
		attachment = [self objectForKey:@"NSAttachment"];
	}
	
	return attachment!=nil;
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
	
	// on Mac NSFont and CTFont are toll-free bridged, so this works there as well
	
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
		
		if (componentCount>0 && componentCount<=4)
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
