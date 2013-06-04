//
//  DTHTMLElement.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 4/14/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCoreText.h"
#import "DTHTMLElement.h"
#import "DTAnchorHTMLElement.h"
#import "DTTextAttachmentHTMLElement.h"
#import "DTBreakHTMLElement.h"
#import "DTHorizontalRuleHTMLElement.h"
#import "DTListItemHTMLElement.h"
#import "DTStylesheetHTMLElement.h"
#import "DTTextHTMLElement.h"
#import "NSString+DTUtilities.h"

@interface DTHTMLElement ()

@property (nonatomic, strong) NSMutableDictionary *fontCache;
@property (nonatomic, strong) NSString *linkGUID;

- (DTCSSListStyle *)calculatedListStyle;

// internal initializer
- (id)initWithName:(NSString *)name attributes:(NSDictionary *)attributes options:(NSDictionary *)options;

@end

BOOL ___shouldUseiOS6Attributes = NO;

NSDictionary *_classesForNames = nil;

@implementation DTHTMLElement

+ (void)initialize
{
	// prevent calling from children
	if (self != [DTHTMLElement class])
	{
		return;
	}
	
	// lookup table so that we quickly get the correct class to instantiate for special tags
	NSMutableDictionary *tmpDict = [[NSMutableDictionary alloc] init];
	
	[tmpDict setObject:[DTAnchorHTMLElement class] forKey:@"a"];
	[tmpDict setObject:[DTBreakHTMLElement class] forKey:@"br"];
	[tmpDict setObject:[DTHorizontalRuleHTMLElement class] forKey:@"hr"];
	[tmpDict setObject:[DTListItemHTMLElement class] forKey:@"li"];
	[tmpDict setObject:[DTStylesheetHTMLElement class] forKey:@"style"];
	[tmpDict setObject:[DTTextAttachmentHTMLElement class] forKey:@"img"];
	[tmpDict setObject:[DTTextAttachmentHTMLElement class] forKey:@"object"];
	[tmpDict setObject:[DTTextAttachmentHTMLElement class] forKey:@"video"];
	[tmpDict setObject:[DTTextAttachmentHTMLElement class] forKey:@"iframe"];
	
	_classesForNames = [tmpDict copy];
}

+ (DTHTMLElement *)elementWithName:(NSString *)name attributes:(NSDictionary *)attributes options:(NSDictionary *)options
{
	// look for specialized class
	Class class = [_classesForNames objectForKey:name];

	if (!class)
	{
		// see if this is a custom attachment class
		Class attachmentClass = [DTTextAttachment registeredClassForTagName:name];
		
		if (attachmentClass)
		{
			class = [DTTextAttachmentHTMLElement class];
		}
		else
		{
			// use generic of none found
			class = [DTHTMLElement class];
		}
	}
	
	DTHTMLElement *element = [[class alloc] initWithName:name attributes:attributes options:options];
	
	return element;
}

- (id)initWithName:(NSString *)name attributes:(NSDictionary *)attributes options:(NSDictionary *)options
{
	// node does not need the options, but it needs the name and attributes
	self = [super initWithName:name attributes:attributes];
	if (self)
	{
	}
	
	return self;
}

