//
//  DTHTMLElement.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 4/14/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTHTMLElement.h"
#import "DTCoreTextParagraphStyle.h"
#import "DTCoreTextFontDescriptor.h"
#import "NSAttributedStringRunDelegates.h"
#import "NSString+HTML.h"
#import "UIColor+HTML.h"
#import "NSCharacterSet+HTML.h"
#import "DTTextAttachment.h"
#import "NSAttributedString+HTML.h"
#import "NSMutableAttributedString+HTML.h"

#import "DTCSSListStyle.h"

@interface DTHTMLElement ()

@property (nonatomic, strong) NSMutableDictionary *fontCache;
@property (nonatomic, strong) NSMutableArray *children;

- (DTCSSListStyle *)calculatedListStyle;

@end


@implementation DTHTMLElement
{
	__unsafe_unretained DTHTMLElement *parent;
	
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
    DTCSSListStyle *_listStyle;
    
	BOOL isColorInherited;
	
	BOOL preserveNewlines;
	
	DTHTMLElementFontVariant fontVariant;
    
    CGFloat textScale;
    CGSize size;
    
    NSInteger _listDepth;
    NSInteger _listCounter;
    
    NSMutableArray *_children;
	NSDictionary *_attributes; // contains all attributes from parsing
}

- (id)init
{
	self = [super init];
	if (self)
	{
		_isInline = -1;
		_isMeta = -1;
		_listDepth = -1;
		_listCounter = NSIntegerMin;
	}
	
	return self;
}

- (NSDictionary *)attributesDictionary
{
	NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
	
	BOOL shouldAddFont = YES;
	
	// copy additional attributes
	if (_additionalAttributes)
	{
		[tmpDict setDictionary:_additionalAttributes];
	}
	
	// add text attachment
	if (textAttachment)
	{
		// need run delegate for sizing
		CTRunDelegateRef embeddedObjectRunDelegate = createEmbeddedObjectRunDelegate(textAttachment);
		[tmpDict setObject:CFBridgingRelease(embeddedObjectRunDelegate) forKey:(id)kCTRunDelegateAttributeName];
		//CFRelease(embeddedObjectRunDelegate);
		
		// add attachment
		[tmpDict setObject:textAttachment forKey:@"DTTextAttachment"];
		
		// remember original paragraphSpacing
		[tmpDict setObject:[NSNumber numberWithFloat:self.paragraphStyle.paragraphSpacing] forKey:@"DTAttachmentParagraphSpacing"];
		
#ifndef DT_ADD_FONT_ON_ATTACHMENTS
		// omit adding a font unless we need it also on attachments, e.g. for editing
		shouldAddFont = NO;
#endif
	}
	
	// otherwise we have a font
	if (shouldAddFont)
	{
		// try font cache first
		NSNumber *key = [NSNumber numberWithInt:[fontDescriptor hash]];
		CTFontRef font = (__bridge CTFontRef)[self.fontCache objectForKey:key];
		
		if (!font)
		{
			font = [fontDescriptor newMatchingFont];
			
			if (font)
			{
				[self.fontCache setObject:CFBridgingRelease(font) forKey:key];
			}
		}
		
		if (font)
		{
			// __bridge since its already retained elsewhere
			[tmpDict setObject:(__bridge id)(font) forKey:(id)kCTFontAttributeName];
		}
	}
	
	// add hyperlink
	if (link)
	{
		[tmpDict setObject:link forKey:@"DTLink"];
		
		// add a GUID to group multiple glyph runs belonging to same link
		[tmpDict setObject:[NSString guid] forKey:@"DTGUID"];
	}
	
	// add strikout if applicable
	if (strikeOut)
	{
		[tmpDict setObject:[NSNumber numberWithBool:YES] forKey:@"DTStrikeOut"];
	}
	
	// set underline style
	if (underlineStyle)
	{
		[tmpDict setObject:[NSNumber numberWithInteger:underlineStyle] forKey:(id)kCTUnderlineStyleAttributeName];
		
		// we could set an underline color as well if we wanted, but not supported by HTML
		//      [attributes setObject:(id)[UIColor redColor].CGColor forKey:(id)kCTUnderlineColorAttributeName];
	}
	
	if (_textColor)
	{
		[tmpDict setObject:(id)[_textColor CGColor] forKey:(id)kCTForegroundColorAttributeName];
	}
	
	if (backgroundColor)
	{
		[tmpDict setObject:(id)[backgroundColor CGColor] forKey:@"DTBackgroundColor"];
	}
	
	if (superscriptStyle)
	{
		[tmpDict setObject:(id)[NSNumber numberWithInt:superscriptStyle] forKey:(id)kCTSuperscriptAttributeName];
	}
	
	// correct spacing to match current font size
	if (self.paragraphStyle.paragraphSpacing>0)
	{
		self.paragraphStyle.paragraphSpacing = self.fontDescriptor.pointSize;
	}
	
	// correct spacing to match current font size
	if (self.paragraphStyle.paragraphSpacingBefore>0)
	{
		self.paragraphStyle.paragraphSpacingBefore = self.fontDescriptor.pointSize;
	}
	
	// add paragraph style
	if (paragraphStyle)
	{
		CTParagraphStyleRef newParagraphStyle = [self.paragraphStyle createCTParagraphStyle];
		[tmpDict setObject:CFBridgingRelease(newParagraphStyle) forKey:(id)kCTParagraphStyleAttributeName];
		//CFRelease(newParagraphStyle);
	}
	
	// add shadow array if applicable
	if (shadows)
	{
		[tmpDict setObject:shadows forKey:@"DTShadows"];
	}
	
	// add tag for PRE so that we can omit changing this font if we override fonts
	if (preserveNewlines)
	{
		[tmpDict setObject:[NSNumber numberWithBool:YES] forKey:@"DTPreserveNewlines"];
	}
	
	if (headerLevel)
	{
		[tmpDict setObject:[NSNumber numberWithInteger:headerLevel] forKey:@"DTHeaderLevel"];
	}
	
	return tmpDict;
}

