//
//  NSMutableAttributedString+HTML.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 4/14/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DTCoreTextParagraphStyle;

@interface NSMutableAttributedString (HTML)


- (void)appendString:(NSString *)string;

- (void)appendString:(NSString *)string withParagraphStyle:(DTCoreTextParagraphStyle *)paragraphStyle;

- (void)appendNakedString:(NSString *)string;

- (void)compressAttributes;


@end