- (NSDictionary *)attributesDictionary
{
	NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
	
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
	}
	
	CTFontRef font = [_fontDescriptor newMatchingFont];
	
	if (font)
	{
#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES && __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_5_1
		if (___useiOS6Attributes)
		{
			UIFont *uiFont = [UIFont fontWithCTFont:font];
			[tmpDict setObject:uiFont forKey:NSFontAttributeName];
		}
		else
#endif
		{
			// __bridge since its already retained elsewhere
			[tmpDict setObject:(__bridge id)(font) forKey:(id)kCTFontAttributeName];
		}
		
		
		// use this font to adjust the values needed for the run delegate during layout time
		[_textAttachment adjustVerticalAlignmentForFont:font];
		
		CFRelease(font);
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
#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES
		if (___useiOS6Attributes)
		{
			[tmpDict setObject:[NSNumber numberWithInteger:NSUnderlineStyleSingle] forKey:NSStrikethroughStyleAttributeName];
		}
		else
#endif
		{
			[tmpDict setObject:[NSNumber numberWithBool:YES] forKey:DTStrikeOutAttribute];
		}
	}
	
	// set underline style
	if (_underlineStyle)
	{
#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES
		if (___useiOS6Attributes)
		{
			[tmpDict setObject:[NSNumber numberWithInteger:NSUnderlineStyleSingle] forKey:NSUnderlineStyleAttributeName];
		}
		else
#endif
		{
			[tmpDict setObject:[NSNumber numberWithInteger:_underlineStyle] forKey:(id)kCTUnderlineStyleAttributeName];
		}
		
		// we could set an underline color as well if we wanted, but not supported by HTML
		//      [attributes setObject:(id)[DTImage redColor].CGColor forKey:(id)kCTUnderlineColorAttributeName];
	}
	
	if (_textColor)
	{
#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES
		if (___useiOS6Attributes)
		{
			[tmpDict setObject:_textColor forKey:NSForegroundColorAttributeName];
		}
		else
#endif
		{
			[tmpDict setObject:(id)[_textColor CGColor] forKey:(id)kCTForegroundColorAttributeName];
		}
	}
	
	if (_backgroundColor)
	{
#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES
		if (___useiOS6Attributes)
		{
			[tmpDict setObject:_backgroundColor forKey:NSBackgroundColorAttributeName];
		}
		else
#endif
		{
			[tmpDict setObject:(id)[_backgroundColor CGColor] forKey:DTBackgroundColorAttribute];
		}
	}
	
	if (_superscriptStyle)
	{
		[tmpDict setObject:(id)[NSNumber numberWithInteger:_superscriptStyle] forKey:(id)kCTSuperscriptAttributeName];
	}
	
	// add paragraph style
	if (_paragraphStyle)
	{
#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES
		if (___useiOS6Attributes)
		{
			NSParagraphStyle *style = [self.paragraphStyle NSParagraphStyle];
			[tmpDict setObject:style forKey:NSParagraphStyleAttributeName];
		}
		else
#endif
		{
			CTParagraphStyleRef newParagraphStyle = [self.paragraphStyle createCTParagraphStyle];
			[tmpDict setObject:CFBridgingRelease(newParagraphStyle) forKey:(id)kCTParagraphStyleAttributeName];
		}
	}
	
	// add shadow array if applicable
	if (_shadows)
	{
#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES
		if (___useiOS6Attributes)
		{
			// only a single shadow supported
			NSDictionary *firstShadow = [_shadows objectAtIndex:0];
			
			NSShadow *shadow = [[NSShadow alloc] init];
			shadow.shadowOffset = [[firstShadow objectForKey:@"Offset"] CGSizeValue];
			shadow.shadowColor = [firstShadow objectForKey:@"Color"];
			shadow.shadowBlurRadius = [[firstShadow objectForKey:@"Blur"] floatValue];
			[tmpDict setObject:shadow forKey:NSShadowAttributeName];
		}
		else
#endif
		{
			[tmpDict setObject:_shadows forKey:DTShadowsAttribute];
		}
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

- (BOOL)needsOutput
{
	@synchronized(self)
	{
		if ([self.childNodes count])
		{
			for (DTHTMLElement *oneChild in self.childNodes)
			{
				if (!oneChild.didOutput)
				{
					return YES;
				}
			}
			
			return NO;
		}
		
		return YES;
	}
}

- (BOOL)_isNotChildOfList
{
	DTHTMLElement *parent = self.parentElement;
	
	if (parent.displayStyle == DTHTMLElementDisplayStyleListItem)
	{
		return NO;
	}
	
	if (parent.displayStyle == DTHTMLElementDisplayStyleBlock)
	{
		if ([parent.name isEqualToString:@"ol"] || [parent.name isEqualToString:@"ul"])
		{
			return NO;
		}
	}
	
	return YES;
}

- (NSAttributedString *)attributedString
{
	@synchronized(self)
	{
		if (_displayStyle == DTHTMLElementDisplayStyleNone || self.didOutput)
		{
			return nil;
		}
		
		NSDictionary *attributes = [self attributesDictionary];
		
		NSMutableAttributedString *tmpString;
		
		if (_textAttachment)
		{
			// ignore text, use unicode object placeholder
			tmpString = [[NSMutableAttributedString alloc] initWithString:UNICODE_OBJECT_PLACEHOLDER attributes:attributes];
		}
		else
		{
			// walk through children
			tmpString = [[NSMutableAttributedString alloc] init];
			
			DTHTMLElement *previousChild = nil;
			
			for (DTHTMLElement *oneChild in self.childNodes)
			{
				// if previous node was inline and this child is block then we need a newline
				if (previousChild && previousChild.displayStyle == DTHTMLElementDisplayStyleInline)
				{
					if (oneChild.displayStyle == DTHTMLElementDisplayStyleBlock)
					{
						// trim off whitespace suffix
						while ([[tmpString string] hasSuffixCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]])
						{
							[tmpString deleteCharactersInRange:NSMakeRange([tmpString length]-1, 1)];
						}
						
						// paragraph break
						[tmpString appendString:@"\n"];
					}
				}
				
				NSAttributedString *nodeString = [oneChild attributedString];
				
				if (nodeString)
				{
					if (!oneChild.containsAppleConvertedSpace)
					{
						// we already have a white space in the string so far
						if ([[tmpString string] hasSuffixCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]])
						{
							while ([[nodeString string] hasPrefix:@" "])
							{
								nodeString = [nodeString attributedSubstringFromRange:NSMakeRange(1, [nodeString length]-1)];
							}
						}
					}
					
					[tmpString appendAttributedString:nodeString];
				}
				
				previousChild = oneChild;
			}
		}
		
		// block-level elements get space trimmed and a newline
		if (_displayStyle != DTHTMLElementDisplayStyleInline)
		{
			// trim off whitespace prefix
			while ([[tmpString string] hasPrefix:@" "])
			{
				[tmpString deleteCharactersInRange:NSMakeRange(0, 1)];
			}
			
			// trim off whitespace suffix
			while ([[tmpString string] hasSuffix:@" "])
			{
				[tmpString deleteCharactersInRange:NSMakeRange([tmpString length]-1, 1)];
			}
			
			if (![self.name isEqualToString:@"html"] && ![self.name isEqualToString:@"body"])
			{
				if (![[tmpString string] hasSuffix:@"\n"])
				{
					NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:@"\n" attributes:[self attributesDictionary]];
					[tmpString appendAttributedString:attributedString];
				}
			}
		}
		
		// make sure the last sub-paragraph of this has no less than the specified paragraph spacing of this element
		// e.g. last LI needs to inherit the margin-after of the UL
		if (self.displayStyle == DTHTMLElementDisplayStyleBlock && [tmpString length]>0)
		{
			
			// if this is latest
			if ([self _isNotChildOfList])
			{
				NSRange paragraphRange = [[tmpString string] rangeOfParagraphAtIndex:[tmpString length]-1];
				
#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES
				if (___useiOS6Attributes)
				{
					NSParagraphStyle *paraStyle = [tmpString attribute:NSParagraphStyleAttributeName atIndex:paragraphRange.location effectiveRange:NULL];
					
					DTCoreTextParagraphStyle *paragraphStyle = [DTCoreTextParagraphStyle paragraphStyleWithNSParagraphStyle:paraStyle];
					
					if (paragraphStyle.paragraphSpacing < self.paragraphStyle.paragraphSpacing)
					{
						paragraphStyle.paragraphSpacing = self.paragraphStyle.paragraphSpacing;
						
						// make new paragraph style
						NSParagraphStyle *newParaStyle = [paragraphStyle NSParagraphStyle];
						
						// remove old (works around iOS 4.3 leak)
						[tmpString removeAttribute:NSParagraphStyleAttributeName range:paragraphRange];
						
						// set new
						[tmpString addAttribute:NSParagraphStyleAttributeName value:newParaStyle range:paragraphRange];
					}
				}
				else
#endif
				{
					CTParagraphStyleRef paraStyle = (__bridge CTParagraphStyleRef)[tmpString attribute:(id)kCTParagraphStyleAttributeName atIndex:paragraphRange.location effectiveRange:NULL];
					
					DTCoreTextParagraphStyle *paragraphStyle = [DTCoreTextParagraphStyle paragraphStyleWithCTParagraphStyle:paraStyle];
					
					if (paragraphStyle.paragraphSpacing < self.paragraphStyle.paragraphSpacing)
					{
						paragraphStyle.paragraphSpacing = self.paragraphStyle.paragraphSpacing;
						
						// make new paragraph style
						CTParagraphStyleRef newParaStyle = [paragraphStyle createCTParagraphStyle];
						
						// remove old (works around iOS 4.3 leak)
						[tmpString removeAttribute:(id)kCTParagraphStyleAttributeName range:paragraphRange];
						
						// set new
						[tmpString addAttribute:(id)kCTParagraphStyleAttributeName value:(__bridge_transfer id)newParaStyle range:paragraphRange];
					}
				}
			}
		}
		
		return tmpString;
	}
}

