//
//  NSAttributedString+SmallCaps.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 31.01.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

/**
 Methods that generated an attributed string with Small Caps, even if the used fonts don't support them natively.
 
 This category works equally for Mac and iOS attributed strings.
 */

@interface NSAttributedString (SmallCaps)

/**
 Creates an `NSAttributedString` from the given text and attributes and synthesizes small caps. On iPad there is only one font that has native small caps, for all other fonts the small caps are synthesized by reducing the font size for all lowercase characters.
 
 @param text The string to convert into an attributed string
 @param attributes A dictionary with attributes for the attributed string
 @returns An attributed string with synthesized small caps.
*/
+ (NSAttributedString *)synthesizedSmallCapsAttributedStringWithText:(NSString *)text attributes:(NSDictionary *)attributes;

@end
