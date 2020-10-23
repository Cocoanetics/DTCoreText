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
	return (__bridge UIFont *)(ctFont);
}

@end

#endif
