//
//  NSAttributedString+HTML.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <CoreText/CoreText.h>
#elif TARGET_OS_MAC
#import <ApplicationServices/ApplicationServices.h>
#endif

#import "DTCoreText.h"

@implementation NSAttributedString (HTML)

- (id)initWithHTMLData:(NSData *)data documentAttributes:(NSDictionary **)docAttributes
{
	return [self initWithHTMLData:data options:nil documentAttributes:docAttributes];
}

- (id)initWithHTMLData:(NSData *)data baseURL:(NSURL *)base documentAttributes:(NSDictionary **)docAttributes
{
	NSDictionary *optionsDict = nil;
	
	if (base)
	{
		optionsDict = [NSDictionary dictionaryWithObject:base forKey:NSBaseURLDocumentOption];
	}
	
	return [self initWithHTMLData:data options:optionsDict documentAttributes:docAttributes];
}

- (id)initWithHTMLData:(NSData *)data options:(NSDictionary *)options documentAttributes:(NSDictionary **)docAttributes
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
	
	// This needs to be on a seprate line so that ARC can handle releasing the object properly
	// return [stringBuilder generatedAttributedString]; shows leak in instruments
	id string = [stringBuilder generatedAttributedString];
	
	return string;
}

@end
