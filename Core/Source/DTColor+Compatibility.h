//
//  DTColor+Compatibility.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <AvailabilityMacros.h>

#if TARGET_OS_IPHONE

#import <UIKit/UIColor.h>

/**
 Implementations of methods on NSColor/UIColor which are missing on the other platform.
 */
@interface UIColor (HTML)


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
 Return a string hexadecimal representation of this NSColor. Splits the color into components with CGColor methods, re-maps them from percentages in the range 0-255, and returns the RGB color (alpha is stripped) in a six character string.
 @returns A CSS hexadecimal NSString specifying this NSColor. 
 */
//- (NSString *)htmlHexString;

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
- (CGColorRef)CGColor DT_RETURNS_INNER_POINTER;
#endif

@end

#endif