- (NSAttributedString *)attributedString
{
	NSDictionary *attributes = [self attributesDictionary];
	
	if (textAttachment)
	{
		// ignore text, use unicode object placeholder
		NSMutableAttributedString *tmpString = [[NSMutableAttributedString alloc] initWithString:UNICODE_OBJECT_PLACEHOLDER attributes:attributes];
		
		BOOL needsNewLineAfter = ![self isContainedInBlockElement];
		
#if ALLOW_IPHONE_SPECIAL_CASES
		// workaround, make float images blocks because we have no float
		if (floatStyle || textAttachment.displaySize.height > 2.0 * fontDescriptor.pointSize)
		{
			needsNewLineAfter = YES;
		}
#endif
		
		if (needsNewLineAfter)
		{
			[tmpString appendNakedString:@"\n"];
		}
		
		return tmpString;
	}
	else
	{
		if (self.fontVariant == DTHTMLElementFontVariantNormal)
		{
			return [[NSAttributedString alloc] initWithString:text attributes:attributes];
		}
		else
		{
			if ([self.fontDescriptor supportsNativeSmallCaps])
			{
				DTCoreTextFontDescriptor *smallDesc = [self.fontDescriptor copy];
				smallDesc.smallCapsFeature = YES;
				
				CTFontRef smallerFont = [smallDesc newMatchingFont];
				
				NSMutableDictionary *smallAttributes = [attributes mutableCopy];
				[smallAttributes setObject:CFBridgingRelease(smallerFont) forKey:(id)kCTFontAttributeName];
				//CFRelease(smallerFont);
				
				
				return [[NSAttributedString alloc] initWithString:text attributes:smallAttributes];
			}
			
			return [NSAttributedString synthesizedSmallCapsAttributedStringWithText:text attributes:attributes];
		}
	}
}

