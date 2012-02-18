//
//  NSString+CSS.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 31.01.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTCoreText.h"
#import "DTColor+HTML.h"

/** Methods to make dealing with CSS strings easier. Extract shadows from this string, extract CSS styles found in this string, extract the pixel size of a CSS measurement relative to the current text size, and extract the CSS pixel measurement of this string.
 */
@interface NSString (CSS)

/** Examine a string for all CSS styles that are applied to it and return a dictionary of those styles. Implemented using scanCSSAttribute: which is defined in NSScanner+HTML.h. 
 @return A dictionary of strings containing the CSS styles which are applied to this string. */
- (NSDictionary *)dictionaryOfCSSStyles;

/** Takes a textSize and modifies the current string's pixel measurement to be modified by it. Used in DTHTMLElement.
 @param textSize The current size which the CSS size is relative to.
 @return A float that is the size textSize be it %, em or just numbers .*/
- (CGFloat)pixelSizeOfCSSMeasureRelativeToCurrentTextSize:(CGFloat)textSize;

/** Parse CSS shadow styles, consisting of color, blur, and offset, out of this string. The input string must be comma delimited in the format: <length> <length> <length>? <color>? where the third length and the color are not required per CSS shadows. To calculate the sizes of the blur and offset pixelSizeOfCSSMeasureRelativeToCurrentTextSize is used. Used in DTHTMLElement.
 @param textSize In order to determine the shadow offset we need what text size it will be displayed at.
 @param color Used if no shadow attribute color is found. 
 @return An array of dictionaries, each of which is a shadow consisting of color, blur, and offset keys value pairs. */
- (NSArray *)arrayOfCSSShadowsWithCurrentTextSize:(CGFloat)textSize currentColor:(DTColor *)color;

/** If this string ends with 'px' return the float value stored therein. Ex: The following '17.0px;' will return 17.0. I DON'T KNOW WHAT USES THIS METHOD IF ANYTHING AT ALL-grep returned just this class
 @return The float value stored in this string. */
- (CGFloat)CSSpixelSize;

@end
