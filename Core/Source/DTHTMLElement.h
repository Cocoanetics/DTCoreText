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


#import "DTCoreTextConstants.h"
#import "DTHTMLParserNode.h"
#import "DTTextAttachment.h"

@class DTHTMLElementBR;

/**
 Class to represent a element (aka "tag") in a HTML document. Structure information - like parent or children - is inherited from its superclass <DTHTMLParserNode>.
 */
@interface DTHTMLElement : DTHTMLParserNode
{
	DTHTMLElement *_parent;
	
	DTCoreTextFontDescriptor *_fontDescriptor;
	DTCoreTextParagraphStyle *_paragraphStyle;
	DTTextAttachment *_textAttachment;
	DTTextAttachmentVerticalAlignment _textAttachmentAlignment;
	NSURL *_link;
	NSString *_anchorName;
	
	DTColor *_textColor;
	DTColor *_backgroundColor;
	
	CTUnderlineStyle _underlineStyle;
	
	NSString *_beforeContent;
	
	NSString *_linkGUID;
	
	BOOL _tagContentInvisible;
	BOOL _strikeOut;
	NSInteger _superscriptStyle;
	
	NSInteger _headerLevel;
	
	NSArray *_shadows;
	
	NSMutableDictionary *_fontCache;
	
	NSMutableDictionary *_additionalAttributes;
	
	DTHTMLElementDisplayStyle _displayStyle;
	DTHTMLElementFloatStyle _floatStyle;
	
	BOOL _isColorInherited;
	
	BOOL _preserveNewlines;
	
	DTHTMLElementFontVariant _fontVariant;
	
	CGFloat _textScale;
	CGSize _size;
	
	NSMutableArray *_children;
	
	NSDictionary *_styles;
	
	BOOL _didOutput;
}

@property (nonatomic, copy) DTCoreTextFontDescriptor *fontDescriptor;
@property (nonatomic, copy) DTCoreTextParagraphStyle *paragraphStyle;
@property (nonatomic, strong) DTTextAttachment *textAttachment;
@property (nonatomic, copy) NSURL *link;
@property (nonatomic, copy) NSString *anchorName;
@property (nonatomic, strong) DTColor *textColor;
@property (nonatomic, strong) DTColor *backgroundColor;
@property (nonatomic, copy) NSString *beforeContent;
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

@property (nonatomic, assign) BOOL didOutput;

/**
 Ignores children for output that consist only of whitespace
 */
@property (nonatomic, assign) BOOL supressWhitespaceChildren;


/**
 Designed initializer, creates the appropriate element sub type
 @param attributes The attributes dictionary of the tag
 @param options The parsing options dictionary
 @returns the initialized element
 */
+ (DTHTMLElement *)elementWithName:(NSString *)name attributes:(NSDictionary *)attributes options:(NSDictionary *)options;
/**
 Creates an `NSAttributedString` that represents the receiver including all its children
 */
- (NSAttributedString *)attributedString;


- (NSDictionary *)attributesDictionary;

- (void)parseStyleString:(NSString *)styleString;
- (void)applyStyleDictionary:(NSDictionary *)styles;
- (NSDictionary *)styles;

- (void)addAdditionalAttribute:(id)attribute forKey:(id)key;

- (NSString *)attributeForKey:(NSString *)key;

/**
 Copies and inherits relevant attributes from the given parent element
 */
- (void)inheritAttributesFromElement:(DTHTMLElement *)element;

/**
 Returns the parent element. That's the same as the parent node but with adjusted type for convenience.
 */
- (DTHTMLElement *)parentElement;


- (BOOL)needsOutput;

/**
 Appends an attributed string representation of the receiver - including its children - to the given attributed string.
 @param attributedString A mutable attributed string to append to
 */
//- (void)appendToAttributedString:(NSMutableAttributedString *)attributedString;

- (BOOL)containedInBlock;

@end
