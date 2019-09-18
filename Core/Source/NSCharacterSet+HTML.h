//
//  NSCharacterSet+HTML.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/15/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

/** 
 Category on NSCharacterSet to create character sets frequently used and relevant to HTML and CSS string manipulations. Each character set is only initialized once. 
 */
@interface NSCharacterSet (HTML)

/**
 @name HTML Character Sets
 */


/** 
 Creates an alpha-numeric character set, appropriate for tag names. 
 @returns An NSCharacterSet with alpha-numeric characters. a-Z, 0-9. 
 */
+ (NSCharacterSet *)tagNameCharacterSet;


/** 
 Creates an alpha-numeric character set just as tagNameCharacterSet does but also with colon, dash, and underscore characters, appropriate for tag attribute names.  
 @returns An NSCharacterSet with alpha-numeric characters and colon :, dash -, and underscore _'. 
 */
+ (NSCharacterSet *)tagAttributeNameCharacterSet;


/**
 Creates a characterset of all whitespace and newline characters that can be ignored between HTML tags
 @returns An NSCharacterSet of ignorable characters
 */
+ (NSCharacterSet *)ignorableWhitespaceCharacterSet;

/** 
 Creates a character set with the apostrophe character ' (used as single quote agnostic of direction) and double quote character " (agnostic of direction).  
 @returns An NSCharacterSet with the single quote and double quote characters: ', ". 
 */
+ (NSCharacterSet *)quoteCharacterSet;


/** 
 Creates a character set with the characters forward slash / and closing angle bracket aka greater than sign >, then forms the union of this character set with the [whitespace character set](https://developer.apple.com/library/ios/#documentation/Cocoa/Reference/Foundation/Classes/NSCharacterSet_Class/Reference/Reference.html) which includes space, tab, newline, and nextline characters. Useful to find the end of an attribute. 
 @returns An NSCharacterSet with the forward slash, closing angle bracket characters, tab, space, newline, and nextline characters. 
 */
+ (NSCharacterSet *)nonQuotedAttributeEndCharacterSet;


/**
 @name CSS Character Sets
 */

/** 
 Creates an alpha-numeric character set just as tagNameCharacterSet does but also with the dash and underscore characters. Does not contain the colon character because it will mess up parsing of CSS style attributes. Useful for CSS attribute names. 
 @returns An NSCharacterSet with alpha-numeric characters, dash, and underscore characters. 
 */
+ (NSCharacterSet *)cssStyleAttributeNameCharacterSet;


/**
 Characterset of characters that make up units in CSS values
 @returns An NSCharacterSet
 */
+ (NSCharacterSet *)cssLengthValueCharacterSet;


/**
 Characterset of characters that make up units in CSS lengths
 @returns An NSCharacterSet
 */
+ (NSCharacterSet *)cssLengthUnitCharacterSet;

/**
Characterset of ASCII Characters
@returns An NSCharacterSet
*/

+ (NSCharacterSet *)ASCIICharacterSet;

@end
