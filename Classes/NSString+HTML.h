//
//  NSString+HTML.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

@interface NSString (HTML)

- (NSUInteger)integerValueFromHex;
- (BOOL)isInlineTag;
- (NSString *)stringByNormalizingWhitespace;
- (BOOL)hasPrefixCharacterFromSet:(NSCharacterSet *)characterSet;
- (NSString *)stringByReplacingHTMLEntities;

@end
