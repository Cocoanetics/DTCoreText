//
//  NSMutableAttributedString+HTML.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 4/14/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//



@class DTCoreTextParagraphStyle, DTCoreTextFontDescriptor;

/**
 Methods for appending `NSString` instances to mutable attributed strings
 */
@interface NSMutableAttributedString (HTML)

/** 
 Appends a string with the same attributes as this string to this string. 
 
 If the last character of the receiver contains a placeholder for a <DTTextAttachment> it is removed from the appended string. Also fields (e.g. list prefixes) are not extended
 @param string The string to be appended to this string. */
- (void)appendString:(NSString *)string;

/** 
 Appends a string with a given paragraph style and font to this string. 
 @param string The string to be appended to this string.
 @param paragraphStyle Paragraph style to be attributed to the appended string.
 @param fontDescriptor Font descriptor to be attributed to the appended string. */
- (void)appendString:(NSString *)string withParagraphStyle:(DTCoreTextParagraphStyle *)paragraphStyle fontDescriptor:(DTCoreTextFontDescriptor *)fontDescriptor;

/**
 Adds an HTML attribute with the given name and value to the characters in the specified range. The attribute is written DTHTMLWriter when writing HTML.
 @param A string specifying the HTML attribute name. For example "target" or "title."
 @param The attribute value associated with name.
 @param The range of characters to which the specified attribute/value pair applies. */
- (void)addHTMLAttribute:(NSString *)name value:(id)value range:(NSRange)aRange;

@end