- (DTHTMLElement *)parentElement
{
	return (DTHTMLElement *)self.parentNode;
}


// decodes the edgeInsets for padding or margin
- (BOOL)_parseEdgeInsetsFromStyleDictionary:(NSDictionary *)styles forAttributesWithPrefix:(NSString *)prefix writingDirection:(CTWritingDirection)writingDirection intoEdgeInsets:(DTEdgeInsets *)intoEdgeInsets
{
	DTEdgeInsets edgeInsets = {0,0,0,0};
	
	BOOL didModify = NO;
	
	if (![styles count])
	{
		return didModify;
	}
	
	BOOL isWebKitAttribute = NO;
	
	if ([prefix hasPrefix:@"-webkit"])
	{
		isWebKitAttribute = YES;
	}
	
	NSString *leftKey = @"-left";
	
	if (isWebKitAttribute)
	{
		if (writingDirection==kCTWritingDirectionRightToLeft)
		{
			// RTL
			leftKey = @"-end";
		}
		else
		{
			// LTR
			leftKey = @"-start";
		}
	}
	
	NSString *rightKey = @"-right";
	
	if (isWebKitAttribute)
	{
		if (writingDirection==kCTWritingDirectionRightToLeft)
		{
			// RTL
			rightKey = @"-start";
		}
		else
		{
			// LTR
			rightKey = @"-end";
		}
	}
	
	NSString *topKey = isWebKitAttribute?@"-before":@"-top";
	NSString *bottomKey = isWebKitAttribute?@"-after":@"-bottom";
	
	for (NSString *oneKey in styles)
	{
		if (![oneKey hasPrefix:prefix])
		{
			continue;
		}
		
		NSString *attributeValue = [styles objectForKey:oneKey];
		
		NSRange dashRange = [oneKey rangeOfString:@"-"];
		
		if (dashRange.length)
		{
			if ([oneKey hasSuffix:leftKey])
			{
				edgeInsets.left = [attributeValue pixelSizeOfCSSMeasureRelativeToCurrentTextSize:self.fontDescriptor.pointSize textScale:_textScale];
				didModify = YES;
			}
			else if ([oneKey hasSuffix:bottomKey])
			{
				edgeInsets.bottom = [attributeValue	pixelSizeOfCSSMeasureRelativeToCurrentTextSize:self.fontDescriptor.pointSize textScale:_textScale];
				didModify = YES;
			}
			else if ([oneKey hasSuffix:rightKey])
			{
				edgeInsets.right = [attributeValue pixelSizeOfCSSMeasureRelativeToCurrentTextSize:self.fontDescriptor.pointSize textScale:_textScale];
				didModify = YES;
			}
			else if ([oneKey hasSuffix:topKey])
			{
				edgeInsets.top = [attributeValue pixelSizeOfCSSMeasureRelativeToCurrentTextSize:self.fontDescriptor.pointSize textScale:_textScale];
				didModify = YES;
			}
		}
		else
		{
			// shortcut with multiple values
			edgeInsets = [attributeValue DTEdgeInsetsRelativeToCurrentTextSize:self.fontDescriptor.pointSize textScale:_textScale];
			didModify = YES;
		}
	}
	
	if (didModify && intoEdgeInsets)
	{
		*intoEdgeInsets = edgeInsets;
	}
	
	return didModify;
}

