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
 
 Options can be:
 
 - DTMaxImageSize: the maximum CGSize that a text attachment can fill
 - DTDefaultFontFamily: the default font family to use instead of Times New Roman
 - DTDefaultFontSize: the default font size to use instead of 12
 - DTDefaultTextColor: the default text color
 - DTDefaultLinkColor: the default color for hyperlink text
 - DTDefaultLinkDecoration: the default decoration for hyperlinks
 - DTDefaultTextAlignment: the default text alignment for paragraphs
 - DTDefaultLineHeightMultiplier: The multiplier for line heights
 - DTDefaultFirstLineHeadIndent: The default indent for left margin on first line
 - DTDefaultHeadIndent: The default indent for left margin except first line
 - DTDefaultListIndent: The amount by which lists are indented
 - DTDefaultStyleSheet: The default style sheet to use
 - DTUseiOS6Attributes: use iOS 6 attributes for building (UITextView compatible)
 - DTWillFlushBlockCallBack: a block to be executed whenever content is flushed to the output string

 @param data The data in HTML format from which to create the attributed string.
 @param options Specifies how the document should be loaded.
 @param docAttributes Currently not in used.
 @returns Returns an initialized object, or `nil` if the data can’t be decoded.
 */
- (id)initWithHTMLData:(NSData *)data options:(NSDictionary *)options documentAttributes:(NSDictionary **)docAttributes;

@end