- (NSAttributedString *)prefixForListItem
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	if (fontDescriptor)
	{
		// make a font without italic or bold
		DTCoreTextFontDescriptor *fontDesc = [self.fontDescriptor copy];
		
		fontDesc.boldTrait = NO;
		fontDesc.italicTrait = NO;
		
		CTFontRef font = [fontDesc newMatchingFont];
		
		[attributes setObject:CFBridgingRelease(font) forKey:(id)kCTFontAttributeName];
		//CFRelease(font);
	}
	
	// text color for bullet same as text
	if (_textColor)
	{
		[attributes setObject:(id)[_textColor CGColor] forKey:(id)kCTForegroundColorAttributeName];
	}
	// add paragraph style (this has the tabs)
	if (paragraphStyle)
	{
		CTParagraphStyleRef newParagraphStyle = [self.paragraphStyle createCTParagraphStyle];
		[attributes setObject:CFBridgingRelease(newParagraphStyle) forKey:(id)kCTParagraphStyleAttributeName];
		//CFRelease(newParagraphStyle);
	}
	
	// get calculated list style
	DTCSSListStyle *calculatedListStyle = [self calculatedListStyle];
	
	NSString *prefix = [calculatedListStyle prefixWithCounter:_listCounter];
	
	if (prefix)
	{
		UIImage *image = nil;
		
		if (calculatedListStyle.imageName)
		{
			image = [UIImage imageNamed:calculatedListStyle.imageName];
			
			if (!image)
			{
				// image invalid
				calculatedListStyle.imageName = nil;
				
				prefix = [calculatedListStyle prefixWithCounter:_listCounter];
			}
		}
		
		NSMutableAttributedString *tmpStr = [[NSMutableAttributedString alloc] initWithString:prefix attributes:attributes];
		
		
		if (image)
		{
			// make an attachment for the image
			DTTextAttachment *attachment = [[DTTextAttachment alloc] init];
			attachment.contents = image;
			attachment.contentType = DTTextAttachmentTypeImage;
			attachment.displaySize = image.size;
			
			// need run delegate for sizing
			CTRunDelegateRef embeddedObjectRunDelegate = createEmbeddedObjectRunDelegate(attachment);
			[attributes setObject:CFBridgingRelease(embeddedObjectRunDelegate) forKey:(id)kCTRunDelegateAttributeName];
			//CFRelease(embeddedObjectRunDelegate);
			
			// add attachment
			[attributes setObject:attachment forKey:@"DTTextAttachment"];				
			
			if (calculatedListStyle.position == DTCSSListStylePositionInside)
			{
				[tmpStr setAttributes:attributes range:NSMakeRange(2, 1)];
			}
			else
			{
				[tmpStr setAttributes:attributes range:NSMakeRange(1, 1)];
			}
		}
		
		return tmpStr;
	}
	
	return nil;
}


