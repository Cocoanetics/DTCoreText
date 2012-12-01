//
//  DTHTMLElement.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 4/14/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCoreText.h"
#import "DTHTMLElement.h"

@interface DTHTMLElement ()

@property (nonatomic, strong) NSMutableDictionary *fontCache;
@property (nonatomic, strong) NSMutableArray *children;
@property (nonatomic, strong) NSString *linkGUID;

- (DTCSSListStyle *)calculatedListStyle;

@end


@implementation DTHTMLElement
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
	
	NSString *_tagName;
	
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
	NSDictionary *_attributes; // contains all attributes from parsing
	
	NSDictionary *_styles;
}

- (id)init
{
	self = [super init];
	if (self)
	{
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
	if (_textAttachment)
	{
#if TARGET_OS_IPHONE
		// need run delegate for sizing (only supported on iOS)
		CTRunDelegateRef embeddedObjectRunDelegate = createEmbeddedObjectRunDelegate(_textAttachment);
		[tmpDict setObject:CFBridgingRelease(embeddedObjectRunDelegate) forKey:(id)kCTRunDelegateAttributeName];
#endif		
		
		// add attachment
		[tmpDict setObject:_textAttachment forKey:NSAttachmentAttributeName];
		
		// remember original paragraphSpacing
		[tmpDict setObject:[NSNumber numberWithFloat:self.paragraphStyle.paragraphSpacing] forKey:DTAttachmentParagraphSpacingAttribute];
		
#ifndef DT_ADD_FONT_ON_ATTACHMENTS
		// omit adding a font unless we need it also on attachments, e.g. for editing
		shouldAddFont = NO;
#endif
	}
	
	// otherwise we have a font
	if (shouldAddFont)
	{
		// try font cache first
		NSNumber *key = [NSNumber numberWithUnsignedInteger:[_fontDescriptor hash]];
		CTFontRef font = (__bridge CTFontRef)[self.fontCache objectForKey:key];
		
		if (!font)
		{
			font = [_fontDescriptor newMatchingFont];
			
			if (font)
			{
				[self.fontCache setObject:CFBridgingRelease(font) forKey:key];
			}
		}
		
		if (font)
		{
			// __bridge since its already retained elsewhere
			[tmpDict setObject:(__bridge id)(font) forKey:(id)kCTFontAttributeName];
			
			// use this font to adjust the values needed for the run delegate during layout time
			[_textAttachment adjustVerticalAlignmentForFont:font];
		}
	}
	
	// add hyperlink
	if (_link)
	{
		[tmpDict setObject:_link forKey:DTLinkAttribute];
		
		// add a GUID to group multiple glyph runs belonging to same link
		[tmpDict setObject:_linkGUID forKey:DTGUIDAttribute];
	}
	
	// add anchor
	if (_anchorName)
	{
		[tmpDict setObject:_anchorName forKey:DTAnchorAttribute];
	}
	
	// add strikout if applicable
	if (_strikeOut)
	{
		[tmpDict setObject:[NSNumber numberWithBool:YES] forKey:DTStrikeOutAttribute];
	}
	
	// set underline style
	if (_underlineStyle)
	{
		[tmpDict setObject:[NSNumber numberWithInteger:_underlineStyle] forKey:(id)kCTUnderlineStyleAttributeName];
		
		// we could set an underline color as well if we wanted, but not supported by HTML
		//      [attributes setObject:(id)[DTImage redColor].CGColor forKey:(id)kCTUnderlineColorAttributeName];
	}
	
	if (_textColor)
	{
		[tmpDict setObject:(id)[_textColor CGColor] forKey:(id)kCTForegroundColorAttributeName];
	}
	
	if (_backgroundColor)
	{
		[tmpDict setObject:(id)[_backgroundColor CGColor] forKey:DTBackgroundColorAttribute];
	}
	
	if (_superscriptStyle)
	{
		[tmpDict setObject:(id)[NSNumber numberWithInteger:_superscriptStyle] forKey:(id)kCTSuperscriptAttributeName];
	}
	
	// add paragraph style
	if (_paragraphStyle)
	{
		CTParagraphStyleRef newParagraphStyle = [self.paragraphStyle createCTParagraphStyle];
		[tmpDict setObject:CFBridgingRelease(newParagraphStyle) forKey:(id)kCTParagraphStyleAttributeName];
		//CFRelease(newParagraphStyle);
	}
	
	// add shadow array if applicable
	if (_shadows)
	{
		[tmpDict setObject:_shadows forKey:DTShadowsAttribute];
	}
	
	// add tag for PRE so that we can omit changing this font if we override fonts
	if (_preserveNewlines)
	{
		[tmpDict setObject:[NSNumber numberWithBool:YES] forKey:DTPreserveNewlinesAttribute];
	}
	
	if (_headerLevel)
	{
		[tmpDict setObject:[NSNumber numberWithInteger:_headerLevel] forKey:DTHeaderLevelAttribute];
	}
	
	if (_paragraphStyle.textLists)
	{
		[tmpDict setObject:_paragraphStyle.textLists forKey:DTTextListsAttribute];
	}
	
	if (_paragraphStyle.textBlocks)
	{
		[tmpDict setObject:_paragraphStyle.textBlocks forKey:DTTextBlocksAttribute];
	}
	return tmpDict;
}

- (NSAttributedString *)attributedString
{
	NSDictionary *attributes = [self attributesDictionary];
	
	if (_textAttachment)
	{
		// ignore text, use unicode object placeholder
		NSMutableAttributedString *tmpString = [[NSMutableAttributedString alloc] initWithString:UNICODE_OBJECT_PLACEHOLDER attributes:attributes];
		
		return tmpString;
	}
	else
	{
		if (self.fontVariant == DTHTMLElementFontVariantNormal)
		{
			return [[NSAttributedString alloc] initWithString:_text attributes:attributes];
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
				
				return [[NSAttributedString alloc] initWithString:_text attributes:smallAttributes];
			}
			else
			{
				return [NSAttributedString synthesizedSmallCapsAttributedStringWithText:_text attributes:attributes];
			}
		}
	}
}

