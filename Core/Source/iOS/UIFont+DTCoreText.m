//
//  UIFont+DTCoreText.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 11.12.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "UIFont+DTCoreText.h"

@implementation UIFont (DTCoreText)

+ (UIFont *)fontWithCTFont:(CTFontRef)ctFont
{
	NSString *fontName = (__bridge_transfer NSString *)CTFontCopyName(ctFont, kCTFontPostScriptNameKey);
	CGFloat fontSize = CTFontGetSize(ctFont);
	return [UIFont fontWithName:fontName size:fontSize];
}

@end
