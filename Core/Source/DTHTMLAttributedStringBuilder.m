//
//  DTHTMLAttributedStringBuilder.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 21.01.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTCoreText.h"
#import "DTHTMLAttributedStringBuilder.h"

#import "DTTextHTMLElement.h"
#import "DTBreakHTMLElement.h"
#import "DTStylesheetHTMLElement.h"
#import "DTTextAttachmentHTMLElement.h"

#import "DTVersion.h"
#import "NSString+DTFormatNumbers.h"

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
	dispatch_queue_t _treeBuildingQueue;;
	dispatch_group_t _treeBuildingGroup;
	
	// lookup table for blocks that deal with begin and end tags
	NSMutableDictionary *_tagStartHandlers;
	NSMutableDictionary *_tagEndHandlers;
	
	DTHTMLAttributedStringBuilderWillFlushCallback _willFlushCallback;
	
	// new parsing
	DTHTMLElement *_rootNode;
	DTHTMLElement *_bodyElement;
	DTHTMLElement *_currentTag;
	BOOL _ignoreParseEvents; // ignores events from parser after first HTML tag was finished
}

- (id)initWithHTML:(NSData *)data options:(NSDictionary *)options documentAttributes:(NSDictionary **)docAttributes
{
	self = [super init];
	if (self)
	{
		_data = data;
		_options = options;
		
		// documentAttributes ignored for now
		
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
	
 	// Specify the appropriate text encoding for the passed data, default is UTF8
	NSString *textEncodingName = [_options objectForKey:NSTextEncodingNameDocumentOption];
	NSStringEncoding encoding = NSUTF8StringEncoding; // default
	
	if (textEncodingName)
	{
		CFStringEncoding cfEncoding = CFStringConvertIANACharSetNameToEncoding((__bridge CFStringRef)textEncodingName);
		encoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
	}
	
	// custom option to use iOS 6 attributes if running on iOS 6
	if ([[_options objectForKey:DTUseiOS6Attributes] boolValue])
	{
		if (![DTVersion osVersionIsLessThen:@"6.0"])
		{
			___useiOS6Attributes = YES;
		}
		else
		{
			___useiOS6Attributes = NO;
		}
	}
	else
	{
		// default is not to use them because many features are not supported
		___useiOS6Attributes = NO;
	}
	
	// custom option to scale text
	_textScale = [[_options objectForKey:NSTextSizeMultiplierDocumentOption] floatValue];
	if (!_textScale)
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
	
	_defaultLinkColor = [_options objectForKey:DTDefaultLinkColor];
	
	if (_defaultLinkColor)
	{
		if ([_defaultLinkColor isKindOfClass:[NSString class]])
		{
			// convert from string to color
			_defaultLinkColor = [DTColor colorWithHTMLName:(NSString *)_defaultLinkColor];
		}
		
		// get hex code for the passed color
		NSString *colorHex = [_defaultLinkColor htmlHexString];
		
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
			defaultLinkHighlightColor = [DTColor colorWithHTMLName:(NSString *)defaultLinkHighlightColor];
		}
		
		// get hex code for the passed color
		NSString *colorHex = [defaultLinkHighlightColor htmlHexString];
		
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
			_defaultTag.textColor = [DTColor colorWithHTMLName:defaultColor];
		}
	}
	
	// create a parser
	DTHTMLParser *parser = [[DTHTMLParser alloc] initWithData:_data encoding:encoding];
	parser.delegate = (id)self;
	
	__block BOOL result;
	dispatch_group_async(_dataParsingGroup, _dataParsingQueue, ^{ result = [parser parse]; });
	
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
	NSLog(@"DTCoreText created string from %@ HTML in %.2f sec", [NSString stringByFormattingBytes:[_data length]], endTime-startTime);
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
		_currentTag.paragraphStyle.headIndent += 25.0 * _textScale;
		_currentTag.paragraphStyle.firstLineHeadIndent = _currentTag.paragraphStyle.headIndent;
		_currentTag.paragraphStyle.paragraphSpacing = _defaultFontDescriptor.pointSize;
	};
	
	[_tagStartHandlers setObject:[blockquoteBlock copy] forKey:@"blockquote"];
	
	
	void (^aBlock)(void) = ^
	{
		if (_currentTag.isColorInherited || !_currentTag.textColor)
		{
			_currentTag.textColor = _defaultLinkColor;
			_currentTag.isColorInherited = NO;
		}
		
		// remove line breaks and whitespace in links
		NSString *cleanString = [[_currentTag attributeForKey:@"href"] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
		cleanString = [cleanString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		
		NSURL *link = [NSURL URLWithString:cleanString];
		
		// deal with relative URL
		if (![link scheme])
		{
			if ([cleanString length])
			{
				link = [NSURL URLWithString:cleanString relativeToURL:_baseURL];
				
				if (!link)
				{
					// NSURL did not like the link, so let's encode it
					cleanString = [cleanString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
					
					link = [NSURL URLWithString:cleanString relativeToURL:_baseURL];
				}
			}
			else
			{
				link = _baseURL;
			}
		}
		
		_currentTag.link = link;
		
		// the name attribute of A becomes an anchor
		_currentTag.anchorName = [_currentTag attributeForKey:@"name"];
	};
	
	[_tagStartHandlers setObject:[aBlock copy] forKey:@"a"];
	
	void (^listBlock)(void) = ^
	{
		_currentTag.paragraphStyle.firstLineHeadIndent = _currentTag.paragraphStyle.headIndent;
		
		// create the appropriate list style from CSS
		DTCSSListStyle *newListStyle = [_currentTag listStyle];
		
		// append this list style to the current paragraph style text lists
		NSMutableArray *textLists = [_currentTag.paragraphStyle.textLists mutableCopy];
		if (!textLists)
		{
			textLists = [NSMutableArray array];
		}
		
		[textLists addObject:newListStyle];
		
		// workaround for different styles on stacked lists
		if ([textLists count]>1) // not necessary for first
		{
			// find out if each list is ordered or unordered
			NSMutableArray *tmpArray = [NSMutableArray array];
			for (DTCSSListStyle *oneList in textLists)
			{
				if ([oneList isOrdered])
				{
					[tmpArray addObject:@"ol"];
				}
				else
				{
					[tmpArray addObject:@"ul"];
				}
			}
			
			// build a CSS selector
			NSString *selector = [tmpArray componentsJoinedByString:@" "];
			
			// find style
			NSDictionary *style = [[_globalStyleSheet styles] objectForKey:selector];
			
			if (style)
			{
				[newListStyle updateFromStyleDictionary:style];
			}
		}
		
		_currentTag.paragraphStyle.textLists = textLists;
	};
	
	[_tagStartHandlers setObject:[listBlock copy] forKey:@"ul"];
	[_tagStartHandlers setObject:[listBlock copy] forKey:@"ol"];
	
	void (^h1Block)(void) = ^
	{
		_currentTag.headerLevel = 1;
	};
	[_tagStartHandlers setObject:[h1Block copy] forKey:@"h1"];
	
	void (^h2Block)(void) = ^
	{
		_currentTag.headerLevel = 2;
	};
	[_tagStartHandlers setObject:[h2Block copy] forKey:@"h2"];
	
	
	void (^h3Block)(void) = ^
	{
		_currentTag.headerLevel = 3;
	};
	[_tagStartHandlers setObject:[h3Block copy] forKey:@"h3"];
	
	
	void (^h4Block)(void) = ^
	{
		_currentTag.headerLevel = 4;
	};
	[_tagStartHandlers setObject:[h4Block copy] forKey:@"h4"];
	
	
	void (^h5Block)(void) = ^
	{
		_currentTag.headerLevel = 5;
	};
	[_tagStartHandlers setObject:[h5Block copy] forKey:@"h5"];
	
	
	void (^h6Block)(void) = ^
	{
		_currentTag.headerLevel = 6;
	};
	[_tagStartHandlers setObject:[h6Block copy] forKey:@"h6"];
	
	
	void (^fontBlock)(void) = ^
	{
		NSString *sizeAttribute = [_currentTag attributeForKey:@"size"];
		
		if (sizeAttribute)
		{
			NSInteger sizeValue = [sizeAttribute intValue];
			
			switch (sizeValue)
			{
				case 1:
					_currentTag.fontDescriptor.pointSize = _textScale * 10.0f;
					break;
				case 2:
					_currentTag.fontDescriptor.pointSize = _textScale * 13.0f;
					break;
				case 3:
					_currentTag.fontDescriptor.pointSize = _textScale * 16.0f;
					break;
				case 4:
					_currentTag.fontDescriptor.pointSize = _textScale * 18.0f;
					break;
				case 5:
					_currentTag.fontDescriptor.pointSize = _textScale * 24.0f;
					break;
				case 6:
					_currentTag.fontDescriptor.pointSize = _textScale * 32.0f;
					break;
				case 7:
					_currentTag.fontDescriptor.pointSize = _textScale * 48.0f;
					break;
				default:
					_currentTag.fontDescriptor.pointSize = _defaultFontDescriptor.pointSize;
					break;
			}
		}
		
		NSString *face = [_currentTag attributeForKey:@"face"];
		
		if (face)
		{
			_currentTag.fontDescriptor.fontName = face;
			
			// face usually invalidates family
			_currentTag.fontDescriptor.fontFamily = nil;
		}
		
		NSString *color = [_currentTag attributeForKey:@"color"];
		
		if (color)
		{
			_currentTag.textColor = [DTColor colorWithHTMLName:color];
		}
	};
	
	[_tagStartHandlers setObject:[fontBlock copy] forKey:@"font"];
	
	
	void (^pBlock)(void) = ^
	{
		_currentTag.paragraphStyle.firstLineHeadIndent = _currentTag.paragraphStyle.headIndent + _defaultParagraphStyle.firstLineHeadIndent;
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
		if ([_currentTag isKindOfClass:[DTTextAttachmentHTMLElement class]])
		{
			if ([_currentTag.textAttachment isKindOfClass:[DTObjectTextAttachment class]])
			{
				DTObjectTextAttachment *objectAttachment = (DTObjectTextAttachment *)_currentTag.textAttachment;
				
				// transfer the child nodes to the attachment
				objectAttachment.childNodes = [_currentTag.childNodes copy];
			}
		}
	};
	
	[_tagEndHandlers setObject:[objectBlock copy] forKey:@"object"];

	
	void (^styleBlock)(void) = ^
	{
		DTCSSStylesheet *localSheet = [(DTStylesheetHTMLElement *)_currentTag stylesheet];
		[_globalStyleSheet mergeStylesheet:localSheet];
	};
	
	[_tagEndHandlers setObject:[styleBlock copy] forKey:@"style"];
	
	
	void (^linkBlock)(void) = ^
	{
		NSString *href = [_currentTag attributeForKey:@"href"];
		NSString *type = [[_currentTag attributeForKey:@"type"] lowercaseString];
		
		if ([type isEqualToString:@"text/css"])
		{
			NSURL *stylesheetURL = [NSURL URLWithString:href relativeToURL:_baseURL];
			if ([stylesheetURL isFileURL])
			{
				NSString *stylesheetContent = [NSString stringWithContentsOfURL:stylesheetURL encoding:NSUTF8StringEncoding error:nil];
				if (stylesheetContent)
				{
					DTCSSStylesheet *localSheet = [[DTCSSStylesheet alloc] initWithStyleBlock:stylesheetContent];
					[_globalStyleSheet mergeStylesheet:localSheet];
				}
			}
			else {
				NSLog(@"WARNING: css link referencing a non-local target, ignored");
			}
		}
	};
	
	[ _tagEndHandlers setObject:[linkBlock copy] forKey:@"link"];
}

#pragma mark DTHTMLParser Delegate

- (void)parser:(DTHTMLParser *)parser didStartElement:(NSString *)elementName attributes:(NSDictionary *)attributeDict
{
	
	dispatch_group_async(_treeBuildingGroup, _treeBuildingQueue, ^{
		
		if (_ignoreParseEvents)
		{
			return;
		}

		DTHTMLElement *newNode = [DTHTMLElement elementWithName:elementName attributes:attributeDict options:_options];
		DTHTMLElement *previousLastChild = nil;
		
		if (_currentTag)
		{
			// inherit stuff
			[newNode inheritAttributesFromElement:_currentTag];
			[newNode interpretAttributes];
			
			previousLastChild = [_currentTag.childNodes lastObject];
			
			// add as new child of current node
			[_currentTag addChildNode:newNode];
			
			// remember body node
			if (!_bodyElement && [newNode.name isEqualToString:@"body"])
			{
				_bodyElement = newNode;
			}
		}
		else
		{
			NSAssert(!_rootNode, @"Something went wrong, second root node found in document and not ignored.");
			
			// might be first node ever
			if (!_rootNode)
			{
				_rootNode = newNode;
				
				[_rootNode inheritAttributesFromElement:_defaultTag];
				[_rootNode interpretAttributes];
			}
		}
		
		// apply style from merged style sheet
		NSDictionary *mergedStyles = [_globalStyleSheet mergedStyleDictionaryForElement:newNode];
		if (mergedStyles)
		{
			[newNode applyStyleDictionary:mergedStyles];
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
					[_currentTag removeChildNode:textElement];
				}
			}
		}
		
		_currentTag = newNode;
		
		// find block to execute for this tag if any
		void (^tagBlock)(void) = [_tagStartHandlers objectForKey:elementName];
		
		if (tagBlock)
		{
			tagBlock();
		}
	});
}

