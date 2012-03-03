//
//  NSMutableAttributedString+HTML.h
//  CoreTextExtensions
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
 @param string The string to be appended to this string. */
- (void)appendString:(NSString *)string;

/** 
 Appends a string with a given paragraph style and font to this string. 
 @param string The string to be appended to this string.
 @param paragraphStyle Paragraph style to be attributed to the appended string. 
 @param fontDescriptor Font descriptor to be attributed to the appended string. */
- (void)appendString:(NSString *)string withParagraphStyle:(DTCoreTextParagraphStyle *)paragraphStyle fontDescriptor:(DTCoreTextFontDescriptor *)fontDescriptor;

/** 
 Appends a string without any attributes. 
 @param string The string to be appended to this string without any attributes. 
 */
- (void)appendNakedString:(NSString *)string;

@end
