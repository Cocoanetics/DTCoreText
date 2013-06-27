//
//  NSMutableAttributedString+HTML.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 4/14/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCoreTextConstants.h"

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
 @name Working with Custom HTML Attributes
 */

/**
 Adds the custom HTML attributes with the given value on the given range, optionally replacing occurences of an attribute with the same name.
 @param name The name of the custom HTML attribute
 @param value The value to set for the custom attribute
 @param replaceExisting `YES` if ranges that have an attribute with the same name should be replaced. With `NO` the attribute is only added for ranges where there is no attribute with the given name
 */
- (void)addHTMLAttribute:(NSString *)name value:(id)value range:(NSRange)range replaceExisting:(BOOL)replaceExisting;

/**
 Adds the custom HTML attributes with the given value from the given range.
 @param name The name of the custom HTML attribute
 */
- (void)removeHTMLAttribute:(NSString *)name range:(NSRange)range;

/**
 Retrieves the dictionary of custom HTML attributes active at the given string index
 @param index The string index to query
 @returns The custom HTML attributes dictionary or `nil` if there aren't any at this index
 */
- (NSDictionary *)HTMLAttributesAtIndex:(NSUInteger)index;

/**
 Retrieves the range that an attribute with a given name is active for, beginning with the passed index

 Since a custom HTML attribute can occur in multiple individual attribute dictionaries this extends the range from the passed index outwards until the full range of the custom HTML attribute has been found. Those range extentions have to have an identical value, as established by comparing them to the value of the custom attribute at the index with isEqual: 
 @param index The string index to query
 @returns The custom HTML attributes dictionary or `nil` if there aren't any at this index
 */
- (NSRange)rangeOfHTMLAttribute:(NSString *)name atIndex:(NSUInteger)index;

@end
