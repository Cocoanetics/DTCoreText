//
//  NSAttributedString+HTML.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

@class NSAttributedString;

extern NSString *NSBaseURLDocumentOption;
extern NSString *NSTextEncodingNameDocumentOption;
extern NSString *NSTextSizeMultiplierDocumentOption;

extern NSString *DTMaxImageSize;
extern NSString *DTDefaultFontFamily;
extern NSString *DTDefaultTextColor;
extern NSString *DTDefaultLinkColor;
extern NSString *DTDefaultLinkDecoration;
extern NSString *DTDefaultTextAlignment;
extern NSString *DTDefaultLineHeightMultiplier;
extern NSString *DTDefaultLineHeightMultiplier;
extern NSString *DTDefaultFirstLineHeadIndent;
extern NSString *DTDefaultHeadIndent;
extern NSString *DTDefaultListIndent;

extern NSString *DTDefaultStyleSheet;

@interface NSAttributedString (HTML)

- (id)initWithHTML:(NSData *)data documentAttributes:(NSDictionary **)dict;
- (id)initWithHTML:(NSData *)data baseURL:(NSURL *)base documentAttributes:(NSDictionary **)dict;
- (id)initWithHTML:(NSData *)data options:(NSDictionary *)options documentAttributes:(NSDictionary **)dict;

// convenience methods
+ (NSAttributedString *)attributedStringWithHTML:(NSData *)data options:(NSDictionary *)options;

// utilities
+ (NSAttributedString *)synthesizedSmallCapsAttributedStringWithText:(NSString *)text attributes:(NSDictionary *)attributes;

// attachment handling
- (NSArray *)textAttachmentsWithPredicate:(NSPredicate *)predicate;

// encoding back to HTML
- (NSString *)htmlString;
- (NSString *)plainTextString;

@end
