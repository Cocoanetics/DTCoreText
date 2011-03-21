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
- (BOOL)hasSuffixCharacterFromSet:(NSCharacterSet *)characterSet;
- (NSString *)stringByReplacingHTMLEntities;

// CSS
- (NSDictionary *)dictionaryOfCSSStyles;
- (CGFloat)pixelSizeOfCSSMeasureRelativeToCurrentTextSize:(CGFloat)textSize;
- (NSArray *)arrayOfCSSShadowsWithCurrentTextSize:(CGFloat)textSize currentColor:(UIColor *)color;
- (CGFloat)CSSpixelSize;

// Utility
+ (NSString *)guid;

@end
