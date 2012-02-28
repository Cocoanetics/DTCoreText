//
//  NSAttributedString+DTCoreText.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 2/1/12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

@class DTCSSListStyle;

/**
 Convenience Methods that mimick similar methods available on Mac
 */
@interface NSAttributedString (DTCoreText)

/**
 @name Working with Text Attachments
 */


/**
 Retrieves the DTTextAttachment objects that match the given predicate.
 
 With this method you can for example find all images that have a certain URL.
 
 @param predicate The predicate to apply for filtering or `nil` for all attachments.
 @returns The filtered array of attachments
 */
- (NSArray *)textAttachmentsWithPredicate:(NSPredicate *)predicate;


/**
 @name Calculating Ranges
 */


/**
 Returns the index of the item at the given location within the list.
 
 @param list The text list.
 @param location The location of the item.
 @returns Returns the index within the list.
*/
- (NSInteger)itemNumberInTextList:(DTCSSListStyle *)list atIndex:(NSUInteger)location;


/**
 Returns the range of the given text list that contains the given location.
 
 @param list The text list.
 @param location The location in the text.
 @returns The range of the given text list containing the location.
 */
- (NSRange)rangeOfTextList:(DTCSSListStyle *)list atIndex:(NSUInteger)location;


/**
 @name Converting to Other Representations
 */


/**
 Encodes the receiver into a generic HTML prepresentation.
 
 @returns An HTML string.
 */
- (NSString *)htmlString;


/*
 Converts the receiver into plain text.
 
 This is different from the `string` method of `NSAttributedString` by also erasing placeholders for text attachments.

 @returns The receiver converted to plain text.
 */
- (NSString *)plainTextString;

@end
