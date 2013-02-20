//
//  DTColor+HTML.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#if TARGET_OS_IPHONE

/**
 Methods used to work with HTML representations of colors.
 */
@interface UIColor (HTML)

/** 
 Takes a CSS color string ('333', 'F9FFF9'), determines the RGB values used, and returns a UIColor object of that color. 
 For each part of the RGB color those numbers for that color are converted to a number using a category on NSString. Then that number is divided by the maximum value, 15 for 3 character strings and 255 for 6 character strings, making the color a percentage and within the range 0.0 and 1.0 that UIColor uses. 
 @param hex A CSS hexadecimal color string of length 6 or 3. 
 @returns A UIColor object generated from the hexadecimal color string with alpha 1.0. 
 */
+ (UIColor *)colorWithHexString:(NSString *)hex;

/** 
 Takes an English string representing a color and maps it to a numeric RGB value as declared by the HTML and CSS specifications (see http://www.w3schools.com/html/html_colornames.asp). Also accepts CSS `#` hexadecimal colors, `rgba`, and `rgb` and does the right thing returning a corresponding UIColor.
 If a color begins with a `#` we know that it is a hexadecimal color and send it to colorWithHexString:. If the string is an `rgba()` color declaration the comma delimited r, g, b, and a values are made into percentages and then made into a UIColor which is returned. If the string is an `rgb()` color declaration the same process happens except with an alpha of 1.0. 
 The last case is that the color string is not a numeric declaration `#`, nor a `rgba` or `rgb` declaration so the CSS color value matching the English string is found in a lookup dictionary and then passed to colorWithHexString: which will make a UIColor out of the hexadecimal string.
 @param name The CSS color string that we want to map from a name into an RGB color. 
 @returns A UIColor object representing the name parameter as numeric values declared by the HTML and CSS specifications, a `rgba()` color, or a `rgb()` color.
 */
+ (UIColor *)colorWithHTMLName:(NSString *)name;

/** 
 Return a string hexadecimal representation of this UIColor. Splits the color into components with CGColor methods, re-maps them from percentages to the range 0-255, and depending on the number of components returns a grayscale (repeating string of two characters) or color RGB (alpha is stripped) six character string. In the event of a non-2 or non-4 component color nil is returned as it is from an unsupported color space.
 @returns A CSS hexadecimal NSString specifying this UIColor. 
 */
- (NSString *)htmlHexString;


/** 
 A quick method to return the alpha component of this UIColor by using the CGColorGetAlpha method.
 @returns The floating point alpha value of this UIColor. 
 */
- (CGFloat)alphaComponent;

@end

#else

/**
 Methods used to work with HTML representations of colors.
 */
@interface NSColor (HTML)


/** 
 Takes a CSS color string ('333', 'F9FFF9'), determines the RGB values used, and returns an NSColor object of that color. 
 For each part of the RGB color those numbers for that color are converted to a number using a category on NSString. Then that number is divided by the maximum value, 15 for 3 character strings and 255 for 6 character strings, making the color a percentage and within the range 0.0 and 1.0 that NSColor uses. 
 @param hex A CSS hexadecimal color string of length 6 or 3. 
 @returns An NSColor object generated from the hexadecimal color string with alpha 1.0. 
 */
+ (NSColor *)colorWithHexString:(NSString *)hex;


/** 
 Takes an English string representing a color and maps it to a numeric RGB value as declared by the HTML and CSS specifications (see http://www.w3schools.com/html/html_colornames.asp). Also accepts CSS `#` hexadecimal colors, `rgba`, and `rgb` and does the right thing returning a corresponding NSColor.
 If a color begins with a `#` we know that it is a hexadecimal color and send it to colorWithHexString:. If the string is an `rgba()` color declaration the comma delimited r, g, b, and a values are made into percentages and then made into an NSColor which is returned. If the string is an `rgb()` color declaration the same process happens except with an alpha of 1.0. 
 The last case is that the color string is not a numeric declaration `#`, nor a `rgba` or `rgb` declaration so the CSS color value matching the English string is found in a lookup dictionary and then passed to colorWithHexString: which will make an NSColor out of the hexadecimal string.
 @param name The CSS color string that we want to map from a name into an RGB color. 
 @returns An NSColor object representing the name parameter as numeric values declared by the HTML and CSS specifications, a `rgba()` color, or a `rgb()` color. 
 */
+ (NSColor *)colorWithHTMLName:(NSString *)name;


/** 
 Return a string hexadecimal representation of this NSColor. Splits the color into components with CGColor methods, re-maps them from percentages in the range 0-255, and returns the RGB color (alpha is stripped) in a six character string.
 @returns A CSS hexadecimal NSString specifying this NSColor. 
 */
- (NSString *)htmlHexString;

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_7
/**
 Converts a CGColorRef into an NSColor by placing each component into an NSColor and pending on the component count to return a grayscale or rgb color. If there are not 2 (grayscale) or 4 (rgba) components the color is from an unsupported color space and nil is returned.
 @param cgColor The CGColorRef to convert
 @returns An NSColor of this CGColorRef 
 */
+ (NSColor *)colorWithCGColor:(CGColorRef)cgColor;

/** 
 Converts an NSColor into a CGColorRef. 
 @returns A CGColorRef of this NSColor 
*/
- (CGColorRef)CGColor;
#endif

@end

#endif
