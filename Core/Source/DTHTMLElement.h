//
//  DTHTMLElement.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 4/14/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//



@class DTCoreTextParagraphStyle;
@class DTCoreTextFontDescriptor;
@class DTTextAttachment;
@class DTCSSListStyle;

#import <CoreText/CoreText.h>


typedef enum
{
	DTHTMLElementFloatStyleNone = 0,
	DTHTMLElementFloatStyleLeft,
	DTHTMLElementFloatStyleRight
} DTHTMLElementFloatStyle;


typedef enum
{
	DTHTMLElementFontVariantInherit = 0,
	DTHTMLElementFontVariantNormal,
	DTHTMLElementFontVariantSmallCaps
} DTHTMLElementFontVariant;

@interface DTHTMLElement : NSObject <NSCopying>

@property (nonatomic, assign) DTHTMLElement *parent;	// subtle simulator bug - use assign not __unsafe_unretained
@property (nonatomic, copy) DTCoreTextFontDescriptor *fontDescriptor;
@property (nonatomic, copy) DTCoreTextParagraphStyle *paragraphStyle;
@property (nonatomic, strong) DTTextAttachment *textAttachment;
@property (nonatomic, copy) NSURL *link;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, copy) NSString *tagName;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSArray *shadows;
@property (nonatomic, assign) CTUnderlineStyle underlineStyle;
@property (nonatomic, assign) BOOL tagContentInvisible;
@property (nonatomic, assign) BOOL strikeOut;
@property (nonatomic, assign) NSInteger superscriptStyle;
@property (nonatomic, assign) NSInteger headerLevel;
@property (nonatomic, readonly) BOOL isInline;
@property (nonatomic, readonly) BOOL isMeta;
@property (nonatomic, readonly) DTHTMLElementFloatStyle floatStyle;
@property (nonatomic, assign) BOOL isColorInherited;
@property (nonatomic, assign) BOOL preserveNewlines;
@property (nonatomic, assign) DTHTMLElementFontVariant fontVariant;
@property (nonatomic, copy) DTCSSListStyle *listStyle;
@property (nonatomic, assign) CGFloat textScale;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, readonly) NSInteger listDepth;
@property (nonatomic) NSInteger listCounter;
@property (nonatomic, strong) NSDictionary *attributes;


- (NSAttributedString *)attributedString;
- (NSAttributedString *)prefixForListItem;
- (NSDictionary *)attributesDictionary;

- (void)parseStyleString:(NSString *)styleString;
- (void)applyStyleDictionary:(NSDictionary *)styles;

- (void)addAdditionalAttribute:(id)attribute forKey:(id)key;

- (NSString *)path;

- (NSString *)attributeForKey:(NSString *)key;

- (void)addChild:(DTHTMLElement *)child;
- (void)removeChild:(DTHTMLElement *)child;

- (DTHTMLElement *)parentWithTagName:(NSString *)name;
- (BOOL)isContainedInBlockElement;

@end
