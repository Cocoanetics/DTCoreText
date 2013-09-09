//
//  DTColorFunctions.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 9/9/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

@class DTColor;

/**
 Takes a CSS color string ('333', 'F9FFF9'), determines the RGB values used, and returns a UIColor object of that color.
 For each part of the RGB color those numbers for that color are converted to a number using a category on NSString. Then that number is divided by the maximum value, 15 for 3 character strings and 255 for 6 character strings, making the color a percentage and within the range 0.0 and 1.0 that UIColor uses.
 @param hexString A CSS hexadecimal color string of length 6 or 3.
 @returns A UIColor object generated from the hexadecimal color string with alpha 1.0.
 */
DTColor *DTColorCreateWithHexString(NSString *hexString);


/**
 Takes an English string representing a color and maps it to a numeric RGB value as declared by the HTML and CSS specifications (see http://www.w3schools.com/html/html_colornames.asp). Also accepts CSS `#` hexadecimal colors, `rgba`, and `rgb` and does the right thing returning a corresponding UIColor.
 If a color begins with a `#` we know that it is a hexadecimal color and send it to colorWithHexString:. If the string is an `rgba()` color declaration the comma delimited r, g, b, and a values are made into percentages and then made into a UIColor which is returned. If the string is an `rgb()` color declaration the same process happens except with an alpha of 1.0.
 The last case is that the color string is not a numeric declaration `#`, nor a `rgba` or `rgb` declaration so the CSS color value matching the English string is found in a lookup dictionary and then passed to colorWithHexString: which will make a UIColor out of the hexadecimal string.
 @param name The CSS color string that we want to map from a name into an RGB color.
 @returns A UIColor object representing the name parameter as numeric values declared by the HTML and CSS specifications, a `rgba()` color, or a `rgb()` color.
 */
DTColor *DTColorCreateWithHTMLName(NSString *name);


/**
 Return a string hexadecimal representation of this UIColor. Splits the color into components with CGColor methods, re-maps them from percentages to the range 0-255, and depending on the number of components returns a grayscale (repeating string of two characters) or color RGB (alpha is stripped) six character string. In the event of a non-2 or non-4 component color nil is returned as it is from an unsupported color space.
 @returns A CSS hexadecimal NSString specifying this UIColor.
 */
NSString *DTHexStringFromDTColor(DTColor *color);