- (void)applyStyleDictionary:(NSDictionary *)styles
{
	if (![styles count])
	{
		return;
	}
	
	// keep that for later lookup
	_styles = styles;
	
	// writing direction
	NSString *directionStr = [_styles objectForKey:@"direction"];
	
	if (directionStr)
	{
		if ([directionStr isEqualToString:@"rtl"])
		{
			_paragraphStyle.baseWritingDirection = NSWritingDirectionRightToLeft;
		}
		else if ([directionStr isEqualToString:@"ltr"])
		{
			_paragraphStyle.baseWritingDirection = NSWritingDirectionLeftToRight;
		}
		else if ([directionStr isEqualToString:@"auto"])
		{
			_paragraphStyle.baseWritingDirection = NSWritingDirectionNatural; // that's also default
		}
		else
		{
			// other values are invalid and will be ignored
		}
	}
	
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
			_fontDescriptor.pointSize = 9.0f * _textScale;
		}
		else if ([fontSize isEqualToString:@"x-small"])
		{
			_fontDescriptor.pointSize = 10.0f * _textScale;
		}
		else if ([fontSize isEqualToString:@"small"])
		{
			_fontDescriptor.pointSize = 13.0f * _textScale;
		}
		else if ([fontSize isEqualToString:@"medium"])
		{
			_fontDescriptor.pointSize = 16.0f * _textScale;
		}
		else if ([fontSize isEqualToString:@"large"])
		{
			_fontDescriptor.pointSize = 18.0f * _textScale;
		}
		else if ([fontSize isEqualToString:@"x-large"])
		{
			_fontDescriptor.pointSize = 24.0f * _textScale;
		}
		else if ([fontSize isEqualToString:@"xx-large"])
		{
			_fontDescriptor.pointSize = 32.0f * _textScale;
		}
		else if ([fontSize isEqualToString:@"-webkit-xxx-large"])
		{
			_fontDescriptor.pointSize = 48.0f * _textScale;
		}
		else if ([fontSize isEqualToString:@"inherit"])
		{
			_fontDescriptor.pointSize = self.parentElement.fontDescriptor.pointSize;
		}
		else if ([fontSize isCSSLengthValue])
		{
			CGFloat fontSizeValue = [fontSize pixelSizeOfCSSMeasureRelativeToCurrentTextSize:_fontDescriptor.pointSize textScale:_textScale];
			_fontDescriptor.pointSize = fontSizeValue;
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
		else if ([lowercaseFontFamily isEqualToString:@"inherit"])
		{
			_fontDescriptor.fontFamily = self.parentElement.fontDescriptor.fontFamily;
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
		else if ([verticalAlignment isEqualToString:@"text-top"])
		{
			_textAttachmentAlignment = DTTextAttachmentVerticalAlignmentTop;
		}
		else if ([verticalAlignment isEqualToString:@"middle"])
		{
			_textAttachmentAlignment = DTTextAttachmentVerticalAlignmentCenter;
		}
		else if ([verticalAlignment isEqualToString:@"text-bottom"])
		{
			_textAttachmentAlignment = DTTextAttachmentVerticalAlignmentBottom;
		}
		else if ([verticalAlignment isEqualToString:@"baseline"])
		{
			_textAttachmentAlignment = DTTextAttachmentVerticalAlignmentBaseline;
		}
	}
	
	// if there is a text attachment we transfer the aligment we got
	_textAttachment.verticalAlignment = _textAttachmentAlignment;
	
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
			CGFloat lineHeightValue = [lineHeight pixelSizeOfCSSMeasureRelativeToCurrentTextSize:_fontDescriptor.pointSize textScale:_textScale];
			self.paragraphStyle.minimumLineHeight = lineHeightValue;
			self.paragraphStyle.maximumLineHeight = lineHeightValue;
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
		_size.width = [widthString pixelSizeOfCSSMeasureRelativeToCurrentTextSize:self.fontDescriptor.pointSize textScale:_textScale];
	}
	
	NSString *heightString = [styles objectForKey:@"height"];
	if (heightString && ![heightString isEqualToString:@"auto"])
	{
		_size.height = [heightString pixelSizeOfCSSMeasureRelativeToCurrentTextSize:self.fontDescriptor.pointSize textScale:_textScale];
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
	
	BOOL needsTextBlock = (_backgroundColor!=nil);
	
	BOOL hasMargins = NO;
	
	NSString *allKeys = [[styles allKeys] componentsJoinedByString:@";"];
	
	// there can only be padding if the word "margin" occurs in the styles keys
	if ([allKeys rangeOfString:@"-webkit-margin"].length)
	{
		hasMargins = ([self _parseEdgeInsetsFromStyleDictionary:styles forAttributesWithPrefix:@"-webkit-margin" writingDirection:self.paragraphStyle.baseWritingDirection intoEdgeInsets:&_margins] || hasMargins);
	}
	
	if ([allKeys rangeOfString:@"margin"].length)
	{
		hasMargins = ([self _parseEdgeInsetsFromStyleDictionary:styles forAttributesWithPrefix:@"margin" writingDirection:self.paragraphStyle.baseWritingDirection intoEdgeInsets:&_margins] || hasMargins);
	}
	
	BOOL hasPadding = NO;
	
	// there can only be padding if the word "padding" occurs in the styles keys
	if ([allKeys rangeOfString:@"-webkit-padding"].length)
	{
		hasPadding = ([self _parseEdgeInsetsFromStyleDictionary:styles forAttributesWithPrefix:@"-webkit-padding" writingDirection:self.paragraphStyle.baseWritingDirection intoEdgeInsets:&_padding] || hasPadding);
	}
	
	if ([allKeys rangeOfString:@"padding"].length)
	{
		
		hasPadding = ([self _parseEdgeInsetsFromStyleDictionary:styles forAttributesWithPrefix:@"padding" writingDirection:self.paragraphStyle.baseWritingDirection intoEdgeInsets:&_padding] || hasPadding);
	}
	
	if (hasPadding)
	{
		// FIXME: this is a workaround because having a text block padding in addition to list ident messes up indenting of the list
		if ([self.name isEqualToString:@"ul"] || [self.name isEqualToString:@"ol"])
		{
			_listIndent = _padding.left;
			_padding.left = 0;
		}
		
		// if we still have padding we need a block
		if (_padding.left>0 || _padding.right>0 || _padding.top>0 || _padding.bottom>0)
		{
			needsTextBlock = YES;
		}
	}
	
	if (_displayStyle == DTHTMLElementDisplayStyleBlock)
	{
		// we only care for margins of block level elements
		if (hasMargins)
		{
			self.paragraphStyle.paragraphSpacing = _margins.bottom;
			
			// we increase the inherited values for the time being
			// TODO: it would be preferred to calculate these from the margins values of the parent elements
			self.paragraphStyle.headIndent += _margins.left;
			self.paragraphStyle.firstLineHeadIndent = self.paragraphStyle.headIndent;
			
			// tailIndent from right side is negative
			self.paragraphStyle.tailIndent -= _margins.right;
		}
		
		if (needsTextBlock)
		{
			// need a block
			DTTextBlock *newBlock = [[DTTextBlock alloc] init];
			
			newBlock.padding = _padding;
			
			// transfer background color to block
			newBlock.backgroundColor = _backgroundColor;
			_backgroundColor = nil;
			
			NSMutableArray *blocks = [self.paragraphStyle.textBlocks mutableCopy];
			
			if (blocks)
			{
				// add new block to the array
				[blocks addObject:newBlock];
			}
			else
			{
				// didn't have any blocks before, start new array
				blocks = [NSArray arrayWithObject:newBlock];
			}
			
			self.paragraphStyle.textBlocks = blocks;
		}
	}
	else if (_displayStyle == DTHTMLElementDisplayStyleListItem)
	{
		self.paragraphStyle.paragraphSpacing = _margins.bottom;
	}
}

