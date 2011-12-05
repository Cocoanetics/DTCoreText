//
//  NSMutableAttributedString+HTML.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 4/14/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//



@class DTCoreTextParagraphStyle;

@interface NSMutableAttributedString (HTML)

// appends a string with the same attributes as the suffix
- (void)appendString:(NSString *)string;

// appends a string with a different paragraph style
- (void)appendString:(NSString *)string withParagraphStyle:(DTCoreTextParagraphStyle *)paragraphStyle;

// appends a string without any attributes
- (void)appendNakedString:(NSString *)string;

@end