- (void)applyStyleDictionary:(NSDictionary *)styles
{
	if (![styles count])
	{
		return;
	}
	
	NSString *fontSize = [styles objectForKey:@"font-size"];
	if (fontSize)
	{
		// absolute sizes based on 12.0 CoreText default size, Safari has 16.0
		
		if ([fontSize isEqualToString:@"smaller"])
		{
			fontDescriptor.pointSize /= 1.2f;
		}
		else if ([fontSize isEqualToString:@"larger"])
		{
			fontDescriptor.pointSize *= 1.2f;
		}
		else if ([fontSize isEqualToString:@"xx-small"])
		{
			fontDescriptor.pointSize = 9.0f/1.3333f * textScale;
		}
		else if ([fontSize isEqualToString:@"x-small"])
		{
			fontDescriptor.pointSize = 10.0f/1.3333f * textScale;
		}
		else if ([fontSize isEqualToString:@"small"])
		{
			fontDescriptor.pointSize = 13.0f/1.3333f * textScale;
		}
		else if ([fontSize isEqualToString:@"medium"])
		{
			fontDescriptor.pointSize = 16.0f/1.3333f * textScale;
		}
		else if ([fontSize isEqualToString:@"large"])
		{
			fontDescriptor.pointSize = 22.0f/1.3333f * textScale;
		}
		else if ([fontSize isEqualToString:@"x-large"])
		{
			fontDescriptor.pointSize = 24.0f/1.3333f * textScale;
		}
		else if ([fontSize isEqualToString:@"xx-large"])
		{
			fontDescriptor.pointSize = 37.0f/1.3333f * textScale;
		}
		else if ([fontSize isEqualToString:@"inherit"])
		{
			fontDescriptor.pointSize = parent.fontDescriptor.pointSize;
		}
		else
		{
			fontDescriptor.pointSize = [fontSize pixelSizeOfCSSMeasureRelativeToCurrentTextSize:fontDescriptor.pointSize]; // already multiplied with textScale
		}
	}
	
	NSString *color = [styles objectForKey:@"color"];
	if (color)
	{
		self.textColor = [UIColor colorWithHTMLName:color];       
	}
	
	NSString *bgColor = [styles objectForKey:@"background-color"];
	if (bgColor)
	{
		self.backgroundColor = [UIColor colorWithHTMLName:bgColor];       
	}
	
	NSString *floatString = [styles objectForKey:@"float"];
	
	if (floatString)
	{
		if ([floatString isEqualToString:@"left"])
		{
			floatStyle = DTHTMLElementFloatStyleLeft;
		}
		else if ([floatString isEqualToString:@"right"])
		{
			floatStyle = DTHTMLElementFloatStyleRight;
		}
		else if ([floatString isEqualToString:@"none"])
		{
			floatStyle = DTHTMLElementFloatStyleNone;
		}
	}
	
	NSString *fontFamily = [[styles objectForKey:@"font-family"] stringByTrimmingCharactersInSet:[NSCharacterSet quoteCharacterSet]];
	
	if (fontFamily)
	{
		NSString *lowercaseFontFamily = [fontFamily lowercaseString];
		
		if ([lowercaseFontFamily rangeOfString:@"helvetica"].length || [lowercaseFontFamily rangeOfString:@"arial"].length || [lowercaseFontFamily rangeOfString:@"geneva"].length)
		{
			fontDescriptor.fontFamily = @"Helvetica";
		}
		else if ([lowercaseFontFamily rangeOfString:@"courier"].length)
		{
			fontDescriptor.fontFamily = @"Courier";
		}
		else if ([lowercaseFontFamily rangeOfString:@"cursive"].length)
		{
			fontDescriptor.stylisticClass = kCTFontScriptsClass;
			fontDescriptor.fontFamily = nil;
		}
		else if ([lowercaseFontFamily rangeOfString:@"sans-serif"].length)
		{
			// too many matches (24)
			// fontDescriptor.stylisticClass = kCTFontSansSerifClass;
			fontDescriptor.fontFamily = @"Helvetica";
		}
		else if ([lowercaseFontFamily rangeOfString:@"serif"].length)
		{
			// kCTFontTransitionalSerifsClass = Baskerville
			// kCTFontClarendonSerifsClass = American Typewriter
			// kCTFontSlabSerifsClass = Courier New
			// 
			// strangely none of the classes yields Times
			fontDescriptor.fontFamily = @"Times New Roman";
		}
		else if ([lowercaseFontFamily rangeOfString:@"fantasy"].length)
		{
			fontDescriptor.fontFamily = @"Papyrus"; // only available on iPad
		}
		else if ([lowercaseFontFamily rangeOfString:@"monospace"].length) 
		{
			fontDescriptor.monospaceTrait = YES;
			fontDescriptor.fontFamily = @"Courier";
		}
		else if ([lowercaseFontFamily rangeOfString:@"times"].length) 
		{
			fontDescriptor.fontFamily = @"Times New Roman";
		}
		else
		{
			// probably custom font registered in info.plist
			fontDescriptor.fontFamily = fontFamily;
		}
	}
	
	NSString *fontStyle = [[styles objectForKey:@"font-style"] lowercaseString];
	if (fontStyle)
	{
		if ([fontStyle isEqualToString:@"normal"])
		{
			fontDescriptor.italicTrait = NO;
		}
		else if ([fontStyle isEqualToString:@"italic"] || [fontStyle isEqualToString:@"oblique"])
		{
			fontDescriptor.italicTrait = YES;
		}
		else if ([fontStyle isEqualToString:@"inherit"])
		{
			// nothing to do
		}
	}
	
	NSString *fontWeight = [[styles objectForKey:@"font-weight"] lowercaseString];
	if (fontWeight)
	{
		if ([fontWeight isEqualToString:@"normal"])
		{
			fontDescriptor.boldTrait = NO;
		}
		else if ([fontWeight isEqualToString:@"bold"])
		{
			fontDescriptor.boldTrait = YES;
		}
		else if ([fontWeight isEqualToString:@"bolder"])
		{
			fontDescriptor.boldTrait = YES;
		}
		else if ([fontWeight isEqualToString:@"lighter"])
		{
			fontDescriptor.boldTrait = NO;
		}
		else 
		{
			// can be 100 - 900
			
			NSInteger value = [fontWeight intValue];
			
			if (value<=600)
			{
				fontDescriptor.boldTrait = NO;
			}
			else 
			{
				fontDescriptor.boldTrait = YES;
			}
		}
	}
	
	
	NSString *decoration = [[styles objectForKey:@"text-decoration"] lowercaseString];
	if (decoration)
	{
		if ([decoration isEqualToString:@"underline"])
		{
			self.underlineStyle = kCTUnderlineStyleSingle;
		}
		else if ([decoration isEqualToString:@"line-through"])
		{
			self.strikeOut = YES;
		}
		else if ([decoration isEqualToString:@"none"])
		{
			// remove all
			self.underlineStyle = kCTUnderlineStyleNone;
			self.strikeOut = NO;
		}
		else if ([decoration isEqualToString:@"overline"])
		{
			//TODO: add support for overline decoration
		}
		else if ([decoration isEqualToString:@"blink"])
		{
			//TODO: add support for blink decoration
		}
		else if ([decoration isEqualToString:@"inherit"])
		{
			// nothing to do
		}
	}
	
	NSString *alignment = [[styles objectForKey:@"text-align"] lowercaseString];
	if (alignment)
	{
		if ([alignment isEqualToString:@"left"])
		{
			self.paragraphStyle.textAlignment = kCTLeftTextAlignment;
		}
		else if ([alignment isEqualToString:@"right"])
		{
			self.paragraphStyle.textAlignment = kCTRightTextAlignment;
		}
		else if ([alignment isEqualToString:@"center"])
		{
			self.paragraphStyle.textAlignment = kCTCenterTextAlignment;
		}
		else if ([alignment isEqualToString:@"justify"])
		{
			self.paragraphStyle.textAlignment = kCTJustifiedTextAlignment;
		}
		else if ([alignment isEqualToString:@"inherit"])
		{
			// nothing to do
		}
	}
	
	NSString *shadow = [styles objectForKey:@"text-shadow"];
	if (shadow)
	{
		self.shadows = [shadow arrayOfCSSShadowsWithCurrentTextSize:fontDescriptor.pointSize currentColor:_textColor];
	}
	
	NSString *lineHeight = [[styles objectForKey:@"line-height"] lowercaseString];
	if (lineHeight)
	{
		if ([lineHeight isEqualToString:@"normal"])
		{
			self.paragraphStyle.lineHeightMultiple = 0.0; // default
		}
		else if ([lineHeight isEqualToString:@"inherit"])
		{
			// no op, we already inherited it
		}
		else if ([lineHeight isNumeric])
		{
			self.paragraphStyle.lineHeightMultiple = [lineHeight floatValue];
			//            self.paragraphStyle.minimumLineHeight = fontDescriptor.pointSize * (CGFloat)[lineHeight intValue];
			//            self.paragraphStyle.maximumLineHeight = self.paragraphStyle.minimumLineHeight;
		}
		else // interpret as length
		{
			self.paragraphStyle.minimumLineHeight = [lineHeight pixelSizeOfCSSMeasureRelativeToCurrentTextSize:fontDescriptor.pointSize];
			self.paragraphStyle.maximumLineHeight = self.paragraphStyle.minimumLineHeight;
		}
	}
	
	NSString *fontVariantStr = [[styles objectForKey:@"font-variant"] lowercaseString];
	if (fontVariantStr)
	{
		if ([fontVariantStr isEqualToString:@"small-caps"])
		{
			fontVariant = DTHTMLElementFontVariantSmallCaps;
		}
		else if ([fontVariantStr isEqualToString:@"inherit"])
		{
			fontVariant = DTHTMLElementFontVariantInherit;
		}
		else
		{
			fontVariant = DTHTMLElementFontVariantNormal;
		}
	}
	
	// list style became it's own object
	self.listStyle = [DTCSSListStyle listStyleWithStyles:styles];
	
	
	NSString *widthString = [styles objectForKey:@"width"];
	if (widthString && ![widthString isEqualToString:@"auto"])
	{
		size.width = [widthString pixelSizeOfCSSMeasureRelativeToCurrentTextSize:self.fontDescriptor.pointSize];
	}
	
	NSString *heightString = [styles objectForKey:@"height"];
	if (heightString && ![heightString isEqualToString:@"auto"])
	{
		size.height = [heightString pixelSizeOfCSSMeasureRelativeToCurrentTextSize:self.fontDescriptor.pointSize];
	}
}