- (DTCSSListStyle *)listStyle
{
	DTCSSListStyle *style = [[DTCSSListStyle alloc] initWithStyles:_styles];
	
	NSString *startingIndex = [_attributes objectForKey:@"start"];
	
	// set the starting index if there is one specified
	if (startingIndex)
	{
		style.startingItemNumber = [startingIndex integerValue];
	}
	
	return style;
}

- (void)addAdditionalAttribute:(id)attribute forKey:(id)key
{
	if (!_additionalAttributes)
	{
		_additionalAttributes = [[NSMutableDictionary alloc] init];
	}
	
	[_additionalAttributes setObject:attribute forKey:key];
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
	if (!value && self.parentElement)
	{
		return [self.parentElement valueForKeyPathWithInheritance:keyPath];
	}
	
	// enum properties have 0 for inherit
	if ([value isKindOfClass:[NSNumber class]])
	{
		NSNumber *number = value;
		
		if (([number integerValue]==0) && self.parentElement)
		{
			return [self.parentElement valueForKeyPathWithInheritance:keyPath];
		}
	}
	
	// string properties have 'inherit' for inheriting
	if ([value isKindOfClass:[NSString class]])
	{
		NSString *string = value;
		
		if ([string isEqualToString:@"inherit"] && self.parentElement)
		{
			return [self.parentElement valueForKeyPathWithInheritance:keyPath];
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

#pragma mark - Inheriting Attributes

- (void)inheritAttributesFromElement:(DTHTMLElement *)element
{
	_fontDescriptor = [element.fontDescriptor copy];
	_paragraphStyle = [element.paragraphStyle copy];

	_headerLevel = element.headerLevel;

	_fontVariant = element.fontVariant;
	_underlineStyle = element.underlineStyle;
	_strikeOut = element.strikeOut;
	_superscriptStyle = element.superscriptStyle;
	
	_shadows = [element.shadows copy];
	
	_link = [element.link copy];
	_anchorName = [element.anchorName copy];
	_linkGUID = element.linkGUID;
	
	_textColor = element.textColor;
	_isColorInherited = YES;
	
	_preserveNewlines = element.preserveNewlines;
	_textScale = element.textScale;
	
	// only inherit background-color from inline elements
	if (element.displayStyle == DTHTMLElementDisplayStyleInline)
	{
		self.backgroundColor = element.backgroundColor;
	}
	
	_containsAppleConvertedSpace = element.containsAppleConvertedSpace;
	
	// we copy the link because we might need for it making the custom view
	_textAttachment.hyperLinkURL = element.link;
}

- (void)interpretAttributes
{
	if (!_attributes)
	{
		// nothing to interpret
		return;
	}
	
	// transfer Apple Converted Space tag
	if ([[self attributeForKey:@"class"] isEqualToString:@"Apple-converted-space"])
	{
		_containsAppleConvertedSpace = YES;
	}
	
	// detect writing direction if set
	NSString *directionStr = [self attributeForKey:@"dir"];
	
	if (directionStr)
	{
		NSAssert(_paragraphStyle, @"Found dir attribute, but missing paragraph style on element");
		
		if ([directionStr isEqualToString:@"rtl"])
		{
			_paragraphStyle.baseWritingDirection = NSWritingDirectionRightToLeft;
		}
		else if ([directionStr isEqualToString:@"ltr"])
		{
			_paragraphStyle.baseWritingDirection = NSWritingDirectionLeftToRight;
		}
		else if ([directionStr isEqualToString:@"auto"])
		{
			_paragraphStyle.baseWritingDirection = NSWritingDirectionNatural; // that's also default
		}
		else
		{
			// other values are invalid and will be ignored
		}
	}

	// handles align="justify"
	NSString *align = [self attributeForKey:@"align"];

	if (align)
	{
		if ([align isEqualToString: @"justify"])
		{
			_paragraphStyle.alignment = kCTTextAlignmentJustified;
		}
		else if ([align isEqualToString: @"left"])
		{
			_paragraphStyle.alignment = kCTTextAlignmentLeft;
		}
		else if ([align isEqualToString: @"center"])
		{
			_paragraphStyle.alignment = kCTTextAlignmentCenter;
		}
		else if ([align isEqualToString: @"right"])
		{
			_paragraphStyle.alignment = kCTTextAlignmentRight;
		}
	}
}

#pragma mark Properties

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
		if (self.parentElement)
		{
			return self.parentElement.fontVariant;
		}
		
		return DTHTMLElementFontVariantNormal;
	}
	
	return _fontVariant;
}

- (void)setAttributes:(NSDictionary *)attributes
{
	[super setAttributes:[attributes copy]];
	
	// decode size contained in attributes, might be overridden later by CSS size
	_size = CGSizeMake([[self attributeForKey:@"width"] floatValue], [[self attributeForKey:@"height"] floatValue]);
}

- (void)setTextAttachment:(DTTextAttachment *)textAttachment
{
	textAttachment.verticalAlignment = _textAttachmentAlignment;
	_textAttachment = textAttachment;
	
	// transfer link GUID
	_textAttachment.hyperLinkGUID = _linkGUID;
	
	// transfer size
	_textAttachment.displaySize = _size;
}

- (void)setLink:(NSURL *)link
{
	_linkGUID = [NSString stringWithUUID];
	_link = [link copy];
	
	if (_textAttachment)
	{
		_textAttachment.hyperLinkGUID = _linkGUID;
	}
}

- (void)setDidOutput:(BOOL)didOutput
{
	@synchronized(self)
	{
		_didOutput = didOutput;
	}
}

- (BOOL)didOutput
{
	@synchronized(self)
	{
		return _didOutput;
	}
}

@synthesize fontDescriptor = _fontDescriptor;
@synthesize paragraphStyle = _paragraphStyle;
@synthesize textColor = _textColor;
@synthesize backgroundColor = _backgroundColor;
@synthesize beforeContent = _beforeContent;
@synthesize link = _link;
@synthesize anchorName = _anchorName;
@synthesize underlineStyle = _underlineStyle;
@synthesize textAttachment = _textAttachment;
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
@synthesize margins = _margins;
@synthesize padding = _padding;
@synthesize linkGUID = _linkGUID;
@synthesize containsAppleConvertedSpace = _containsAppleConvertedSpace;

@end


