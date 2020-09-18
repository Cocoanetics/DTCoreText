//
//  UIFont+DTCoreText.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 11.12.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTCompatibility.h"

#if TARGET_OS_IPHONE

#import <CoreText/CoreText.h>

/**
 Methods to translate from `CTFont` to `UIFont`
 */

@interface UIFont (DTCoreText)

/**
 Creates a UIFont that matches the provided CTFont.
 @param ctFont a `CTFontRef`
 @returns The matching UIFont
 */
+ (UIFont *)fontWithCTFont:(CTFontRef)ctFont;

@end

#endif
