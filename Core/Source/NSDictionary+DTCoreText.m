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
	
#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES
	// try NSParagraphStyle to see if "modern tags" are possible
	if (![NSParagraphStyle class])
	{
		// unknown class
		return NO;
	}
	
	underlineStyle = [self objectForKey:NSUnderlineStyleAttributeName];
	
	if (underlineStyle)
	{
		return [underlineStyle integerValue] != NSUnderlineStyleNone;
	}
#endif
	
	return NO;
}

- (BOOL)isStrikethrough
{
	NSNumber *strikethroughStyle = [self objectForKey:DTStrikeOutAttribute];
	
	if (strikethroughStyle)
	{
		return [strikethroughStyle boolValue];
	}

#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES
	// try NSParagraphStyle to see if "modern tags" are possible
	if (![NSParagraphStyle class])
	{
		// unknown class
		return NO;
	}
	
	strikethroughStyle = [self objectForKey:NSStrikethroughStyleAttributeName];
	
	if (strikethroughStyle)
	{
		return [strikethroughStyle boolValue];
	}
#endif
	
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
    CTParagraphStyleRef ctParagraphStyle = (__bridge CTParagraphStyleRef)[self objectForKey:(id)kCTParagraphStyleAttributeName];
	
	if (ctParagraphStyle)
	{
		return [DTCoreTextParagraphStyle paragraphStyleWithCTParagraphStyle:ctParagraphStyle];
	}
	
#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES
	// try NSParagraphStyle
	
	if (![NSParagraphStyle class])
	{
		// unknown class
		return nil;
	}
	
	NSParagraphStyle *nsParagraphStyle = [self objectForKey:NSParagraphStyleAttributeName];
	
	if (nsParagraphStyle)
	{
		return [DTCoreTextParagraphStyle paragraphStyleWithNSParagraphStyle:nsParagraphStyle];
	}
#endif
	
	return nil;
}

- (DTCoreTextFontDescriptor *)fontDescriptor
{
	CTFontRef ctFont = (__bridge CTFontRef)[self objectForKey:(id)kCTFontAttributeName];
	
	if (ctFont)
	{
		return [DTCoreTextFontDescriptor fontDescriptorForCTFont:ctFont];
	}
	
#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES && TARGET_OS_IPHONE
	if (floor(NSFoundationVersionNumber) >= DTNSFoundationVersionNumber_iOS_6_0)
	{
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
	}
#endif
	
	return nil;
}

- (DTColor *)foregroundColor
{
#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES
	// try NSParagraphStyle to see if "modern tags" are possible
	
	if ([NSParagraphStyle class])
	{
		DTColor *color = [self objectForKey:NSForegroundColorAttributeName];
		
		if (color)
		{
			return color;
		}
	}
#endif
	
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
	
#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES
	// try NSParagraphStyle to see if "modern tags" are possible
	
	if (![NSParagraphStyle class])
	{
		// unknown class
		return nil;
	}
	
	DTColor *color = [self objectForKey:NSBackgroundColorAttributeName];
	
	if (color)
	{
		return color;
	}
#endif
	
	// default background is nil
	return nil;
}

- (CGFloat)kerning
{
#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES
	// try NSParagraphStyle to see if "modern tags" are possible
	
	if ([NSParagraphStyle class])
	{
		NSNumber *kerningNum = [self objectForKey:NSKernAttributeName];
		
		return [kerningNum floatValue];
	}
#endif
	
	NSNumber *kerningNum = [self objectForKey:(id)kCTKernAttributeName];
	
	return [kerningNum floatValue];
}

@end