- (void)parser:(DTHTMLParser *)parser didEndElement:(NSString *)elementName
{

	dispatch_group_async(_treeBuildingGroup, _treeBuildingQueue, ^{
		
		if (_ignoreParseEvents)
		{
			return;
		}
		
		// output the element if it is direct descendant of body tag, or close of body in case there are direct text nodes
		
		// find block to execute for this tag if any
		void (^tagBlock)(void) = [_tagEndHandlers objectForKey:elementName];
		
		if (tagBlock)
		{
			tagBlock();
		}
		
		if (_currentTag.displayStyle != DTHTMLElementDisplayStyleNone)
		{
			if (_currentTag == _bodyElement || _currentTag.parentElement == _bodyElement)
			{
				DTHTMLElement *theTag = _currentTag;
				
				dispatch_group_async(_stringAssemblyGroup, _stringAssemblyQueue, ^{
					// has children that have not been output yet
					if ([theTag needsOutput])
					{
						// caller gets opportunity to modify tag before it is written
						if (_willFlushCallback)
						{
							_willFlushCallback(theTag);
						}
						
						NSAttributedString *nodeString = [theTag attributedString];
						
						if (nodeString)
						{
							// if this is a block element then we need a paragraph break before it
							if (theTag.displayStyle != DTHTMLElementDisplayStyleInline)
							{
								if ([_tmpString length] && ![[_tmpString string] hasSuffix:@"\n"])
								{
									// trim off whitespace
									while ([[_tmpString string] hasSuffixCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]])
									{
										[_tmpString deleteCharactersInRange:NSMakeRange([_tmpString length]-1, 1)];
									}
									
									[_tmpString appendString:@"\n"];
								}
							}
							
							[_tmpString appendAttributedString:nodeString];
							theTag.didOutput = YES;
							
							if (!_shouldKeepDocumentNodeTree)
							{
								// we don't need the children any more
								[theTag removeAllChildNodes];
							}
						}
						
					}
				});
			}
			
		}

		while (![_currentTag.name isEqualToString:elementName])
		{
			// missing end of element, attempt to recover
			_currentTag = [_currentTag parentElement];
		}
		
		// closing the root node, ignore everything afterwards
		if (_currentTag == _rootNode)
		{
			_ignoreParseEvents = YES;
		}

		// go back up a level
		_currentTag = [_currentTag parentElement];
	});
}

