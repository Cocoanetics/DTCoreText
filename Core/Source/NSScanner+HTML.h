//
//  NSScanner+HTML.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/12/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

@class DTColor;

/** Additions to NSScanner to quickly and conveniently deal with HTML strings. Including methods to scan an HTML DOCTYPE  
 */
@interface NSScanner (HTML)

/** Scan to find an HTML tag. Enclosed in angle brackets <>. Store the attributes inside the tag in attributes pointer parameter, the name of the tag in tagName, whether the tag is still open in isOpen, and immediately closed in isClosed. 
 @param tagName Pointer to an NSString where the tag name will be stored in lowercase as tag names are. If the tag is a comment then @"#COMMENT#" will be stored in tagName.
 @param attributes Pointer to an NSSDictionary where the attributes scanned will be stored in key value pairs of the attribute names and attribute values. 
 @param isOpen Pointer to a BOOL where the tagOpen status will be stored. YES if there is no detected end to the tag, NO if there is a detected end. 
 @param isClosed Pointer to a BOOL where the immediatelyClosed status will be stored. YES if there is detected an immediate end to the tag, NO if there is no detected end to the tag. 
 @returns YES if there were no errors in scanning */
- (BOOL)scanHTMLTag:(NSString **)tagName attributes:(NSDictionary **)attributes isOpen:(BOOL *)isOpen isClosed:(BOOL *)isClosed;

/** Scan to find DOCTYPE in the format <!$DOCTYPE>. 
 @param contents Pointer to an NSString wherein the contents of the DOCTYPE will be stored.
 @returns YES if there were no errors in scanning.
 */
- (BOOL)scanDOCTYPE:(NSString **)contents;

/** Scan to find a CSS attribute in a name/value pair.  
 @param name Pointer to an NSString where the name of the scanned CSS attribute will be stored.
 @param value Pointer to an NSString where the value of the scanned CSS attribute will be stored.
 @returns YES if there were no errors in scanning. */
- (BOOL)scanCSSAttribute:(NSString **)name value:(NSString **)value;

/** Scan to find a URL in the format `url(…)` as used in CSS. The URL is decoded and escaped before being stored in urlString. 
 @param urlString Pointer to an NSString wherein the found URL will be stored. 
 @returns YES if there were no errors in scanning. */
- (BOOL)scanCSSURL:(NSString **)urlString;

/** Scan to find an HTML color string. Find it by scanning for `#` or `rgb` and then passing the text from that range into DTColor's colorWithHTMLName: method. When found store it in the color pointer parameter, return a bool whether or not a color was found. 
 @param color Pointer to a DTColor wherein the found color will be stored.
 @returns YES if there were no errors in scanning. */
- (BOOL)scanHTMLColor:(DTColor **)color;


/** Diagnostic method. Log the substring of this scanner's string from the current scanner location to the end of the string. This is significant and useful for diagnostics because it is the unscanned portion of this scanner's string. 
 */
- (void)logPosition;

@end

