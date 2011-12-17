//
//  NSString+Paragraphs.h
//  DTRichTextEditor
//
//  Created by Oliver Drobnik on 11/11/11.
//  Copyright (c) 2011 Cocoanetics. All rights reserved.
//



@interface NSString (Paragraphs)

- (NSRange)rangeOfParagraphsContainingRange:(NSRange)range parBegIndex:(NSUInteger *)parBegIndex parEndIndex:(NSUInteger *)parEndIndex;
- (BOOL)indexIsAtBeginningOfParagraph:(NSUInteger)index;

@end
