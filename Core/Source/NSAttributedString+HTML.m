//
//  NSAttributedString+HTML.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <CoreText/CoreText.h>

#import "DTCoreTextConstants.h"

#import "NSAttributedString+HTML.h"
#import "NSMutableAttributedString+HTML.h"

#import "NSString+HTML.h"
#import "DTColor+HTML.h"
#import "NSScanner+HTML.h"
#import "NSCharacterSet+HTML.h"
#import "NSAttributedStringRunDelegates.h"
#import "DTTextAttachment.h"

#import "DTHTMLElement.h"
#import "DTCSSListStyle.h"
#import "DTCSSStylesheet.h"

#import "DTCoreTextFontDescriptor.h"
#import "DTCoreTextParagraphStyle.h"

#import "CGUtils.h"
#import "NSString+UTF8Cleaner.h"
#import "DTCoreTextConstants.h"
#import "DTHTMLAttributedStringBuilder.h"



@implementation NSAttributedString (HTML)

- (id)initWithHTML:(NSData *)data documentAttributes:(NSDictionary **)dict
{
	return [self initWithHTML:data options:nil documentAttributes:dict];
}

- (id)initWithHTML:(NSData *)data baseURL:(NSURL *)base documentAttributes:(NSDictionary **)dict
{
	NSDictionary *optionsDict = nil;
	
	if (base)
	{
		optionsDict = [NSDictionary dictionaryWithObject:base forKey:NSBaseURLDocumentOption];
	}
	
	return [self initWithHTML:data options:optionsDict documentAttributes:dict];
}

- (id)initWithHTML:(NSData *)data options:(NSDictionary *)options documentAttributes:(NSDictionary **)dict
{
	// only with valid data
	if (![data length])
	{
		
		return nil;
	}
	
	DTHTMLAttributedStringBuilder	*stringBuilder = [[DTHTMLAttributedStringBuilder alloc] initWithHTML:data options:options documentAttributes:dict];

	// example for setting a willFlushCallback, that gets called before elements are written to the generated attributed string
	
	[stringBuilder setWillFlushCallback:^(DTHTMLElement *element) 
	{
		// if an element is larger than twice the font size put it in it's own block
		if (element.displayStyle == DTHTMLElementDisplayStyleInline && element.textAttachment.displaySize.height > 2.0 * element.fontDescriptor.pointSize)
		{
			element.displayStyle = DTHTMLElementDisplayStyleBlock;
		}
	} ];
	
	[stringBuilder buildString];
	
	// This needs to be on a seprate line so that ARC can handle releasing the object properly
	// return [stringBuilder generatedAttributedString]; shows leak in instruments
	id string = [stringBuilder generatedAttributedString];
	
	return string;
}

@end