- (void)parseStyleString:(NSString *)styleString
{
	NSDictionary *styles = [styleString dictionaryOfCSSStyles];
	[self applyStyleDictionary:styles];
}

- (void)addAdditionalAttribute:(id)attribute forKey:(id)key
{
	if (!_additionalAttributes)
	{
		_additionalAttributes = [[NSMutableDictionary alloc] init];
	}
	
	[_additionalAttributes setObject:attribute forKey:key];
}

- (void)addChild:(DTHTMLElement *)child
{
	child.parent = self;
	[self.children addObject:child];
}

- (void)removeChild:(DTHTMLElement *)child
{
	[self.children removeObject:child];
}

- (DTHTMLElement *)parentWithTagName:(NSString *)name
{
	if ([self.parent.tagName isEqualToString:name])
	{
		return self.parent;
	}
	
	return [self.parent parentWithTagName:name];
}

- (BOOL)isContainedInBlockElement
{
	if (!parent || [parent isMeta] || !parent.tagName) // default tag has no tag name
	{
		return NO;
	}
	
	if ([self.parent isInline])
	{
		return [self.parent isContainedInBlockElement];
	}
	
	return YES;
}

- (NSString *)attributeForKey:(NSString *)key
{
	return [_attributes objectForKey:key];
}

#pragma mark Calulcating Properties