- (void)parser:(DTHTMLParser *)parser foundCharacters:(NSString *)string
{
	dispatch_group_async(_treeBuildingGroup, _treeBuildingQueue, ^{
		
		if (_ignoreParseEvents)
		{
			return;
		}
		
		NSAssert(_currentTag, @"Cannot add text node without a current node");
		
		if (!_currentTag.preserveNewlines && [string isIgnorableWhitespace])
		{
			// ignore whitespace as first element of block element
			if (_currentTag.displayStyle!=DTHTMLElementDisplayStyleInline && ![_currentTag.childNodes count])
			{
				return;
			}
			
			// ignore whitespace following a block element
			DTHTMLElement *previousTag = [_currentTag.childNodes lastObject];
			
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
		
		[textNode inheritAttributesFromElement:_currentTag];
		[textNode interpretAttributes];
		
		// save it for later output
		[_currentTag addChildNode:textNode];
		
		DTHTMLElement *theTag = _currentTag;
		
		// text directly contained in body needs to be output right away
		if (theTag == _bodyElement)
		{
			dispatch_group_async(_stringAssemblyGroup, _stringAssemblyQueue, ^{
				[_tmpString appendAttributedString:[textNode attributedString]];
				theTag.didOutput = YES;
			});
			
			// only add it to current tag if we need it
			if (_shouldKeepDocumentNodeTree)
			{
				[theTag addChildNode:textNode];
			}
			
			return;
		}
		
	});
}

- (void)parser:(DTHTMLParser *)parser foundCDATA:(NSData *)CDATABlock
{
	dispatch_group_async(_treeBuildingGroup, _treeBuildingQueue, ^{
		
		if (_ignoreParseEvents)
		{
			return;
		}
		
		NSAssert(_currentTag, @"Cannot add text node without a current node");
		
		NSString *styleBlock = [[NSString alloc] initWithData:CDATABlock encoding:NSUTF8StringEncoding];
		
		// adds a text node to the current node
		DTHTMLParserTextNode *textNode = [[DTHTMLParserTextNode alloc] initWithCharacters:styleBlock];
		
		[_currentTag addChildNode:textNode];
	});
}

- (void)parserDidEndDocument:(DTHTMLParser *)parser
{

	dispatch_group_async(_treeBuildingGroup, _treeBuildingQueue, ^{
		NSAssert(!_currentTag, @"Something went wrong, at end of document there is still an open node");

		dispatch_group_async(_stringAssemblyGroup, _stringAssemblyQueue, ^{
			// trim off white space at end
			while ([[_tmpString string] hasSuffixCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]])
			{
				[_tmpString deleteCharactersInRange:NSMakeRange([_tmpString length]-1, 1)];
			}
		});
	});
}

#pragma mark Properties

@synthesize willFlushCallback = _willFlushCallback;
@synthesize shouldKeepDocumentNodeTree = _shouldKeepDocumentNodeTree;

@end
