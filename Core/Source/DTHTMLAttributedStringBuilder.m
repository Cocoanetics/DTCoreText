//
//  DTHTMLAttributedStringBuilder.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 21.01.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import <DTFoundation/DTLog.h>
#import <DTFoundation/DTHTMLParser.h>
#import <DTFoundation/NSString+DTURLEncoding.h>

#import "DTHTMLAttributedStringBuilder.h"

#import "DTTextHTMLElement.h"
#import "DTBreakHTMLElement.h"
#import "DTStylesheetHTMLElement.h"
#import "DTCSSStylesheet.h"
#import "DTCoreTextFontDescriptor.h"
#import "DTHTMLParserTextNode.h"

#import "DTTextAttachmentHTMLElement.h"
#import "DTColorFunctions.h"
#import "DTCoreTextParagraphStyle.h"
#import "DTObjectTextAttachment.h"
#import "DTVideoTextAttachment.h"

#import "NSString+HTML.h"
#import "NSCharacterSet+HTML.h"
#import "NSMutableAttributedString+HTML.h"

#if DEBUG_LOG_METRICS
#import "NSString+DTFormatNumbers.h"
#endif

@interface DTHTMLAttributedStringBuilder ()

- (void)_registerTagStartHandlers;
- (void)_registerTagEndHandlers;

@end


@implementation DTHTMLAttributedStringBuilder
{
	NSData *_data;
	NSDictionary *_options;
	BOOL _shouldKeepDocumentNodeTree;
	
	// settings for parsing
	CGFloat _textScale;
	DTColor *_defaultLinkColor;
	DTCSSStylesheet *_globalStyleSheet;
	NSURL *_baseURL;
	DTCoreTextFontDescriptor *_defaultFontDescriptor;
	DTCoreTextParagraphStyle *_defaultParagraphStyle;
	
	// root node inherits these defaults
	DTHTMLElement *_defaultTag;
	
	// parsing state, accessed from inside blocks
	NSMutableAttributedString *_tmpString;
	
	// GCD
	dispatch_queue_t _stringAssemblyQueue;
	dispatch_group_t _stringAssemblyGroup;
	dispatch_queue_t _dataParsingQueue;
	dispatch_group_t _dataParsingGroup;
	dispatch_queue_t _treeBuildingQueue;
	dispatch_group_t _treeBuildingGroup;
	
	// lookup table for blocks that deal with begin and end tags
	NSMutableDictionary *_tagStartHandlers;
	NSMutableDictionary *_tagEndHandlers;
	
	DTHTMLAttributedStringBuilderWillFlushCallback _willFlushCallback;
	DTHTMLAttributedStringBuilderParseErrorCallback _parseErrorCallback;

	BOOL _shouldProcessCustomHTMLAttributes;
	
	// new parsing
	DTHTMLElement *_rootNode;
	DTHTMLElement *_bodyElement;
	DTHTMLElement *_currentTag;
	BOOL _ignoreParseEvents; // ignores events from parser after first HTML tag was finished
	BOOL _ignoreInlineStyles; // ignores style blocks attached on elements
	BOOL _preserverDocumentTrailingSpaces; // don't remove spaces at end of document
	
	DTHTMLParser  *_parser;
}

- (id)initWithHTML:(NSData *)data options:(NSDictionary *)options documentAttributes:(NSDictionary * __autoreleasing*)docAttributes
{
	self = [super init];
	if (self)
	{
		_data = data;
		_options = options;
		
		// documentAttributes ignored for now
		// Specify the appropriate text encoding for the passed data, default is UTF8
		NSString *textEncodingName = [_options objectForKey:NSTextEncodingNameDocumentOption];
		NSStringEncoding encoding = NSUTF8StringEncoding; // default
		
		if (textEncodingName)
		{
			CFStringEncoding cfEncoding = CFStringConvertIANACharSetNameToEncoding((__bridge CFStringRef)textEncodingName);
			encoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
		}
		_parser = [[DTHTMLParser alloc] initWithData:_data encoding:encoding];
		_parser.delegate = (id)self;
		
		// GCD setup
		_stringAssemblyQueue = dispatch_queue_create("DTHTMLAttributedStringBuilder", 0);
		_stringAssemblyGroup = dispatch_group_create();
		_dataParsingQueue = dispatch_queue_create("DTHTMLAttributedStringBuilderParser", 0);
		_dataParsingGroup = dispatch_group_create();
		_treeBuildingQueue = dispatch_queue_create("DTHTMLAttributedStringBuilderParser Tree Queue", 0);
		_treeBuildingGroup = dispatch_group_create();
	}
	
	return self;
}

