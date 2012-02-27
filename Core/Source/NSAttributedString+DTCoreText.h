//
//  NSAttributedString+DTCoreText.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 2/1/12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

@class DTCSSListStyle;

@interface NSAttributedString (DTCoreText)

// convenience methods
+ (NSAttributedString *)attributedStringWithHTML:(NSData *)data options:(NSDictionary *)options;

// attachment handling
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




// encoding back to HTML
- (NSString *)htmlString;
- (NSString *)plainTextString;

@end
