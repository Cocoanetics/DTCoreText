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
@class DTColor;

typedef enum
{
	DTHTMLElementDisplayStyleInline = 0, // default
	DTHTMLElementDisplayStyleNone,
	DTHTMLElementDisplayStyleBlock,
	DTHTMLElementDisplayStyleListItem
} DTHTMLElementDisplayStyle;

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

@property (nonatomic, strong) DTHTMLElement *parent;
@property (nonatomic, copy) DTCoreTextFontDescriptor *fontDescriptor;
@property (nonatomic, copy) DTCoreTextParagraphStyle *paragraphStyle;
@property (nonatomic, strong) DTTextAttachment *textAttachment;
@property (nonatomic, copy) NSURL *link;
@property (nonatomic, strong) DTColor *textColor;
@property (nonatomic, strong) DTColor *backgroundColor;
@property (nonatomic, copy) NSString *tagName;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSArray *shadows;
@property (nonatomic, assign) CTUnderlineStyle underlineStyle;
@property (nonatomic, assign) BOOL tagContentInvisible;
@property (nonatomic, assign) BOOL strikeOut;
@property (nonatomic, assign) NSInteger superscriptStyle;
@property (nonatomic, assign) NSInteger headerLevel;
@property (nonatomic, assign) DTHTMLElementDisplayStyle displayStyle;
@property (nonatomic, readonly) DTHTMLElementFloatStyle floatStyle;
@property (nonatomic, assign) BOOL isColorInherited;
@property (nonatomic, assign) BOOL preserveNewlines;
@property (nonatomic, assign) DTHTMLElementFontVariant fontVariant;
@property (nonatomic, assign) CGFloat textScale;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, strong) NSDictionary *attributes;

- (NSAttributedString *)attributedString;
- (NSDictionary *)attributesDictionary;

- (void)parseStyleString:(NSString *)styleString;
- (void)applyStyleDictionary:(NSDictionary *)styles;
- (NSDictionary *)styles;

- (void)addAdditionalAttribute:(id)attribute forKey:(id)key;

- (NSString *)path;

- (NSString *)attributeForKey:(NSString *)key;

- (void)addChild:(DTHTMLElement *)child;
- (void)removeChild:(DTHTMLElement *)child;

- (DTHTMLElement *)parentWithTagName:(NSString *)name;
- (BOOL)isContainedInBlockElement;

@end
