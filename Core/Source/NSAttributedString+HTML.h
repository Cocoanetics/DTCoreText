//
//  NSAttributedString+HTML.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCompatibility.h"

@class NSAttributedString;

/**
 Methods for generating an `NSAttributedString` from HTML data. Those methods exist on Mac but have not been ported (publicly) to iOS. This project aims to remedy this.
 
 For a list of available options to pass to any of these methods please refer to [DTHTMLAttributedStringBuilder initWithHTML:options:documentAttributes:].
 */

@interface NSAttributedString (HTML)

// initWithHTMLData: convenience initializers have moved to Swift (DTCoreTextSwift target).
// Import DTCoreTextSwift to use them.

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
 
 Since a custom HTML attribute can occur in multiple individual attribute dictionaries this extends the range from the passed index outwards until the full range of the custom HTML attribute has been found. Those range extensions have to have an identical value, as established by comparing them to the value of the custom attribute at the index with isEqual:
 @param name The name of the custom attribute to remove
 @param index The string index to query
 @returns The custom HTML attributes dictionary or `nil` if there aren't any at this index
 */
- (NSRange)rangeOfHTMLAttribute:(NSString *)name atIndex:(NSUInteger)index;

/**
 Retrieves the NSAttributedString with NSData
 
 Currently only supports iOS by `___useiOS6Attributes`, if error occur return nil.

 @param data The data must generate by `convertToData` function
 @return NSAttributedString from unarchiveObjectWithData, the data must generate by `convertToData` function
 */
+ (NSAttributedString *)attributedStringWithData:(NSData *)data;

/**
 Retrieves NSData with self
 
 Currently only supports iOS by `___useiOS6Attributes`, if error occur return nil.
 
 @return NSData from NSAttributedString execute archivedDataWithRootObject:
 */
- (NSData *)convertToData;

@end
