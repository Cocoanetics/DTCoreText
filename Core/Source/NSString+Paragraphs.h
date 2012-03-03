//
//  NSString+Paragraphs.h
//  DTRichTextEditor
//
//  Created by Oliver Drobnik on 11/11/11.
//  Copyright (c) 2011 Cocoanetics. All rights reserved.
//


/**
 Methods simplifying dealing with text that is in paragraphs.
 
 The character used to separate paragraphs from each other is '\n'.
 */
@interface NSString (Paragraphs)


/*
 Extends the given range such that it contains only full paragraphs. 
 */
- (NSRange)rangeOfParagraphsContainingRange:(NSRange)range parBegIndex:(NSUInteger *)parBegIndex parEndIndex:(NSUInteger *)parEndIndex;


- (BOOL)indexIsAtBeginningOfParagraph:(NSUInteger)index;

- (NSRange)rangeOfParagraphAtIndex:(NSUInteger)index;

@end
