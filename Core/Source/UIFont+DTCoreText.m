//
//  UIFont+DTCoreText.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 11.12.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "UIFont+DTCoreText.h"

#if TARGET_OS_IPHONE

@implementation UIFont (DTCoreText)

+ (UIFont *)fontWithCTFont:(CTFontRef)ctFont
{
	NSString *fontName = (__bridge_transfer NSString *)CTFontCopyName(ctFont, kCTFontPostScriptNameKey);

	CGFloat fontSize = CTFontGetSize(ctFont);
	UIFont *font = [UIFont fontWithName:fontName size:fontSize];

	// fix for missing HelveticaNeue-Italic font in iOS 7.0.x
	if (!font && [fontName isEqualToString:@"HelveticaNeue-Italic"])
	{
		font = [UIFont fontWithName:@"HelveticaNeue-LightItalic" size:fontSize];
	}

	return font;
}

@end

#endif
