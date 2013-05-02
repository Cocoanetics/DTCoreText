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

@implementation NSDictionary (DTRichText)

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
	return [[self objectForKey:(id)kCTUnderlineStyleAttributeName] integerValue]!=kCTUnderlineStyleNone;
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
	
	// try NSParagraphStyle
	
	if (![NSParagraphStyle class])
	{
		// unknown class
		return nil;
	}
	
	NSParagraphStyle *nsParagraphStyle = [self objectForKey:NSParagraphStyleAttributeName];
	return [DTCoreTextParagraphStyle paragraphStyleWithNSParagraphStyle:nsParagraphStyle];
}

- (DTCoreTextFontDescriptor *)fontDescriptor
{
	CTFontRef ctFont = (__bridge CTFontRef)[self objectForKey:(id)kCTFontAttributeName];
	
	if (ctFont)
	{
		return [DTCoreTextFontDescriptor fontDescriptorForCTFont:ctFont];
	}
	
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
	
	return nil;
}

@end