- (id)valueForKeyPathWithInheritance:(NSString *)keyPath
{
	
	
	id value = [self valueForKeyPath:keyPath];
	
	// if property is not set we also go to parent
	if (!value && parent)
	{
		return [parent valueForKeyPathWithInheritance:keyPath];
	}
	
	// enum properties have 0 for inherit
	if ([value isKindOfClass:[NSNumber class]])
	{
		NSNumber *number = value;
		
		if (([number integerValue]==0) && parent)
		{
			return [parent valueForKeyPathWithInheritance:keyPath];
		}
	}
	
	// string properties have 'inherit' for inheriting
	if ([value isKindOfClass:[NSString class]])
	{
		NSString *string = value;
		
		if ([string isEqualToString:@"inherit"] && parent)
		{
			return [parent valueForKeyPathWithInheritance:keyPath];
		}
	}
	
	// obviously not inherited
	return value;
}


- (DTCSSListStyle *)calculatedListStyle
{
	DTCSSListStyle *style = [[DTCSSListStyle alloc] init];
	
	id calcType = [self valueForKeyPathWithInheritance:@"listStyle.type"];
	id calcPos = [self valueForKeyPathWithInheritance:@"listStyle.position"];
	id calcImage = [self valueForKeyPathWithInheritance:@"listStyle.imageName"];
	
	style.type = (DTCSSListStyleType)[calcType integerValue];
	style.position = (DTCSSListStylePosition)[calcPos integerValue];
	style.imageName = calcImage;
	
	return style;
}

#pragma mark Copying

- (id)copyWithZone:(NSZone *)zone
{
	DTHTMLElement *newObject = [[DTHTMLElement allocWithZone:zone] init];
	
	newObject.fontDescriptor = self.fontDescriptor; // copy
	newObject.paragraphStyle = self.paragraphStyle; // copy
	
	newObject.fontVariant = self.fontVariant;
	
	newObject.underlineStyle = self.underlineStyle;
	newObject.tagContentInvisible = self.tagContentInvisible;
	newObject.textColor = self.textColor;
	newObject.isColorInherited = YES;
	newObject.backgroundColor = self.backgroundColor;
	newObject.strikeOut = self.strikeOut;
	newObject.superscriptStyle = self.superscriptStyle;
	newObject.shadows = self.shadows;
	
	newObject.link = self.link; // copy
	
	newObject.preserveNewlines = self.preserveNewlines;
	
	newObject.fontCache = self.fontCache; // reference
	newObject.listCounter = self.listCounter;
	
	return newObject;
}

#pragma mark Properties

- (NSMutableDictionary *)fontCache
{
	if (!_fontCache)
	{
		_fontCache = [[NSMutableDictionary alloc] init];
	}
	
	return _fontCache;
}

