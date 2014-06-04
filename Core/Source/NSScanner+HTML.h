//
//  NSScanner+HTML.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/12/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

@class DTColor;

/**
 Extensions for NSScanner to deal with HTML-specific parsing, primarily CSS-related things
 */
@interface NSScanner (HTML)

/**
 @name Working with CSS
 */

/**
 Scans for a CSS attribute used in CSS style sheets
 @param name An optional output parameter that will contain the name of the scanned attribute if successful
 @param value An optional output parameter that will contain the value of the scanned attribute if successful. This value may be a string or an array.
 @returns `YES` if an URL String could be scanned
 */
- (BOOL)scanCSSAttribute:(NSString * __autoreleasing*)name value:(id __autoreleasing*)value;


/**
 Scans for URLs used in CSS style sheets
 @param urlString An optional output parameter that will contain the scanned URL string if successful
 @returns `YES` if an URL String could be scanned
 */
- (BOOL)scanCSSURL:(NSString * __autoreleasing*)urlString;


/**
 Scans for a typical HTML color, typically either #FFFFFF, rgb(255,255,255) or a HTML color name.
 @param color An optional output parameter that will contain the scanned color if successful
 @returns `YES` if a color could be scanned
 */
- (BOOL)scanHTMLColor:(DTColor * __autoreleasing*)color;

/**
 Scans for a typical HTML color, typically either #FFFFFF, rgb(255,255,255) or a HTML color name.
 @param color An optional output parameter that will contain the scanned color if successful
 @param name An optional output parameter that will contain the HTML color string
 @returns `YES` if a color could be scanned
 */
- (BOOL)scanHTMLColor:(DTColor * __autoreleasing*)color HTMLName:(NSString * __autoreleasing*)name;

@end

