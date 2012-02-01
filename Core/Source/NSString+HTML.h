//
//  NSString+HTML.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

//#import <Foundation/Foundation.h>


@interface NSString (HTML)

- (NSUInteger)integerValueFromHex;
- (BOOL)isNumeric;
- (float)percentValue;
- (NSString *)stringByNormalizingWhitespace;
- (BOOL)hasPrefixCharacterFromSet:(NSCharacterSet *)characterSet;
- (BOOL)hasSuffixCharacterFromSet:(NSCharacterSet *)characterSet;

- (NSString *)stringByAddingHTMLEntities;
- (NSString *)stringByReplacingHTMLEntities;

// Utility
+ (NSString *)guid;

@end