- (void)dealloc
{
#if !OS_OBJECT_USE_OBJC
	dispatch_release(_stringAssemblyQueue);
	dispatch_release(_stringAssemblyGroup);
	dispatch_release(_dataParsingQueue);
	dispatch_release(_dataParsingGroup);
	dispatch_release(_treeBuildingQueue);
	dispatch_release(_treeBuildingGroup);
#endif
}

- (BOOL)_buildString
{
#if DEBUG_LOG_METRICS
	// metrics: get start time
	CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
#endif
	
	// only with valid data
	if (![_data length])
	{
		return NO;
	}
	
	// register default handlers
	[self _registerTagStartHandlers];
	[self _registerTagEndHandlers];
	
#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES
	
	// custom option to use iOS 6 attributes if running on iOS 6
	if ([[_options objectForKey:DTUseiOS6Attributes] boolValue])
	{
#if TARGET_OS_IPHONE
		// NS-attributes only supported running on iOS 6.0 or greater
		if (floor(NSFoundationVersionNumber) >= DTNSFoundationVersionNumber_iOS_6_0)
		{
			___useiOS6Attributes = YES;
		}
		else
		{
			___useiOS6Attributes = NO;
		}
#else
		// Mac generally supports it
		___useiOS6Attributes = YES;
#endif
	}
	
#endif

	
	// custom option to scale text
	_textScale = [[_options objectForKey:NSTextSizeMultiplierDocumentOption] floatValue];
	if (_textScale==0)
	{
		_textScale = 1.0f;
	}
	
	// use baseURL from options if present
	_baseURL = [_options objectForKey:NSBaseURLDocumentOption];
	
	// the combined style sheet for entire document
	_globalStyleSheet = [[DTCSSStylesheet defaultStyleSheet] copy];
	
	// do we have a default style sheet passed as option?
	DTCSSStylesheet *defaultStylesheet = [_options objectForKey:DTDefaultStyleSheet];
	if (defaultStylesheet)
	{
		// merge the default styles to the combined style sheet
		[_globalStyleSheet mergeStylesheet:defaultStylesheet];
	}
	
	// for performance reasons we will return this mutable string
	_tmpString = [[NSMutableAttributedString alloc] init];
	
	// base tag with font defaults
	_defaultFontDescriptor = [[DTCoreTextFontDescriptor alloc] initWithFontAttributes:nil];
	
	
	// set the default font size
	CGFloat defaultFontSize = 12.0f;
	
	NSNumber *defaultFontSizeNumber = [_options objectForKey:DTDefaultFontSize];
	
	if (defaultFontSizeNumber)
	{
		defaultFontSize = [defaultFontSizeNumber floatValue];
	}
	
	_defaultFontDescriptor.pointSize = defaultFontSize * _textScale;
	
	NSString *defaultFontFamily = [_options objectForKey:DTDefaultFontFamily];
	
	if (defaultFontFamily)
	{
		_defaultFontDescriptor.fontFamily = defaultFontFamily;
	}
	else
	{
		_defaultFontDescriptor.fontFamily = @"Times New Roman";
	}

	NSString *defaultFontName = [_options objectForKey:DTDefaultFontName];

	if (defaultFontName) {
		_defaultFontDescriptor.fontName = defaultFontName;
	}

	
	_defaultLinkColor = [_options objectForKey:DTDefaultLinkColor];
	
	if (_defaultLinkColor)
	{
		if ([_defaultLinkColor isKindOfClass:[NSString class]])
		{
			// convert from string to color
			_defaultLinkColor = DTColorCreateWithHTMLName((NSString *)_defaultLinkColor);
		}
		
		// get hex code for the passed color
		NSString *colorHex = DTHexStringFromDTColor(_defaultLinkColor);
		
		// overwrite the style
		NSString *styleBlock = [NSString stringWithFormat:@"a {color:#%@;}", colorHex];
		[_globalStyleSheet parseStyleBlock:styleBlock];
	}
	
	// default is to have A underlined
	NSNumber *linkDecorationDefault = [_options objectForKey:DTDefaultLinkDecoration];
	
	if (linkDecorationDefault)
	{
		if (![linkDecorationDefault boolValue])
		{
			// remove default decoration
			[_globalStyleSheet parseStyleBlock:@"a {text-decoration:none;}"];
		}
	}
	
	DTColor *defaultLinkHighlightColor = [_options objectForKey:DTDefaultLinkHighlightColor];
	
	if (defaultLinkHighlightColor)
	{
		if ([defaultLinkHighlightColor isKindOfClass:[NSString class]])
		{
			// convert from string to color
			defaultLinkHighlightColor = DTColorCreateWithHTMLName((NSString *)defaultLinkHighlightColor);
		}
		
		// get hex code for the passed color
		NSString *colorHex = DTHexStringFromDTColor(defaultLinkHighlightColor);
		
		// overwrite the style
		NSString *styleBlock = [NSString stringWithFormat:@"a:active {color:#%@;}", colorHex];
		[_globalStyleSheet parseStyleBlock:styleBlock];
	}
	
	// default paragraph style
	_defaultParagraphStyle = [DTCoreTextParagraphStyle defaultParagraphStyle];
	
	NSNumber *defaultLineHeightMultiplierNum = [_options objectForKey:DTDefaultLineHeightMultiplier];
	
	if (defaultLineHeightMultiplierNum)
	{
		CGFloat defaultLineHeightMultiplier = [defaultLineHeightMultiplierNum floatValue];
		_defaultParagraphStyle.lineHeightMultiple = defaultLineHeightMultiplier;
	}
	
	NSNumber *defaultTextAlignmentNum = [_options objectForKey:DTDefaultTextAlignment];
	
	if (defaultTextAlignmentNum)
	{
		_defaultParagraphStyle.alignment = (CTTextAlignment)[defaultTextAlignmentNum integerValue];
	}
	
	NSNumber *defaultFirstLineHeadIndent = [_options objectForKey:DTDefaultFirstLineHeadIndent];
	if (defaultFirstLineHeadIndent)
	{
		_defaultParagraphStyle.firstLineHeadIndent = [defaultFirstLineHeadIndent integerValue];
	}
	
	NSNumber *defaultHeadIndent = [_options objectForKey:DTDefaultHeadIndent];
	if (defaultHeadIndent)
	{
		_defaultParagraphStyle.headIndent = [defaultHeadIndent integerValue];
	}
	
	_defaultTag = [[DTHTMLElement alloc] init];
	_defaultTag.fontDescriptor = _defaultFontDescriptor;
	_defaultTag.paragraphStyle = _defaultParagraphStyle;
	_defaultTag.textScale = _textScale;
	_defaultTag.currentTextSize = _defaultFontDescriptor.pointSize;
	
#if DTCORETEXT_FIX_14684188
	// workaround, only necessary while rdar://14684188 is not fixed
	_defaultTag.textColor = [UIColor blackColor];
#endif
	
	id defaultColor = [_options objectForKey:DTDefaultTextColor];
	if (defaultColor)
	{
		if ([defaultColor isKindOfClass:[DTColor class]])
		{
			// already a DTColor
			_defaultTag.textColor = defaultColor;
		}
		else
		{
			// need to convert first
			_defaultTag.textColor = DTColorCreateWithHTMLName(defaultColor);
		}
	}
	
	_shouldProcessCustomHTMLAttributes = [[_options objectForKey:DTProcessCustomHTMLAttributes] boolValue];
	
	// ignore inline styles if option is passed
	_ignoreInlineStyles = [[_options objectForKey:DTIgnoreInlineStylesOption] boolValue];
	
	// don't remove spaces at end of document
	_preserverDocumentTrailingSpaces = [[_options objectForKey:DTDocumentPreserveTrailingSpaces] boolValue];
	
	DT_WEAK_VARIABLE typeof(self) weakSelf = self;
	__block BOOL result;
	dispatch_group_async(_dataParsingGroup, _dataParsingQueue, ^{ result = [weakSelf.self->_parser parse]; });
	
	// wait until all string assembly is complete
	dispatch_group_wait(_dataParsingGroup, DISPATCH_TIME_FOREVER);
	dispatch_group_wait(_treeBuildingGroup, DISPATCH_TIME_FOREVER);
	dispatch_group_wait(_stringAssemblyGroup, DISPATCH_TIME_FOREVER);
	
	// clean up handlers because they retained self
	_tagStartHandlers = nil;
	_tagEndHandlers = nil;

#if DEBUG_LOG_METRICS
	// metrics: get end time
	CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
	
	// output metrics
	DTLogInfo((@"DTCoreText created string from %@ HTML in %.2f sec", [NSString stringByFormattingBytes:[_data length]], endTime-startTime);
#endif
	
	return result;
}

- (NSAttributedString *)generatedAttributedString
{
	if (!_tmpString)
	{
		[self _buildString];
	}
	
	return _tmpString;
}

#pragma mark GCD

- (void)_registerTagStartHandlers
{
	if (_tagStartHandlers)
	{
		return;
	}
	
	_tagStartHandlers = [[NSMutableDictionary alloc] init];
	
	void (^blockquoteBlock)(void) = ^
	{
		self->_currentTag.paragraphStyle.headIndent += (CGFloat)25.0 * self->_textScale;
		self->_currentTag.paragraphStyle.firstLineHeadIndent = self->_currentTag.paragraphStyle.headIndent;
		self->_currentTag.paragraphStyle.paragraphSpacing = self->_defaultFontDescriptor.pointSize;
	};
	
	[_tagStartHandlers setObject:[blockquoteBlock copy] forKey:@"blockquote"];
	
	
	void (^aBlock)(void) = ^
	{
		if (self->_currentTag.isColorInherited || !self->_currentTag.textColor)
		{
			self->_currentTag.textColor = self->_defaultLinkColor;
			self->_currentTag.isColorInherited = NO;
		}
		
		// the name attribute of A becomes an anchor
		self->_currentTag.anchorName = [self->_currentTag attributeForKey:@"name"];

		// remove line breaks and whitespace in links
		NSString *cleanString = [[self->_currentTag attributeForKey:@"href"] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
		cleanString = [cleanString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		
		if (![cleanString length])
		{
			// no valid href
			return;
		}
		
		NSURL *link = [NSURL URLWithString:cleanString];
        if (link == nil) {
            link = [NSURL URLWithString:[cleanString stringByURLEncoding]];
        }
		
		// deal with relative URL
		if (![link scheme])
		{
			if ([cleanString length])
			{
				link = [NSURL URLWithString:cleanString relativeToURL:self->_baseURL];
				
				if (!link)
				{
					// NSURL did not like the link, so let's encode it
					cleanString = [cleanString stringByAddingHTMLEntities];
					
					link = [NSURL URLWithString:cleanString relativeToURL:self->_baseURL];
				}
			}
			else
			{
				link = self->_baseURL;
			}
		}
		
		self->_currentTag.link = link;
	};
	
	[_tagStartHandlers setObject:[aBlock copy] forKey:@"a"];
	
	void (^listBlock)(void) = ^
	{
		self->_currentTag.paragraphStyle.firstLineHeadIndent = self->_currentTag.paragraphStyle.headIndent;
		
		// create the appropriate list style from CSS
		DTCSSListStyle *newListStyle = [self->_currentTag listStyle];
		
		// append this list style to the current paragraph style text lists
		NSMutableArray *textLists = [self->_currentTag.paragraphStyle.textLists mutableCopy];
		
		if (!textLists)
		{
			textLists = [NSMutableArray array];
		}
		
		[textLists addObject:newListStyle];
		
		self->_currentTag.paragraphStyle.textLists = textLists;
	};
	
	[_tagStartHandlers setObject:[listBlock copy] forKey:@"ul"];
	[_tagStartHandlers setObject:[listBlock copy] forKey:@"ol"];
	
	void (^h1Block)(void) = ^
	{
		self->_currentTag.headerLevel = 1;
	};
	[_tagStartHandlers setObject:[h1Block copy] forKey:@"h1"];
	
	void (^h2Block)(void) = ^
	{
		self->_currentTag.headerLevel = 2;
	};
	[_tagStartHandlers setObject:[h2Block copy] forKey:@"h2"];
	
	
	void (^h3Block)(void) = ^
	{
		self->_currentTag.headerLevel = 3;
	};
	[_tagStartHandlers setObject:[h3Block copy] forKey:@"h3"];
	
	
	void (^h4Block)(void) = ^
	{
		self->_currentTag.headerLevel = 4;
	};
	[_tagStartHandlers setObject:[h4Block copy] forKey:@"h4"];
	
	
	void (^h5Block)(void) = ^
	{
		self->_currentTag.headerLevel = 5;
	};
	[_tagStartHandlers setObject:[h5Block copy] forKey:@"h5"];
	
	
	void (^h6Block)(void) = ^
	{
		self->_currentTag.headerLevel = 6;
	};
	[_tagStartHandlers setObject:[h6Block copy] forKey:@"h6"];
	
	
	void (^fontBlock)(void) = ^
	{
		CGFloat pointSize;
		
		NSString *sizeAttribute = [self->_currentTag attributeForKey:@"size"];
		
		if (sizeAttribute)
		{
			NSInteger sizeValue = [sizeAttribute intValue];
			
			switch (sizeValue)
			{
				case 1:
					pointSize = self->_textScale * 10.0f;
					break;
				case 2:
					pointSize = self->_textScale * 13.0f;
					break;
				case 3:
					pointSize = self->_textScale * 16.0f;
					break;
				case 4:
					pointSize = self->_textScale * 18.0f;
					break;
				case 5:
					pointSize = self->_textScale * 24.0f;
					break;
				case 6:
					pointSize = self->_textScale * 32.0f;
					break;
				case 7:
					pointSize = self->_textScale * 48.0f;
					break;
				default:
					pointSize = self->_defaultFontDescriptor.pointSize;
					break;
			}
		}
		else
		{
			// size is inherited
			pointSize = self->_currentTag.fontDescriptor.pointSize;
		}
		
		NSString *face = [self->_currentTag attributeForKey:@"face"];
		
		if (face)
		{
			// create a temp font with this face
			CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)face, pointSize, NULL);
			
			self->_currentTag.fontDescriptor = [DTCoreTextFontDescriptor fontDescriptorForCTFont:font];
			
			CFRelease(font);
		}
		else
		{
			// modify inherited descriptor
			self->_currentTag.fontDescriptor.pointSize = pointSize;
		}
		
		NSString *color = [self->_currentTag attributeForKey:@"color"];
		
		if (color)
		{
			self->_currentTag.textColor = DTColorCreateWithHTMLName(color);
		}
	};
	
	[_tagStartHandlers setObject:[fontBlock copy] forKey:@"font"];
	
	
	void (^pBlock)(void) = ^
	{
		// if have the custom headIndent
		if (self->_defaultParagraphStyle.firstLineHeadIndent > 0)
		{
			self->_currentTag.paragraphStyle.firstLineHeadIndent = self->_currentTag.paragraphStyle.headIndent +
																		 self->_defaultParagraphStyle.firstLineHeadIndent;
		}
		else
		{
			self->_currentTag.paragraphStyle.firstLineHeadIndent = self->_currentTag.paragraphStyle.headIndent + self->_currentTag.pTextIndent;
		}
	};
	
	[_tagStartHandlers setObject:[pBlock copy] forKey:@"p"];
}

- (void)_registerTagEndHandlers
{
	if (_tagEndHandlers)
	{
		return;
	}
	
	_tagEndHandlers = [[NSMutableDictionary alloc] init];
		
	void (^objectBlock)(void) = ^
	{
		if ([self->_currentTag isKindOfClass:[DTTextAttachmentHTMLElement class]])
		{
			if ([self->_currentTag.textAttachment isKindOfClass:[DTObjectTextAttachment class]])
			{
				DTObjectTextAttachment *objectAttachment = (DTObjectTextAttachment *)self->_currentTag.textAttachment;
				
				// transfer the child nodes to the attachment
				objectAttachment.childNodes = [self->_currentTag.childNodes copy];
			}
		}
	};
	
	[_tagEndHandlers setObject:[objectBlock copy] forKey:@"object"];

	void (^videoBlock)(void) = ^
	{
		if ([self->_currentTag isKindOfClass:[DTTextAttachmentHTMLElement class]])
		{
			DTTextAttachmentHTMLElement *attachmentElement = (DTTextAttachmentHTMLElement *)self->_currentTag;
			
			if ([attachmentElement.textAttachment isKindOfClass:[DTVideoTextAttachment class]])
			{
				DTVideoTextAttachment *videoAttachment = (DTVideoTextAttachment *)attachmentElement.textAttachment;
				
				// find first child that has a source
				if (!videoAttachment.contentURL)
				{
					for (DTHTMLElement *child in attachmentElement.childNodes)
					{
						if ([child.name isEqualToString:@"source"])
						{
							NSString *src = [child attributeForKey:@"src"];
							
							// content URL
							videoAttachment.contentURL = [NSURL URLWithString:src relativeToURL:self->_baseURL];
							
							break;
						}
					}
				}
			}
		}
	};
	
	[_tagEndHandlers setObject:[videoBlock copy] forKey:@"video"];
	
	void (^styleBlock)(void) = ^
	{
		DTCSSStylesheet *localSheet = [(DTStylesheetHTMLElement *)self->_currentTag stylesheet];
		[self->_globalStyleSheet mergeStylesheet:localSheet];
	};
	
	[_tagEndHandlers setObject:[styleBlock copy] forKey:@"style"];
	
	
	void (^linkBlock)(void) = ^
	{
		NSString *href = [self->_currentTag attributeForKey:@"href"];
		NSString *type = [[self->_currentTag attributeForKey:@"type"] lowercaseString];
		
		if ([type isEqualToString:@"text/css"])
		{
			NSURL *stylesheetURL = [NSURL URLWithString:href relativeToURL:self->_baseURL];
			if ([stylesheetURL isFileURL])
			{
				NSString *stylesheetContent = [NSString stringWithContentsOfURL:stylesheetURL encoding:NSUTF8StringEncoding error:nil];
				if (stylesheetContent)
				{
					DTCSSStylesheet *localSheet = [[DTCSSStylesheet alloc] initWithStyleBlock:stylesheetContent];
					[self->_globalStyleSheet mergeStylesheet:localSheet];
				}
			}
			else
			{
				DTLogWarning(@"CSS link referencing a non-local target, ignored");
			}
		}
	};
	
	[ _tagEndHandlers setObject:[linkBlock copy] forKey:@"link"];
}

#pragma mark DTHTMLParser Delegate

- (void)parser:(DTHTMLParser *)parser didStartElement:(NSString *)elementName attributes:(NSDictionary *)attributeDict
{
	DT_WEAK_VARIABLE typeof(self) weakSelf = self;
	dispatch_group_async(_treeBuildingGroup, _treeBuildingQueue, ^{
		DTHTMLAttributedStringBuilder *strongSelf = weakSelf;

		if (strongSelf->_ignoreParseEvents)
		{
			return;
		}

		DTHTMLElement *newNode = [DTHTMLElement elementWithName:elementName attributes:attributeDict options:strongSelf->_options];
		DTHTMLElement *previousLastChild = nil;
		
		if (strongSelf->_currentTag)
		{
			// inherit stuff
			[newNode inheritAttributesFromElement:strongSelf->_currentTag];
			[newNode interpretAttributes];
			
			previousLastChild = [strongSelf->_currentTag.childNodes lastObject];
			
			// add as new child of current node
			[strongSelf->_currentTag addChildNode:newNode];
			
			// remember body node
			if (!strongSelf->_bodyElement && [newNode.name isEqualToString:@"body"])
			{
				strongSelf->_bodyElement = newNode;
			}
			
			if (strongSelf->_shouldProcessCustomHTMLAttributes)
			{
				newNode.shouldProcessCustomHTMLAttributes = strongSelf->_shouldProcessCustomHTMLAttributes;
			}
		}
		else
		{
			NSAssert(!strongSelf->_rootNode, @"Something went wrong, second root node found in document and not ignored.");
			
			// might be first node ever
			if (!strongSelf->_rootNode)
			{
				strongSelf->_rootNode = newNode;
				
				[strongSelf->_rootNode inheritAttributesFromElement:strongSelf->_defaultTag];
				[strongSelf->_rootNode interpretAttributes];
			}
		}
		
		// apply style from merged style sheet
		NSSet *matchedSelectors;
		NSDictionary *mergedStyles = [strongSelf->_globalStyleSheet mergedStyleDictionaryForElement:newNode matchedSelectors:&matchedSelectors ignoreInlineStyle:strongSelf->_ignoreInlineStyles];
		
		if (mergedStyles)
		{
			[newNode applyStyleDictionary:mergedStyles];
			
			// do not add the matched class names to 'class' custom attribute 
			if (matchedSelectors)
			{
				NSMutableSet *classNamesToIgnoreForCustomAttributes = [NSMutableSet set];
				
				for (NSString *oneSelector in matchedSelectors)
				{
					// class selectors have a period
					NSRange periodRange = [oneSelector rangeOfString:@"."];
					
					if (periodRange.location != NSNotFound)
					{
						NSString *className = [oneSelector substringFromIndex:periodRange.location+1];
						
						// add this to ignored classes
						[classNamesToIgnoreForCustomAttributes addObject:className];
					}
				}
				
				if ([classNamesToIgnoreForCustomAttributes count])
				{
					newNode.CSSClassNamesToIgnoreForCustomAttributes = classNamesToIgnoreForCustomAttributes;
				}
			}
		}
		
		// adding a block element eliminates previous trailing white space text node
		// because a new block starts on a new line
		if (previousLastChild && newNode.displayStyle != DTHTMLElementDisplayStyleInline)
		{
			if ([previousLastChild isKindOfClass:[DTTextHTMLElement class]])
			{
				DTTextHTMLElement *textElement = (DTTextHTMLElement *)previousLastChild;
				
				if ([[textElement text] isIgnorableWhitespace])
				{
					[strongSelf->_currentTag removeChildNode:textElement];
				}
			}
		}
		
		strongSelf->_currentTag = newNode;
		
		// find block to execute for this tag if any
		void (^tagBlock)(void) = [strongSelf->_tagStartHandlers objectForKey:elementName];
		
		if (tagBlock)
		{
			tagBlock();
		}
	});
}

- (void)parser:(DTHTMLParser *)parser didEndElement:(NSString *)elementName
{

	DT_WEAK_VARIABLE typeof(self) weakSelf = self;
	dispatch_group_async(_treeBuildingGroup, _treeBuildingQueue, ^{
		@autoreleasepool {
			DTHTMLAttributedStringBuilder *strongSelf = weakSelf;
			if (strongSelf->_ignoreParseEvents)
			{
				return;
			}
			
			// output the element if it is direct descendant of body tag, or close of body in case there are direct text nodes
			
			// find block to execute for this tag if any
			void (^tagBlock)(void) = [strongSelf->_tagEndHandlers objectForKey:elementName];
			
			if (tagBlock)
			{
				tagBlock();
			}
			
			if (strongSelf->_currentTag.displayStyle != DTHTMLElementDisplayStyleNone)
			{
				if (strongSelf->_currentTag == strongSelf->_bodyElement || strongSelf->_currentTag.parentElement == strongSelf->_bodyElement)
				{
					DTHTMLElement *theTag = strongSelf->_currentTag;
					
					dispatch_group_async(strongSelf->_stringAssemblyGroup, strongSelf->_stringAssemblyQueue, ^{
						// has children that have not been output yet
						if ([theTag needsOutput])
						{
							// caller gets opportunity to modify tag before it is written
							if (strongSelf->_willFlushCallback)
							{
								strongSelf->_willFlushCallback(theTag);
							}
							
							NSAttributedString *nodeString = [theTag attributedString];
							
							if (nodeString)
							{
								// if this is a block element then we need a paragraph break before it
								if (theTag.displayStyle != DTHTMLElementDisplayStyleInline)
								{
									if ([strongSelf->_tmpString length] && ![[strongSelf->_tmpString string] hasSuffix:@"\n"])
									{
										// trim off whitespace
										while ([[strongSelf->_tmpString string] hasSuffixCharacterFromSet:[NSCharacterSet ignorableWhitespaceCharacterSet]])
										{
											[strongSelf->_tmpString deleteCharactersInRange:NSMakeRange([strongSelf->_tmpString length]-1, 1)];
										}
										
										[strongSelf->_tmpString appendString:@"\n"];
									}
								}
								
								[strongSelf->_tmpString appendAttributedString:nodeString];
								theTag.didOutput = YES;
								
								if (!strongSelf->_shouldKeepDocumentNodeTree)
								{
									// we don't need the children any more
									[theTag removeAllChildNodes];
								}
							}
							
						}
					});
				}
				
			}
			
			while (![strongSelf->_currentTag.name isEqualToString:elementName])
			{
				// missing end of element, attempt to recover
				strongSelf->_currentTag = [strongSelf->_currentTag parentElement];
			}
			
			// closing the root node, ignore everything afterwards
			if (strongSelf->_currentTag == strongSelf->_rootNode)
			{
				strongSelf->_ignoreParseEvents = YES;
			}
			
			// go back up a level
			strongSelf->_currentTag = [strongSelf->_currentTag parentElement];
		}
	});
}

- (void)parser:(DTHTMLParser *)parser foundCharacters:(NSString *)string
{
	DT_WEAK_VARIABLE typeof(self) weakSelf = self;
	dispatch_group_async(_treeBuildingGroup, _treeBuildingQueue, ^{
		DTHTMLAttributedStringBuilder *strongSelf = weakSelf;
		if (strongSelf->_ignoreParseEvents)
		{
			return;
		}
		
		NSAssert(strongSelf->_currentTag, @"Cannot add text node without a current node");
		
		if (!strongSelf->_currentTag.preserveNewlines && [string isIgnorableWhitespace])
		{
			// ignore whitespace as first element of block element
			if (strongSelf->_currentTag.displayStyle!=DTHTMLElementDisplayStyleInline && ![strongSelf->_currentTag.childNodes count])
			{
				return;
			}
			
			// ignore whitespace following a block element
			DTHTMLElement *previousTag = [strongSelf->_currentTag.childNodes lastObject];
			
			if (previousTag.displayStyle != DTHTMLElementDisplayStyleInline)
			{
				return;
			}
			
			// ignore whitespace following a BR
			if ([previousTag isKindOfClass:[DTBreakHTMLElement class]])
			{
				return;
			}
		}
		
		// adds a text node to the current node
		DTTextHTMLElement *textNode = [[DTTextHTMLElement alloc] init];
		textNode.text = string;
		
		[textNode inheritAttributesFromElement:strongSelf->_currentTag];
		[textNode interpretAttributes];
		
		// save it for later output
		[strongSelf->_currentTag addChildNode:textNode];
		
		DTHTMLElement *theTag = strongSelf->_currentTag;
		
		// text directly contained in body needs to be output right away
		if (theTag == strongSelf->_bodyElement)
		{
			dispatch_group_async(strongSelf->_stringAssemblyGroup, strongSelf->_stringAssemblyQueue, ^{
				[strongSelf->_tmpString appendAttributedString:[textNode attributedString]];
				theTag.didOutput = YES;
			});
			
			// only add it to current tag if we need it
			if (strongSelf->_shouldKeepDocumentNodeTree)
			{
				[theTag addChildNode:textNode];
			}
			
			return;
		}
		
	});
}

- (void)parser:(DTHTMLParser *)parser foundCDATA:(NSData *)CDATABlock
{
	DT_WEAK_VARIABLE typeof(self) weakSelf = self;
	dispatch_group_async(_treeBuildingGroup, _treeBuildingQueue, ^{
		DTHTMLAttributedStringBuilder *strongSelf = weakSelf;
		
		if (strongSelf->_ignoreParseEvents)
		{
			return;
		}
		
		NSAssert(strongSelf->_currentTag, @"Cannot add text node without a current node");
		
		NSString *styleBlock = [[NSString alloc] initWithData:CDATABlock encoding:NSUTF8StringEncoding];
		
		// adds a text node to the current node
		DTHTMLParserTextNode *textNode = [[DTHTMLParserTextNode alloc] initWithCharacters:styleBlock];
		
		[strongSelf->_currentTag addChildNode:textNode];
	});
}

- (void)parserDidEndDocument:(DTHTMLParser *)parser
{
	DT_WEAK_VARIABLE typeof(self) weakSelf = self;
	dispatch_group_async(_treeBuildingGroup, _treeBuildingQueue, ^{
		DTHTMLAttributedStringBuilder *strongSelf = weakSelf;
		
		NSAssert(!strongSelf->_currentTag, @"Something went wrong, at end of document there is still an open node");

		if (!strongSelf->_preserverDocumentTrailingSpaces) {
			dispatch_group_async(strongSelf->_stringAssemblyGroup, strongSelf->_stringAssemblyQueue, ^{
				// trim off white space at end
				while ([[strongSelf->_tmpString string] hasSuffixCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]])
				{
					[strongSelf->_tmpString deleteCharactersInRange:NSMakeRange([strongSelf->_tmpString length]-1, 1)];
				}
			});
		}
	});
}

- (void)parser:(DTHTMLParser *)parser parseErrorOccurred:(NSError *)parseError;
{
	if(_parseErrorCallback)
	{
		_parseErrorCallback(_tmpString,parseError);
	}
}
			  
- (void)abortParsing
{
	[_parser abortParsing];
}
#pragma mark Properties

@synthesize willFlushCallback = _willFlushCallback;
@synthesize shouldKeepDocumentNodeTree = _shouldKeepDocumentNodeTree;
@synthesize parseErrorCallback = _parseErrorCallback;

@end
