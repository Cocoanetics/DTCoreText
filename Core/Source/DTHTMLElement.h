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

/** DTHTMLElement represents a single HTML element with CSS styles, that can have parents and children. */
@interface DTHTMLElement : NSObject <NSCopying>

@property (nonatomic, strong) DTHTMLElement *parent;
// Document font descriptor first. */
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
/** Contains all attributes from parsing */
@property (nonatomic, strong) NSDictionary *attributes;

/** @name Attributed string relevant methods. */
/** Return an attributed string from the dictionary of attributes (attributesDictionary) applied to this element's text. If this element has a text attachment then the element's text is ignored in the attributed string being replaced by the unicode replacement character: �. 
 
 @returns An NSAttributedString of the attributes applied to this element and applied on this element's text if without a text attachment. */
- (NSAttributedString *)attributedString;
/** */
- (NSAttributedString *)prefixForListItemWithCounter:(NSUInteger)listCounter;
/** 
 @returns A dictionary of the attributes applied to this element. */
- (NSDictionary *)attributesDictionary;

/** @name Styles methods */
/** Parse a string for CSS styles and apply those styles to this element. 

 @param styleString A string containing CSS styles which are parsed and then applied to this element. */
- (void)parseStyleString:(NSString *)styleString;

/** Applies the styles contained in styles parameter to this element. 

 @param styles Dictionary of CSS styles to be applied to this element. */
- (void)applyStyleDictionary:(NSDictionary *)styles;

/**  The styles applied to this element through parseStyleString: and applyStyleDictionary:. Stored as a CSS style dictionary. 
 @returns A dictionary of CSS styles that were applied to this element. */
- (NSDictionary *)styles;

/** Add another attribute to the additional attributes dictionary which will be taken into account when generating the attributesDictionary. 
 @param attribute The attribute to add. 
 @param key The key for the added attribute. 
 */
- (void)addAdditionalAttribute:(id)attribute forKey:(id)key;

- (NSString *)path;

- (NSString *)attributeForKey:(NSString *)key;

/** @name HTML child element methods */
/** Adds a child element to this element's list of children. 

 @param child An HTML element to be added to this element's children. */
- (void)addChild:(DTHTMLElement *)child;

/** Removes a specific child element. 
 @param child The child element instance to be removed as a child. */
- (void)removeChild:(DTHTMLElement *)child;

/** Checks if this element's parent has the same tag name as the parameter name. Ascends the parent hierarchy to find the tag name.

 If this parent doesn't have it, check the grandparents and so on). If no parent in the hierarchy has the correct tag the father elements's call to parentWithTagName: will return nil because it has no parent itself.

 @param name The NSString tag name to check. 
 @returns The HTML element with the tag name  */
- (DTHTMLElement *)parentWithTagName:(NSString *)name;

/** Quick method to check if all parents display inline as used by block elements. 

 @returns YES if this method is within a block element. */
- (BOOL)isContainedInBlockElement;

@end
