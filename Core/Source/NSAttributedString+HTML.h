//
//  NSAttributedString+HTML.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

@class NSAttributedString;

/**
 Methods for generating an `NSAttributedString` from HTML data. Those methods exist on Mac but have not been ported (publicly) to iOS. This project aims to remedy this.
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
 */
- (id)initWithHTMLData:(NSData *)data documentAttributes:(NSDictionary **)docAttributes;

/**
 Initializes and returns a new `NSAttributedString` object from the HTML contained in the given object and base URL.
 @param data The data in HTML format from which to create the attributed string.
 @param baseURL An `NSURL` that represents the base URL for all links within the HTML.
 @param docAttributes Currently not in used.
 @returns Returns an initialized object, or `nil` if the data can’t be decoded.
 */
- (id)initWithHTMLData:(NSData *)data baseURL:(NSURL *)baseURL documentAttributes:(NSDictionary **)docAttributes;

/**
 Initializes and returns a new `NSAttributedString` object from the HTML contained in the given object and base URL.
 @param data The data in HTML format from which to create the attributed string.
 @param options Specifies how the document should be loaded. Contains values described in “Option keys for importing documents.” 
 @param docAttributes Currently not in used.
 @returns Returns an initialized object, or `nil` if the data can’t be decoded.
 */
- (id)initWithHTMLData:(NSData *)data options:(NSDictionary *)options documentAttributes:(NSDictionary **)docAttributes;

@end
