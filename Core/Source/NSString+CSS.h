//
//  NSString+CSS.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 31.01.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

@class DTColor;

/**
 Methods to make dealing with CSS strings easier. Extract shadows from this string, extract CSS styles found in this string, extract the pixel size of a CSS measurement relative to the current text size, and extract the CSS pixel measurement of this string.
 */
@interface NSString (CSS)

/**
 Examine a string for all CSS styles that are applied to it and return a dictionary of those styles. Implemented using scanCSSAttribute: which is defined in NSScanner+HTML.h.
 @returns A dictionary of strings containing the CSS styles which are applied to this string.
 */
- (NSDictionary *)dictionaryOfCSSStyles;

/**
 Determines if the receiver contains a CSS length value, that is a number with optional period and unit (em, pt, px).
 @returns `YES` if this is a CSS length value
 */
- (BOOL)isCSSLengthValue;

/**
 Calculates a pixel-based length from the receiver based on the current text size in pixels. Used in DTHTMLElement.
 @param textSize The current size which the CSS size is relative to.
 @param textScale The factor by which absolute sizes are scaled. Set to 1.0f to keep the original value.
 @returns A float that is the textSize
 */
- (CGFloat)pixelSizeOfCSSMeasureRelativeToCurrentTextSize:(CGFloat)textSize textScale:(CGFloat)textScale;

/**
 Decodes edge inset values from the CSS attribute string. This is used for margin andpadding which might have varying number of elements.
 @param textSize The current size which the CSS size is relative to.
 @param textScale The factor by which absolute sizes are scaled. Set to 1.0f to keep the original value.
 @returns The edge insets that this describes
 */
- (DTEdgeInsets)DTEdgeInsetsRelativeToCurrentTextSize:(CGFloat)textSize textScale:(CGFloat)textScale;

/**
 Parse CSS shadow styles, consisting of color, blur, and offset, out of this string. The input string must be comma delimited in the format: <length> <length> <length>? <color>? where the third length and the color are not required per CSS shadows. To calculate the sizes of the blur and offset pixelSizeOfCSSMeasureRelativeToCurrentTextSize is used. Used in DTHTMLElement.
 @param textSize In order to determine the shadow offset we need what text size it will be displayed at.
 @param color Used if no shadow attribute color is found.
 @returns An array of dictionaries, each of which is a shadow consisting of color, blur, and offset keys value pairs.
 */
- (NSArray *)arrayOfCSSShadowsWithCurrentTextSize:(CGFloat)textSize currentColor:(DTColor *)color;

/**
 Decodes a content attribute which might contained unicode sequences.
 */
- (NSString *)stringByDecodingCSSContentAttribute;

@end
