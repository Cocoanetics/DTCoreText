//
//  UIFont+DTCoreText.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 11.12.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

@interface UIFont (DTCoreText)

/**
 Creates a UIFont that matches the provided CTFont.
 @param ctFont a `CTFontRef`
 @returns The matching UIFont
 */
+ (UIFont *)fontWithCTFont:(CTFontRef)ctFont;

@end
