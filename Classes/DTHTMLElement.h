//
//  DTHTMLElement.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 4/14/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DTCoreTextParagraphStyle;
@class DTCoreTextFontDescriptor;
@class DTTextAttachment;

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

typedef enum
{
    DTHTMLElementListStyleInherit = 0,
    DTHTMLElementListStyleNone,
    DTHTMLElementListStyleCircle,
    DTHTMLElementListStyleDecimal,
    DTHTMLElementListStyleDecimalLeadingZero,
    DTHTMLElementListStyleDisc,
    DTHTMLElementListStyleUpperAlpha,
    DTHTMLElementListStyleUpperLatin,
    DTHTMLElementListStyleLowerAlpha,
    DTHTMLElementListStyleLowerLatin,
    DTHTMLElementListStylePlus,
    DTHTMLElementListStyleUnderscore
} DTHTMLElementListStyle;


@interface DTHTMLElement : NSObject <NSCopying>
{
	DTHTMLElement *parent;
	
    DTCoreTextFontDescriptor *fontDescriptor;
    DTCoreTextParagraphStyle *paragraphStyle;
    DTTextAttachment *textAttachment;
    NSURL *link;
    
    UIColor *_textColor;
	UIColor *backgroundColor;
    
    CTUnderlineStyle underlineStyle;
    
    NSString *tagName;
    NSString *text;
    
    BOOL tagContentInvisible;
    BOOL strikeOut;
    NSInteger superscriptStyle;
    
    NSInteger headerLevel;
    
    NSArray *shadows;
    
    NSMutableDictionary *_fontCache;
    
    NSInteger _isInline;
    NSInteger _isMeta;
	
	NSMutableDictionary *_additionalAttributes;
	
	DTHTMLElementFloatStyle floatStyle;
    DTHTMLElementListStyle listStyle;
    
	BOOL isColorInherited;
	
	BOOL preserveNewlines;
	
	DTHTMLElementFontVariant fontVariant;
    
    CGFloat textScale;
    CGSize size;
    
    NSInteger _listDepth;
    NSInteger _listCounter;
    
    NSMutableArray *children;
}

@property (nonatomic, assign) DTHTMLElement *parent;
@property (nonatomic, copy) DTCoreTextFontDescriptor *fontDescriptor;
@property (nonatomic, copy) DTCoreTextParagraphStyle *paragraphStyle;
@property (nonatomic, retain) DTTextAttachment *textAttachment;
@property (nonatomic, copy) NSURL *link;
@property (nonatomic, retain) UIColor *textColor;
@property (nonatomic, retain) UIColor *backgroundColor;
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
@property (nonatomic, assign) DTHTMLElementListStyle listStyle;
@property (nonatomic, assign) CGFloat textScale;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, readonly) NSArray *children;
@property (nonatomic, readonly) NSInteger listDepth;
@property (nonatomic) NSInteger listCounter;


- (NSAttributedString *)attributedString;
- (NSAttributedString *)prefixForListItemWithCounter:(NSInteger)counter;
- (NSDictionary *)attributesDictionary;

- (void)parseStyleString:(NSString *)styleString;
- (void)addAdditionalAttribute:(id)attribute forKey:(id)key;

- (NSString *)path;

- (void)addChild:(DTHTMLElement *)child;
- (void)removeChild:(DTHTMLElement *)child;

- (DTHTMLElement *)parentWithTagName:(NSString *)name;
- (BOOL)isContainedInBlockElement;

@end
