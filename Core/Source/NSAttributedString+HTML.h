//
//  NSAttributedString+HTML.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

@class NSAttributedString;

/**
 Methods for generating an `NSAttributedString` from HTML data. Those methods exist on Mac but have not been ported (publicly) to iOS. This project aims to remedy this.
 
 For a list of available options to pass to any of these methods please refer to [DTHTMLAttributedStringBuilder initWithHTML:options:documentAttributes:].
 */

@interface NSAttributedString (HTML)

/**
 @name Creating an NSAttributedString
 */

/**
 Initializes and returns a new `NSAttributedString` object from the HTML contained in the given object and base URL.
 @param data The data in HTML format from which to create the attributed string.
 @param docAttributes Currently not in used.
 @returns Returns an initialized object, or `nil` if the data can’t be decoded.
 @see [DTHTMLAttributedStringBuilder initWithHTML:options:documentAttributes:] for a list of available options
 */
- (id)initWithHTMLData:(NSData *)data documentAttributes:(NSDictionary * __autoreleasing*)docAttributes;

/**
 Initializes and returns a new `NSAttributedString` object from the HTML contained in the given object and base URL.
 @param data The data in HTML format from which to create the attributed string.
 @param baseURL An `NSURL` that represents the base URL for all links within the HTML.
 @param docAttributes Currently not in used.
 @returns Returns an initialized object, or `nil` if the data can’t be decoded.
 @see [DTHTMLAttributedStringBuilder initWithHTML:options:documentAttributes:] for a list of available options
 */
- (id)initWithHTMLData:(NSData *)data baseURL:(NSURL *)baseURL documentAttributes:(NSDictionary * __autoreleasing*)docAttributes;

/**
 Initializes and returns a new `NSAttributedString` object from the HTML contained in the given object and base URL. 
 
 @param data The data in HTML format from which to create the attributed string.
 @param options Specifies how the document should be loaded.
 @param docAttributes Currently not in used.
 @returns Returns an initialized object, or `nil` if the data can’t be decoded.
  @see [DTHTMLAttributedStringBuilder initWithHTML:options:documentAttributes:] for a list of available options
 */
- (id)initWithHTMLData:(NSData *)data options:(NSDictionary *)options documentAttributes:(NSDictionary * __autoreleasing*)docAttributes;


/**
 @name Working with Custom HTML Attributes
 */

/**
 Retrieves the dictionary of custom HTML attributes active at the given string index
 @param index The string index to query
 @returns The custom HTML attributes dictionary or `nil` if there aren't any at this index
 */
- (NSDictionary *)HTMLAttributesAtIndex:(NSUInteger)index;

/**
 Retrieves the range that an attribute with a given name is active for, beginning with the passed index
 
 Since a custom HTML attribute can occur in multiple individual attribute dictionaries this extends the range from the passed index outwards until the full range of the custom HTML attribute has been found. Those range extentions have to have an identical value, as established by comparing them to the value of the custom attribute at the index with isEqual:
 @param name The name of the custom attribute to remove
 @param index The string index to query
 @returns The custom HTML attributes dictionary or `nil` if there aren't any at this index
 */
- (NSRange)rangeOfHTMLAttribute:(NSString *)name atIndex:(NSUInteger)index;

@end