- (BOOL)isInline
{
	if (_isInline<0)
	{
		_isInline = [tagName isInlineTag];
	}
	
	return _isInline ? YES : NO;
}

- (BOOL)isMeta
{
	if (_isMeta<0)
	{
		_isMeta = [tagName isMetaTag];
	}
	
	return _isMeta ? YES : NO;
}
- (void)setTextColor:(UIColor *)textColor
{
	if (_textColor != textColor)
	{
		
		_textColor = textColor;
		isColorInherited = NO;
	}
}

- (DTHTMLElementFontVariant)fontVariant
{
	if (fontVariant == DTHTMLElementFontVariantInherit)
	{
		if (parent)
		{
			return parent.fontVariant;
		}
		
		return DTHTMLElementFontVariantNormal;
	}
	
	return fontVariant;
}

- (NSString *)path
{
	if (parent)
	{
		return [[parent path] stringByAppendingFormat:@"/%@", self.tagName];
	}
	
	if (tagName)
	{
		return tagName;
	}
	
	return @"root";
}

- (NSInteger)listDepth
{
	if (_listDepth < 0)
	{
		// See if this is a list related element.
		if ([tagName isEqualToString:@"ol"] || [tagName isEqualToString:@"ul"] || [tagName isEqualToString:@"li"])
		{
			// Walk up the tree to the root. Increment the count every time we hit an OL or UL tag
			// so we have our nesting count correct.
			DTHTMLElement *elem = self;
			_listDepth = 0;
			while (elem.parent) {
				NSString *tag = elem.parent.tagName;
				if ([tag isEqualToString:@"ol"] || [tag isEqualToString:@"ul"])
				{
					_listDepth++;
				}
				elem = elem.parent;
			}
		}
		else {
			// We're not a list element, so set the depth to zero.
			_listDepth = 0;
		}
	}
	return _listDepth;
}

- (NSInteger)listCounter
{
	// If the counter is set to NSIntegerMin, it hasn't been calculated or manually set.
	// Calculate it on demand.
	if (_listCounter == NSIntegerMin)
	{
		// See if this is an LI. No other elements get a counter.
		if ([tagName isEqualToString:@"li"])
		{
			// Count the number of LI elements in the parent until we reach self. That's our counter.
			NSInteger counter = 1;
			NSUInteger numChildren = [parent.children count];
			for (NSUInteger i = 0; i < numChildren; i++)
			{
				// We walk through the children and check for LI elements just in case someone
				// slipped us some bad HTML.
				DTHTMLElement *child = [parent.children objectAtIndex:i];
				if (child != self && [child.tagName isEqualToString:@"li"])
				{
					// Add one to the last LI's value just in case its listCounter property got overridden and
					// set to something other than its natural order in the elements list.
					counter = child.listCounter + 1;
				}
				else
				{
					break;
				}
			}
			_listCounter = counter;
		}
		else
		{
			_listCounter = 0;
		}
	}
	return _listCounter;
}

- (void)setListCounter:(NSInteger)count
{
	_listCounter = count;
}

- (NSMutableArray *)children
{
	if (!_children)
	{
		_children = [[NSMutableArray alloc] init];
	}
	
	return _children;
}

- (void)setAttributes:(NSDictionary *)attributes
{
	if (_attributes != attributes)
	{
		_attributes = attributes;
		
		// decode size contained in attributes, might be overridden later by CSS size
		size = CGSizeMake([[self attributeForKey:@"width"] floatValue], [[self attributeForKey:@"height"] floatValue]); 
	}
}


@synthesize parent;
@synthesize fontDescriptor;
@synthesize paragraphStyle;
@synthesize textColor = _textColor;
@synthesize backgroundColor;
@synthesize tagName;
@synthesize text;
@synthesize link;
@synthesize underlineStyle;
@synthesize textAttachment;
@synthesize tagContentInvisible;
@synthesize strikeOut;
@synthesize superscriptStyle;
@synthesize headerLevel;
@synthesize shadows;
@synthesize isInline;
@synthesize floatStyle;
@synthesize isColorInherited;
@synthesize preserveNewlines;
@synthesize fontVariant;
@synthesize listStyle = _listStyle;
@synthesize textScale;
@synthesize size;

@synthesize fontCache = _fontCache;
@synthesize children = _children;
@synthesize attributes = _attributes;



@end


