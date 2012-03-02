//
//  NSString+HTML.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

//#import <Foundation/Foundation.h>

/** Methods for making HTML strings easier and quicker to handle. */
@interface NSString (HTML)

/** Extract the numbers from this string and return them as an NSUInteger. 
 @return An NSUInteger of the number characters in this string. */
- (NSUInteger)integerValueFromHex;

/** Test whether or not this string is numeric only.
 @return If this string consists only of numeric characters 0-9. */
- (BOOL)isNumeric;

/** Read through this string and store the numbers included, then divide them by 100 giving a percentage.
 @return The numbers contained in this string, as a percentage. */
- (float)percentValue;

/** Return a copy of this string with all whitespace characters replaced by space characters. 
 @return A copy of this string with only space characters for whitespace. */
- (NSString *)stringByNormalizingWhitespace;

/** Determines if the first character of this string is in the parameter characterSet. 
 @param characterSet The character set to compare the first character of this string against.
 @return If the first character of this string is in character set. */
- (BOOL)hasPrefixCharacterFromSet:(NSCharacterSet *)characterSet;

/** Determines if the last character of this string is in the parameter characterSet. 
 @param characterSet The character set to compare the last character of this string against. 
 @return If the last character of this string is in the character set. */
- (BOOL)hasSuffixCharacterFromSet:(NSCharacterSet *)characterSet;

/** Convert a string into a proper HTML string by converting special characters into HTML entities. For example: an ellipsis `…` is represented by the entity `&hellip;` in order to display it correctly across text encodings. 
 @return A string containing HTML that now uses proper HTML entities. */
- (NSString *)stringByAddingHTMLEntities;

/** Convert a string from HTML entities into correct character representations using UTF8 encoding. For example: an ellipsis entity representy by `&hellip;` is converted into `…`. 
 @return A string without HTML entities, instead having the actual characters formerly represented by HTML entities. */
- (NSString *)stringByReplacingHTMLEntities;

/** Create a globally unique identifier to uniquely identify something. Used to create a GUID, store it in a dictionary or other data structure and retrieve it to uniquely identifiy something. In DTLinkButton multiple parts of the same hyperlink synchronize their looks through the GUID.
 @return GUID assigned to this string to easily and uniquely identify it.. */
+ (NSString *)guid;

@end
