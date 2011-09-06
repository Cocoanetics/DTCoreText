//
//  DTWebArchive+HTML.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 9/6/11.
//  Copyright (c) 2011 Drobnik.com. All rights reserved.
//

#import "DTWebArchive+HTML.h"
#import "DTWebArchive.h"

#import "NSAttributedString+HTML.h"

@implementation DTWebArchive (HTML)

- (NSAttributedString *)attributedString
{
	// only proceed if this is indeed HTML
	if (![_mainResource.mimeType isEqualToString:@"text/html"])
	{
		return nil;
	}

	// build the options
	NSMutableDictionary *options = [NSMutableDictionary dictionary];
	
	if (_mainResource.url)
	{
		[options setObject:_mainResource.textEncodingName forKey:NSBaseURLDocumentOption];
	}
	
	if (_mainResource.textEncodingName)
	{
		[options setObject:_mainResource.textEncodingName forKey:NSTextEncodingNameDocumentOption];
	}

	// make attributed string
	NSMutableAttributedString *tmpStr = [[NSMutableAttributedString alloc] initWithHTML:_mainResource.data options:options documentAttributes:NULL];
	
	return [tmpStr autorelease];
}

@end