- (void)applyStyleDictionary:(NSDictionary *)styles
{
	if (![styles count])
	{
		return;
	}
	
	// keep that for later lookup
	_styles = styles;
	
	// register pseudo-selector contents
	self.beforeContent = [[_styles objectForKey:@"before:content"] stringByDecodingCSSContentAttribute];
	
	NSString *fontSize = [styles objectForKey:@"font-size"];
	if (fontSize)
	{
		// absolute sizes based on 12.0 CoreText default size, Safari has 16.0
		
		if ([fontSize isEqualToString:@"smaller"])
		{
			_fontDescriptor.pointSize /= 1.2f;
		}
		else if ([fontSize isEqualToString:@"larger"])
		{
			_fontDescriptor.pointSize *= 1.2f;
		}
		else if ([fontSize isEqualToString:@"xx-small"])
		{
			_fontDescriptor.pointSize = 9.0f/1.3333f * _textScale;
		}
		else if ([fontSize isEqualToString:@"x-small"])
		{
			_fontDescriptor.pointSize = 10.0f/1.3333f * _textScale;
		}
		else if ([fontSize isEqualToString:@"small"])
		{
			_fontDescriptor.pointSize = 13.0f/1.3333f * _textScale;
		}
		else if ([fontSize isEqualToString:@"medium"])
		{
			_fontDescriptor.pointSize = 16.0f/1.3333f * _textScale;
		}
		else if ([fontSize isEqualToString:@"large"])
		{
			_fontDescriptor.pointSize = 22.0f/1.3333f * _textScale;
		}
		else if ([fontSize isEqualToString:@"x-large"])
		{
			_fontDescriptor.pointSize = 24.0f/1.3333f * _textScale;
		}
		else if ([fontSize isEqualToString:@"xx-large"])
		{
			_fontDescriptor.pointSize = 37.0f/1.3333f * _textScale;
		}
		else if ([fontSize isEqualToString:@"inherit"])
		{
			_fontDescriptor.pointSize = _parent.fontDescriptor.pointSize;
		}
		else
		{
			_fontDescriptor.pointSize = [fontSize pixelSizeOfCSSMeasureRelativeToCurrentTextSize:_fontDescriptor.pointSize]; // already multiplied with textScale
		}
	}
	
	NSString *color = [styles objectForKey:@"color"];
	if (color)
	{
		self.textColor = [DTColor colorWithHTMLName:color];       
	}
	
	NSString *bgColor = [styles objectForKey:@"background-color"];
	if (bgColor)
	{
		self.backgroundColor = [DTColor colorWithHTMLName:bgColor];       
	}
	
	NSString *floatString = [styles objectForKey:@"float"];
	
	if (floatString)
	{
		if ([floatString isEqualToString:@"left"])
		{
			_floatStyle = DTHTMLElementFloatStyleLeft;
		}
		else if ([floatString isEqualToString:@"right"])
		{
			_floatStyle = DTHTMLElementFloatStyleRight;
		}
		else if ([floatString isEqualToString:@"none"])
		{
			_floatStyle = DTHTMLElementFloatStyleNone;
		}
	}
	
	NSString *fontFamily = [[styles objectForKey:@"font-family"] stringByTrimmingCharactersInSet:[NSCharacterSet quoteCharacterSet]];
	
	if (fontFamily)
	{
		NSString *lowercaseFontFamily = [fontFamily lowercaseString];
		
		if ([lowercaseFontFamily rangeOfString:@"geneva"].length)
		{
			_fontDescriptor.fontFamily = @"Helvetica";
		}
		else if ([lowercaseFontFamily rangeOfString:@"cursive"].length)
		{
			_fontDescriptor.stylisticClass = kCTFontScriptsClass;
			_fontDescriptor.fontFamily = nil;
		}
		else if ([lowercaseFontFamily rangeOfString:@"sans-serif"].length)
		{
			// too many matches (24)
			// fontDescriptor.stylisticClass = kCTFontSansSerifClass;
			_fontDescriptor.fontFamily = @"Helvetica";
		}
		else if ([lowercaseFontFamily rangeOfString:@"serif"].length)
		{
			// kCTFontTransitionalSerifsClass = Baskerville
			// kCTFontClarendonSerifsClass = American Typewriter
			// kCTFontSlabSerifsClass = Courier New
			// 
			// strangely none of the classes yields Times
			_fontDescriptor.fontFamily = @"Times New Roman";
		}
		else if ([lowercaseFontFamily rangeOfString:@"fantasy"].length)
		{
			_fontDescriptor.fontFamily = @"Papyrus"; // only available on iPad
		}
		else if ([lowercaseFontFamily rangeOfString:@"monospace"].length) 
		{
			_fontDescriptor.monospaceTrait = YES;
			_fontDescriptor.fontFamily = @"Courier";
		}
		else if ([lowercaseFontFamily rangeOfString:@"times"].length) 
		{
			_fontDescriptor.fontFamily = @"Times New Roman";
		}
		else
		{
			// probably custom font registered in info.plist
			_fontDescriptor.fontFamily = fontFamily;
		}
	}
	
	NSString *fontStyle = [[styles objectForKey:@"font-style"] lowercaseString];
	if (fontStyle)
	{
		if ([fontStyle isEqualToString:@"normal"])
		{
			_fontDescriptor.italicTrait = NO;
		}
		else if ([fontStyle isEqualToString:@"italic"] || [fontStyle isEqualToString:@"oblique"])
		{
			_fontDescriptor.italicTrait = YES;
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
			_fontDescriptor.boldTrait = NO;
		}
		else if ([fontWeight isEqualToString:@"bold"])
		{
			_fontDescriptor.boldTrait = YES;
		}
		else if ([fontWeight isEqualToString:@"bolder"])
		{
			_fontDescriptor.boldTrait = YES;
		}
		else if ([fontWeight isEqualToString:@"lighter"])
		{
			_fontDescriptor.boldTrait = NO;
		}
		else 
		{
			// can be 100 - 900
			
			NSInteger value = [fontWeight intValue];
			
			if (value<=600)
			{
				_fontDescriptor.boldTrait = NO;
			}
			else 
			{
				_fontDescriptor.boldTrait = YES;
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
			self.paragraphStyle.alignment = kCTLeftTextAlignment;
		}
		else if ([alignment isEqualToString:@"right"])
		{
			self.paragraphStyle.alignment = kCTRightTextAlignment;
		}
		else if ([alignment isEqualToString:@"center"])
		{
			self.paragraphStyle.alignment = kCTCenterTextAlignment;
		}
		else if ([alignment isEqualToString:@"justify"])
		{
			self.paragraphStyle.alignment = kCTJustifiedTextAlignment;
		}
		else if ([alignment isEqualToString:@"inherit"])
		{
			// nothing to do
		}
	}
	
	NSString *verticalAlignment = [[styles objectForKey:@"vertical-align"] lowercaseString];
	if (verticalAlignment)
	{
		if ([verticalAlignment isEqualToString:@"sub"])
		{
			self.superscriptStyle = -1;
		}
		else if ([verticalAlignment isEqualToString:@"super"])
		{
			self.superscriptStyle = +1;
		}
		else if ([verticalAlignment isEqualToString:@"baseline"])
		{
			self.superscriptStyle = 0;
		}
		else if ([verticalAlignment isEqualToString:@"inherit"])
		{
			// nothing to do
		}
	}
	
	NSString *shadow = [styles objectForKey:@"text-shadow"];
	if (shadow)
	{
		self.shadows = [shadow arrayOfCSSShadowsWithCurrentTextSize:_fontDescriptor.pointSize currentColor:_textColor];
	}
	
	NSString *lineHeight = [[styles objectForKey:@"line-height"] lowercaseString];
	if (lineHeight)
	{
		if ([lineHeight isEqualToString:@"normal"])
		{
			self.paragraphStyle.lineHeightMultiple = 0.0; // default
			self.paragraphStyle.minimumLineHeight = 0.0; // default
			self.paragraphStyle.maximumLineHeight = 0.0; // default
		}
		else if ([lineHeight isEqualToString:@"inherit"])
		{
			// no op, we already inherited it
		}
		else if ([lineHeight isNumeric])
		{
			self.paragraphStyle.lineHeightMultiple = [lineHeight floatValue];
		}
		else // interpret as length
		{
			self.paragraphStyle.minimumLineHeight = [lineHeight pixelSizeOfCSSMeasureRelativeToCurrentTextSize:_fontDescriptor.pointSize];
			self.paragraphStyle.maximumLineHeight = self.paragraphStyle.minimumLineHeight;
		}
	}
	
	NSString *marginBottom = [styles objectForKey:@"margin-bottom"];
	if (marginBottom) 
	{
		self.paragraphStyle.paragraphSpacing = [marginBottom pixelSizeOfCSSMeasureRelativeToCurrentTextSize:_fontDescriptor.pointSize];
	}
	else
	{
		NSString *webkitMarginAfter = [styles objectForKey:@"-webkit-margin-after"];
		if (webkitMarginAfter) 
		{
			self.paragraphStyle.paragraphSpacing = [webkitMarginAfter pixelSizeOfCSSMeasureRelativeToCurrentTextSize:_fontDescriptor.pointSize];
		}
	}
	NSString *fontVariantStr = [[styles objectForKey:@"font-variant"] lowercaseString];
	if (fontVariantStr)
	{
		if ([fontVariantStr isEqualToString:@"small-caps"])
		{
			_fontVariant = DTHTMLElementFontVariantSmallCaps;
		}
		else if ([fontVariantStr isEqualToString:@"inherit"])
		{
			_fontVariant = DTHTMLElementFontVariantInherit;
		}
		else
		{
			_fontVariant = DTHTMLElementFontVariantNormal;
		}
	}
	
	NSString *widthString = [styles objectForKey:@"width"];
	if (widthString && ![widthString isEqualToString:@"auto"])
	{
		_size.width = [widthString pixelSizeOfCSSMeasureRelativeToCurrentTextSize:self.fontDescriptor.pointSize];
	}
	
	NSString *heightString = [styles objectForKey:@"height"];
	if (heightString && ![heightString isEqualToString:@"auto"])
	{
		_size.height = [heightString pixelSizeOfCSSMeasureRelativeToCurrentTextSize:self.fontDescriptor.pointSize];
	}
	
	NSString *whitespaceString = [styles objectForKey:@"white-space"];
	if ([whitespaceString hasPrefix:@"pre"])
	{
		_preserveNewlines = YES;
	}
	else
	{
		_preserveNewlines = NO;
	}
	
	NSString *displayString = [styles objectForKey:@"display"];
	if (displayString)
	{
		if ([displayString isEqualToString:@"none"])
		{
			_displayStyle = DTHTMLElementDisplayStyleNone;
		}
		else if ([displayString isEqualToString:@"block"])
		{
			_displayStyle = DTHTMLElementDisplayStyleBlock;
		}
		else if ([displayString isEqualToString:@"inline"])
		{
			_displayStyle = DTHTMLElementDisplayStyleInline;
		}
		else if ([displayString isEqualToString:@"list-item"])
		{
			_displayStyle = DTHTMLElementDisplayStyleListItem;
		}
		else if ([displayString isEqualToString:@"table"])
		{
			_displayStyle = DTHTMLElementDisplayStyleTable;
		}
		else if ([verticalAlignment isEqualToString:@"inherit"])
		{
			// nothing to do
		}
	}
	
	// only works for objects!
	NSString *verticalAlignString = [styles objectForKey:@"vertical-align"];
	if (verticalAlignString)
	{
		if ([verticalAlignString isEqualToString:@"text-top"])
		{
			_textAttachmentAlignment = DTTextAttachmentVerticalAlignmentTop;
		}
		else if ([verticalAlignString isEqualToString:@"middle"])
		{
			_textAttachmentAlignment = DTTextAttachmentVerticalAlignmentCenter;
		}
		else if ([verticalAlignString isEqualToString:@"text-bottom"])
		{
			_textAttachmentAlignment = DTTextAttachmentVerticalAlignmentBottom;
		}
		else if ([verticalAlignString isEqualToString:@"baseline"])
		{
			_textAttachmentAlignment = DTTextAttachmentVerticalAlignmentBaseline;
		}
	}
	
	
	DTEdgeInsets padding = {0,0,0,0};
	
	// webkit default value
	NSString *webkitPaddingStart = [styles objectForKey:@"-webkit-padding-start"];
	
	if (webkitPaddingStart)
	{
		self.paragraphStyle.listIndent = [webkitPaddingStart pixelSizeOfCSSMeasureRelativeToCurrentTextSize:self.fontDescriptor.pointSize];
	}
	
	BOOL needsTextBlock = (_backgroundColor!=nil);
	
	NSString *paddingString = [styles objectForKey:@"padding"];
	
	if (paddingString)
	{
		// maybe it's using the short style
		NSArray *parts = [paddingString componentsSeparatedByString:@" "];
		
		if ([parts count] == 4)
		{
			padding.top = [[parts objectAtIndex:0] pixelSizeOfCSSMeasureRelativeToCurrentTextSize:self.fontDescriptor.pointSize];
			padding.right = [[parts objectAtIndex:1] pixelSizeOfCSSMeasureRelativeToCurrentTextSize:self.fontDescriptor.pointSize];
			padding.bottom = [[parts objectAtIndex:2] pixelSizeOfCSSMeasureRelativeToCurrentTextSize:self.fontDescriptor.pointSize];
			padding.left = [[parts objectAtIndex:3] pixelSizeOfCSSMeasureRelativeToCurrentTextSize:self.fontDescriptor.pointSize];
		}
		else if ([parts count] == 3)
		{
			padding.top = [[parts objectAtIndex:0] pixelSizeOfCSSMeasureRelativeToCurrentTextSize:self.fontDescriptor.pointSize];
			padding.right = [[parts objectAtIndex:1] pixelSizeOfCSSMeasureRelativeToCurrentTextSize:self.fontDescriptor.pointSize];
			padding.bottom = [[parts objectAtIndex:2] pixelSizeOfCSSMeasureRelativeToCurrentTextSize:self.fontDescriptor.pointSize];
			padding.left = padding.right;
		}
		else if ([parts count] == 2)
		{
			padding.top = [[parts objectAtIndex:0] pixelSizeOfCSSMeasureRelativeToCurrentTextSize:self.fontDescriptor.pointSize];
			padding.right = [[parts objectAtIndex:1] pixelSizeOfCSSMeasureRelativeToCurrentTextSize:self.fontDescriptor.pointSize];
			padding.bottom = padding.top;
			padding.left = padding.right;
		}
		else 
		{
			CGFloat paddingAmount = [paddingString pixelSizeOfCSSMeasureRelativeToCurrentTextSize:self.fontDescriptor.pointSize];
			padding = DTEdgeInsetsMake(paddingAmount, paddingAmount, paddingAmount, paddingAmount);
		}
		
		// left padding overrides webkit list indent
		self.paragraphStyle.listIndent = padding.left;
		
		needsTextBlock = YES;
	}
	else
	{
		paddingString = [styles objectForKey:@"padding-left"];
		
		if (paddingString)
		{
			padding.left = [paddingString pixelSizeOfCSSMeasureRelativeToCurrentTextSize:self.fontDescriptor.pointSize];
			needsTextBlock = YES;
			
			// left padding overrides webkit list indent
			self.paragraphStyle.listIndent = padding.left;
		}
		
		paddingString = [styles objectForKey:@"padding-top"];
		
		if (paddingString)
		{
			padding.top = [paddingString pixelSizeOfCSSMeasureRelativeToCurrentTextSize:self.fontDescriptor.pointSize];
			needsTextBlock = YES;
		}
		
		paddingString = [styles objectForKey:@"padding-right"];
		
		if (paddingString)
		{
			padding.right = [paddingString pixelSizeOfCSSMeasureRelativeToCurrentTextSize:self.fontDescriptor.pointSize];
			needsTextBlock = YES;
		}
		
		paddingString = [styles objectForKey:@"padding-bottom"];
		
		if (paddingString)
		{
			padding.bottom = [paddingString pixelSizeOfCSSMeasureRelativeToCurrentTextSize:self.fontDescriptor.pointSize];
			needsTextBlock = YES;
		}
	}
	
	if (_displayStyle == DTHTMLElementDisplayStyleBlock)
	{
		if (needsTextBlock)
		{
			// need a block
			DTTextBlock *newBlock = [[DTTextBlock alloc] init];
			
			newBlock.padding = padding;
			
			// transfer background color to block
			newBlock.backgroundColor = _backgroundColor;
			_backgroundColor = nil;
			
			NSArray *newBlocks = [self.paragraphStyle.textBlocks mutableCopy];
			
			if (!newBlocks)
			{
				// need an array, this is the first block
				newBlocks = [NSArray arrayWithObject:newBlock];
			}
			
			self.paragraphStyle.textBlocks = newBlocks;
		}
	}
}

- (NSDictionary *)styles
{
	return _styles;
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
	child.parent = nil;
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
	if (!_parent || !_parent.tagName) // default tag has no tag name
	{
		return NO;
	}
	
	if (self.parent.displayStyle == DTHTMLElementDisplayStyleInline)
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
	if (!value && _parent)
	{
		return [_parent valueForKeyPathWithInheritance:keyPath];
	}
	
	// enum properties have 0 for inherit
	if ([value isKindOfClass:[NSNumber class]])
	{
		NSNumber *number = value;
		
		if (([number integerValue]==0) && _parent)
		{
			return [_parent valueForKeyPathWithInheritance:keyPath];
		}
	}
	
	// string properties have 'inherit' for inheriting
	if ([value isKindOfClass:[NSString class]])
	{
		NSString *string = value;
		
		if ([string isEqualToString:@"inherit"] && _parent)
		{
			return [_parent valueForKeyPathWithInheritance:keyPath];
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
	
	newObject.strikeOut = self.strikeOut;
	newObject.superscriptStyle = self.superscriptStyle;
	newObject.shadows = self.shadows;
	
	newObject.link = self.link; // copy
	newObject.anchorName = self.anchorName; // copy
	newObject.linkGUID = _linkGUID; // transfer the GUID
	
	newObject.preserveNewlines = self.preserveNewlines;
	
	newObject.fontCache = self.fontCache; // reference
	
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

- (void)setTextColor:(DTColor *)textColor
{
	if (_textColor != textColor)
	{
		
		_textColor = textColor;
		_isColorInherited = NO;
	}
}

- (DTHTMLElementFontVariant)fontVariant
{
	if (_fontVariant == DTHTMLElementFontVariantInherit)
	{
		if (_parent)
		{
			return _parent.fontVariant;
		}
		
		return DTHTMLElementFontVariantNormal;
	}
	
	return _fontVariant;
}

- (NSString *)path
{
	if (_parent)
	{
		return [[_parent path] stringByAppendingFormat:@"/%@", self.tagName];
	}
	
	if (_tagName)
	{
		return _tagName;
	}
	
	return @"root";
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
		_size = CGSizeMake([[self attributeForKey:@"width"] floatValue], [[self attributeForKey:@"height"] floatValue]); 
	}
}

- (void)setTextAttachment:(DTTextAttachment *)textAttachment
{
	textAttachment.verticalAlignment = _textAttachmentAlignment;
	_textAttachment = textAttachment;
	
	// transfer link GUID
	_textAttachment.hyperLinkGUID = _linkGUID;
}

- (void)setLink:(NSURL *)link
{
	_linkGUID = [NSString guid];
	_link = [link copy];
	
	if (_textAttachment)
	{
		_textAttachment.hyperLinkGUID = _linkGUID;
	}
}

@synthesize parent = _parent;
@synthesize fontDescriptor = _fontDescriptor;
@synthesize paragraphStyle = _paragraphStyle;
@synthesize textColor = _textColor;
@synthesize backgroundColor = _backgroundColor;
@synthesize tagName = _tagName;
@synthesize beforeContent = _beforeContent;
@synthesize text = _text;
@synthesize link = _link;
@synthesize anchorName = _anchorName;
@synthesize underlineStyle = _underlineStyle;
@synthesize textAttachment = _textAttachment;
@synthesize tagContentInvisible = _tagContentInvisible;
@synthesize strikeOut = _strikeOut;
@synthesize superscriptStyle = _superscriptStyle;
@synthesize headerLevel = _headerLevel;
@synthesize shadows = _shadows;
@synthesize floatStyle = _floatStyle;
@synthesize isColorInherited = _isColorInherited;
@synthesize preserveNewlines = _preserveNewlines;
@synthesize displayStyle = _displayStyle;
@synthesize fontVariant = _fontVariant;
@synthesize textScale = _textScale;
@synthesize size = _size;

@synthesize fontCache = _fontCache;
@synthesize children = _children;
@synthesize attributes = _attributes;
@synthesize linkGUID = _linkGUID;

@end


