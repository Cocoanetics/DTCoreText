//
//  NSString+Paragraphs.h
//  DTRichTextEditor
//
//  Created by Oliver Drobnik on 11/11/11.
//  Copyright (c) 2011 Cocoanetics. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Methods simplifying dealing with text that is in paragraphs.
 
 The character used to separate paragraphs from each other is '\n'.
 */
@interface NSString (Paragraphs)

/**
 Extends the given range such that it contains only full paragraphs. 
 
 @param range The string range
 @param parBegIndex An optional output parameter that is filled with the beginning index of the extended range
 @param parEndIndex An optional output parameter that is filled with the ending index of the extended range
 @returns The extended string range
 */
- (NSRange)rangeOfParagraphsContainingRange:(NSRange)range parBegIndex:(NSUInteger *)parBegIndex parEndIndex:(NSUInteger *)parEndIndex;


/**
 Determines if the given index is the first character of a new paragraph.
 
 This is done by examining the string, index 0 or characters following a newline are considered to be a first character of a new paragraph.
 @param index The index to examine
 @returns `YES` if the given index is the first character of a new paragraph, `NO` otherwise
 */
- (BOOL)indexIsAtBeginningOfParagraph:(NSUInteger)index;

/**
 Returns the string range of the paragraph with the given index.
 
 @param index The paragraph index to inspect
 @returns The string range of the paragraph
 */
- (NSRange)rangeOfParagraphAtIndex:(NSUInteger)index;


/**
 Counts the number of paragraphs in the receiver
 @returns The number of paragraph characters (\n) in the receiver
 */
- (NSUInteger)numberOfParagraphs;

@end
