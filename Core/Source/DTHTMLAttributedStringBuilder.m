//
//  DTHTMLAttributedStringBuilder.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 21.01.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTCoreText.h"
#import "DTHTMLAttributedStringBuilder.h"

@interface DTHTMLAttributedStringBuilder ()

- (void)_registerTagStartHandlers;
- (void)_registerTagEndHandlers;
- (void)_flushCurrentTagContent:(NSString *)tagContent normalizeWhitespace:(BOOL)normalizeWhitespace;
- (void)_flushListPrefix;

@end


@implementation DTHTMLAttributedStringBuilder
{
	NSData *_data;
	NSDictionary *_options;
	
	// settings for parsing
	CGFloat _textScale;
	DTColor *_defaultLinkColor;
	DTCSSStylesheet *_globalStyleSheet;
	NSURL *_baseURL;
	DTCoreTextFontDescriptor *_defaultFontDescriptor;
	DTCoreTextParagraphStyle *_defaultParagraphStyle;
	
	// parsing state, accessed from inside blocks
	NSMutableAttributedString *_tmpString;
	NSMutableString *_currentTagContents;
	
	DTHTMLElement *_currentTag;
	BOOL _needsListItemStart;
	BOOL _needsNewLineBefore;
	BOOL _outputHasNewline;
	BOOL _currentTagIsEmpty; // YES for each opened tag, NO for anything flushed including hr, br, img -> adds an extra NL for <p></p>
	
	// GCD
	dispatch_queue_t _stringAssemblyQueue;
	dispatch_group_t _stringAssemblyGroup;
	dispatch_queue_t _stringParsingQueue;
	dispatch_group_t _stringParsingGroup;
	
	// lookup table for blocks that deal with begin and end tags
	NSMutableDictionary *_tagStartHandlers;
	NSMutableDictionary *_tagEndHandlers;
	
	DTHTMLAttributedStringBuilderWillFlushCallback _willFlushCallback;
}

- (id)initWithHTML:(NSData *)data options:(NSDictionary *)options documentAttributes:(NSDictionary **)docAttributes
{
	self = [super init];
	if (self)
	{
		_data = data;
		_options = options;
		
		// documentAttributes ignored for now
		
		//GCD setup
		_stringAssemblyQueue = dispatch_queue_create("DTHTMLAttributedStringBuilder", 0);
		_stringAssemblyGroup = dispatch_group_create();
		_stringParsingQueue = dispatch_queue_create("DTHTMLAttributedStringBuilderParser", 0);
		_stringParsingGroup = dispatch_group_create();
	}
	
	return self;	
}

- (void)dealloc 
{
	#if TARGET_API_MAC_OSX
		#if MAC_OS_X_VERSION_MIN_REQUIRED < 1080
			dispatch_release(_stringAssemblyQueue);
			dispatch_release(_stringAssemblyGroup);
			dispatch_release(_stringParsingQueue);
			dispatch_release(_stringParsingGroup);
		#endif
	#endif
}

- (BOOL)_buildString
{
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
	
	_needsListItemStart = NO;
	_needsNewLineBefore = NO;
	
	// base tag with font defaults
	_defaultFontDescriptor = [[DTCoreTextFontDescriptor alloc] initWithFontAttributes:nil];
	_defaultFontDescriptor.pointSize = 12.0f * _textScale;
	
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
	
	NSNumber *defaultListIndent = [_options objectForKey:DTDefaultListIndent];
	if (defaultListIndent)
	{
		_defaultParagraphStyle.listIndent = [defaultListIndent integerValue];
	}
	
	DTHTMLElement *defaultTag = [[DTHTMLElement alloc] init];
	defaultTag.fontDescriptor = _defaultFontDescriptor;
	defaultTag.paragraphStyle = _defaultParagraphStyle;
	defaultTag.textScale = _textScale;
	
	id defaultColor = [_options objectForKey:DTDefaultTextColor];
	if (defaultColor)
	{
		if ([defaultColor isKindOfClass:[DTColor class]])
		{
			// already a DTColor
			defaultTag.textColor = defaultColor;
		}
		else
		{
			// need to convert first
			defaultTag.textColor = [DTColor colorWithHTMLName:defaultColor];
		}
	}
	
	
	_currentTag = defaultTag; // our defaults are the root
	
	// create a parser
	DTHTMLParser *parser = [[DTHTMLParser alloc] initWithData:_data encoding:encoding];
	parser.delegate = (id)self;
	
	__block BOOL result;
	dispatch_group_async(_stringParsingGroup, _stringParsingQueue, ^{ result = [parser parse]; });
	
	// wait until all string assembly is complete
	dispatch_group_wait(_stringParsingGroup, DISPATCH_TIME_FOREVER);
	dispatch_group_wait(_stringAssemblyGroup, DISPATCH_TIME_FOREVER);
	
	// clean up handlers because they retained self
	_tagStartHandlers = nil;
	_tagEndHandlers = nil;
	
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
	
	void (^imgBlock)(void) = ^ 
	{
		// float causes the image to be its own block
		if (_currentTag.floatStyle != DTHTMLElementFloatStyleNone)
		{
			_currentTag.displayStyle = DTHTMLElementDisplayStyleBlock;
		}
		
		// hide contents of recognized tag
		_currentTag.tagContentInvisible = YES;
		
		// make appropriate attachment
		DTTextAttachment *attachment = [DTTextAttachment textAttachmentWithElement:_currentTag options:_options];
		
		// add it to tag
		_currentTag.textAttachment = attachment;
		
		// to avoid much too much space before the image
		_currentTag.paragraphStyle.lineHeightMultiple = 1;
		
		// specifiying line height interfers with correct positioning
		_currentTag.paragraphStyle.minimumLineHeight = 0;
		_currentTag.paragraphStyle.maximumLineHeight = 0;
		
		// caller gets opportunity to modify image tag before it is written
		if (_willFlushCallback)
		{
			_willFlushCallback(_currentTag);
		}
		
		// maybe the image is forced to show as block, then we want a newline before and after
		if (_currentTag.displayStyle == DTHTMLElementDisplayStyleBlock)
		{
			_needsNewLineBefore = YES;
		}
		
		if (_needsNewLineBefore)
		{
			if ([_tmpString length] && !_outputHasNewline)
			{
				[_tmpString appendNakedString:@"\n"];
				_outputHasNewline = YES;
			}
			
			_needsNewLineBefore = NO;
		}
		
		// add it to output
		[_tmpString appendAttributedString:[_currentTag attributedString]];	
		_outputHasNewline = NO;
		_currentTagIsEmpty = NO;
	};
	
	[_tagStartHandlers setObject:[imgBlock copy] forKey:@"img"];
	
	
	void (^blockquoteBlock)(void) = ^ 
	{
		_currentTag.paragraphStyle.headIndent += 25.0 * _textScale;
		_currentTag.paragraphStyle.firstLineHeadIndent = _currentTag.paragraphStyle.headIndent;
		_currentTag.paragraphStyle.paragraphSpacing = _defaultFontDescriptor.pointSize;
	};
	
	[_tagStartHandlers setObject:[blockquoteBlock copy] forKey:@"blockquote"];
	
	
	void (^objectBlock)(void) = ^ 
	{
		// hide contents of recognized tag
		_currentTag.tagContentInvisible = YES;
		
		// make appropriate attachment
		DTTextAttachment *attachment = [DTTextAttachment textAttachmentWithElement:_currentTag options:_options];
		
		// add it to tag
		_currentTag.textAttachment = attachment;
		
		// to avoid much too much space before the image
		_currentTag.paragraphStyle.lineHeightMultiple = 1;
		
		// caller gets opportunity to modify object tag before it is written
		if (_willFlushCallback)
		{
			_willFlushCallback(_currentTag);
		}
		
		// maybe the image is forced to show as block, then we want a newline before and after
		if (_currentTag.displayStyle == DTHTMLElementDisplayStyleBlock)
		{
			_needsNewLineBefore = YES;
		}
		
		if (_needsNewLineBefore)
		{
			if ([_tmpString length] && !_outputHasNewline)
			{
				[_tmpString appendNakedString:@"\n"];
				_outputHasNewline = YES;
			}
			
			_needsNewLineBefore = NO;
		}
		
		// add it to output
		[_tmpString appendAttributedString:[_currentTag attributedString]];
		_outputHasNewline = NO;
		_currentTagIsEmpty = NO;
	};
	
	[_tagStartHandlers setObject:[objectBlock copy] forKey:@"object"];
	[_tagStartHandlers setObject:[objectBlock copy] forKey:@"video"];
	[_tagStartHandlers setObject:[objectBlock copy] forKey:@"iframe"];
	
	
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
	
	
	void (^liBlock)(void) = ^ 
	{
		_needsListItemStart = YES;
		_currentTag.paragraphStyle.paragraphSpacing = 0;
		_currentTag.paragraphStyle.firstLineHeadIndent = _currentTag.paragraphStyle.headIndent;
		_currentTag.paragraphStyle.headIndent += _currentTag.paragraphStyle.listIndent;

		DTCSSListStyle *listStyle = [_currentTag.paragraphStyle.textLists lastObject];
		
		if (listStyle.type != DTCSSListStyleTypeNone)
		{
			// first tab is to right-align bullet, numbering against
			CGFloat tabOffset = _currentTag.paragraphStyle.headIndent - 5.0f*_textScale;
			[_currentTag.paragraphStyle addTabStopAtPosition:tabOffset alignment:kCTRightTextAlignment];
		}
		
		// second tab is for the beginning of first line after bullet
		[_currentTag.paragraphStyle addTabStopAtPosition:_currentTag.paragraphStyle.headIndent alignment:	kCTLeftTextAlignment];
	};
	
	[_tagStartHandlers setObject:[liBlock copy] forKey:@"li"];
	

	void (^listBlock)(void) = ^ 
	{
#if TARGET_OS_IPHONE		
		if (_needsListItemStart)
		{
			// we have an opening tag, but haven’t flushed the text since
			_needsNewLineBefore = YES;
			
			_currentTag.paragraphStyle.paragraphSpacing = 0;
			
			if (_needsNewLineBefore)
			{
				if (!_outputHasNewline)
				{
					[_tmpString appendString:@"\n"];
					_outputHasNewline = YES;
				}
				
				_needsNewLineBefore = NO;
			}
			
			// output the prefix
			[self _flushListPrefix];
		}
#endif		
		_needsNewLineBefore = YES;
		
		// create the appropriate list style from CSS
		NSDictionary *styles = [_currentTag styles];
		DTCSSListStyle *newListStyle = [[DTCSSListStyle alloc] initWithStyles:styles];
		
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
		
		// next text needs a NL inserted before it
		_needsNewLineBefore = YES;
	};
	
	[_tagStartHandlers setObject:[listBlock copy] forKey:@"ul"];
	[_tagStartHandlers setObject:[listBlock copy] forKey:@"ol"];
	
	
	
	void (^hrBlock)(void) = ^ 
	{
		// open block needs closing
		if (_needsNewLineBefore)
		{
			if ([_tmpString length] && !_outputHasNewline)
			{
				[_tmpString appendString:@"\n"];
				_outputHasNewline = YES;
			}
			
			_needsNewLineBefore = NO;
		}
		
		_currentTag.text = @"\n";
		
		NSMutableDictionary *styleDict = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"Dummy"];
		
		if (_currentTag.backgroundColor)
		{
			[styleDict setObject:_currentTag.backgroundColor forKey:DTBackgroundColorAttribute];
		}
		[_currentTag addAdditionalAttribute:styleDict forKey:DTHorizontalRuleStyleAttribute];
		
		[_tmpString appendAttributedString:[_currentTag attributedString]];
		_outputHasNewline = YES;
		_currentTagIsEmpty = NO;
	};
	
	[_tagStartHandlers setObject:[hrBlock copy] forKey:@"hr"];
	
	
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
		NSInteger size = [[_currentTag attributeForKey:@"size"] intValue];
		
		switch (size) 
		{
			case 1:
				_currentTag.fontDescriptor.pointSize = _textScale * 9.0f;
				break;
			case 2:
				_currentTag.fontDescriptor.pointSize = _textScale * 10.0f;
				break;
			case 4:
				_currentTag.fontDescriptor.pointSize = _textScale * 14.0f;
				break;
			case 5:
				_currentTag.fontDescriptor.pointSize = _textScale * 18.0f;
				break;
			case 6:
				_currentTag.fontDescriptor.pointSize = _textScale * 24.0f;
				break;
			case 7:
				_currentTag.fontDescriptor.pointSize = _textScale * 37.0f;
				break;	
			case 3:
			default:
				_currentTag.fontDescriptor.pointSize = _defaultFontDescriptor.pointSize;
				break;
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
	
	
	void (^brBlock)(void) = ^ 
	{
		_currentTag.text = UNICODE_LINE_FEED;
		
		// NOTE: cannot use flush because that removes the break
		[_tmpString appendAttributedString:[_currentTag attributedString]];
		_outputHasNewline = NO;
		_currentTagIsEmpty = NO;
	};
	
	[_tagStartHandlers setObject:[brBlock copy] forKey:@"br"];
}

- (void)_registerTagEndHandlers
{
	if (_tagEndHandlers)
	{
		return;
	}

	_tagEndHandlers = [[NSMutableDictionary alloc] init];
	
	void (^bodyBlock)(void) = ^ 
	{
		// if the last child was a block we need an extra \n
		if (_needsNewLineBefore)
		{
			if ([_tmpString length] && !_outputHasNewline)
			{
				[_tmpString appendString:@"\n"];
				_outputHasNewline = YES;
			}
			
			_needsNewLineBefore = NO;
		}
	};
	
	[_tagEndHandlers setObject:[bodyBlock copy] forKey:@"body"];
	
	
	void (^liBlock)(void) = ^ 
	{
		_needsListItemStart = NO;
	};
	
	[_tagEndHandlers setObject:[liBlock copy] forKey:@"li"];
	
	
	void (^ulBlock)(void) = ^ 
	{
		// pop the current list style from the paragraph style text lists
		NSMutableArray *textLists = [_currentTag.paragraphStyle.textLists mutableCopy];
		[textLists removeLastObject];
		_currentTag.paragraphStyle.textLists = textLists;
		
		// if this was the last active list
		if ([textLists count]==0) 
		{
			// adjust spacing after last li to be the one defined for ol/ul
			NSInteger index = [_tmpString length];
			
			if (index)
			{
				index--;
				
				// get the paragraph style for the previous paragraph
				NSRange effectiveRange;
				CTParagraphStyleRef prevParagraphStyle = (__bridge CTParagraphStyleRef)[_tmpString attribute:(id)kCTParagraphStyleAttributeName
																									atIndex:index 
																							 effectiveRange:&effectiveRange];
				
				// convert it to DTCoreText
				DTCoreTextParagraphStyle *paragraphStyle = [DTCoreTextParagraphStyle paragraphStyleWithCTParagraphStyle:prevParagraphStyle];
				
				if (paragraphStyle.paragraphSpacing != _currentTag.paragraphStyle.paragraphSpacing)
				{
					paragraphStyle.paragraphSpacing = _currentTag.paragraphStyle.paragraphSpacing;
					
					CTParagraphStyleRef newParagraphStyle = [paragraphStyle createCTParagraphStyle];
					
					// because we have multiple paragraph styles per paragraph still, we need to extend towards the begin of the paragraph
					NSRange paragraphRange = [[_tmpString string] rangeOfParagraphAtIndex:effectiveRange.location];
					
					// iOS 4.3 bug: need to remove previous attribute or else CTParagraphStyleRef leaks
					[_tmpString removeAttribute:(id)kCTParagraphStyleAttributeName range:paragraphRange];
					
					[_tmpString addAttribute:(id)kCTParagraphStyleAttributeName value:CFBridgingRelease(newParagraphStyle) range:paragraphRange];
				}
			}
		}
	};
	
	[_tagEndHandlers setObject:[ulBlock copy] forKey:@"ul"];
	[_tagEndHandlers setObject:[ulBlock copy] forKey:@"ol"];
	
	void (^pBlock)(void) = ^ 
	{
		if (_currentTagIsEmpty)
		{
			// empty paragraph
			
			// end of P we always add a newline
			[_tmpString appendString:@"\n" withParagraphStyle:_currentTag.paragraphStyle fontDescriptor:_currentTag.fontDescriptor];
		}
		else
		{
			// extend previous tag contents
			[_tmpString appendString:@"\n"];
		}
		_outputHasNewline = YES;
	};
	
	[_tagEndHandlers setObject:[pBlock copy] forKey:@"p"];
}

- (void)_handleTagContent:(NSString *)string
{
	NSAssert(dispatch_get_current_queue() == _stringAssemblyQueue, @"method called from invalid queue");
	
	if (!_currentTagContents)
	{
		_currentTagContents = [[NSMutableString alloc] initWithCapacity:1000];
	}
	
	[_currentTagContents appendString:string];
}


- (void)_flushListPrefix
{
	// if we start a list, we need to wait until we have the actual text
	if (_needsListItemStart)
	{
		DTCSSListStyle *effectiveList = [_currentTag.paragraphStyle.textLists lastObject];
		
		NSInteger index = [_tmpString length]-1;
		NSInteger counter = 0;
		
		if (index>0)
		{
			// check if there was a list item before this one
			index--;
			
			NSRange prevListRange;
			NSArray *prevLists = [_tmpString attribute:DTTextListsAttribute atIndex:index effectiveRange:&prevListRange];
			
			if ([prevLists containsObject:effectiveList])
			{
				NSInteger prevItemIndex = [_tmpString itemNumberInTextList:effectiveList atIndex:index];
				counter = prevItemIndex + 1;
			}
			else
			{
				// new list start
				counter = [effectiveList startingItemNumber];
			}
		}
		else
		{
			// new list start at beginning of string
			counter = [effectiveList startingItemNumber];
		}
		
		NSDictionary *tagAttributes = [_currentTag attributesDictionary];
		NSAttributedString *prefixString = [NSAttributedString prefixForListItemWithCounter:counter listStyle:effectiveList listIndent:_currentTag.paragraphStyle.listIndent attributes:tagAttributes];
		
		if (prefixString)
		{
			[_tmpString appendAttributedString:prefixString]; 
			_outputHasNewline = NO;
		}
		
		_needsListItemStart = NO;
	}
}

- (void)_flushCurrentTagContent:(NSString *)tagContent normalizeWhitespace:(BOOL)normalizeWhitespace
{
	NSAssert(dispatch_get_current_queue() == _stringAssemblyQueue, @"method called from invalid queue");
	
	// trim newlines
	NSString *tagContents = tagContent;
	
	if (![tagContents length])
	{
		// nothing to do
		return;
	}
	
	if (_currentTag.preserveNewlines)
	{
		tagContents = [tagContent stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
		
		tagContents = [tagContents stringByReplacingOccurrencesOfString:@"\n" withString:UNICODE_LINE_FEED];
	}
	else
	{
		if (normalizeWhitespace)
		{
			tagContents = [tagContents stringByNormalizingWhitespace];
		
			if ([tagContents isEqualToString:@" "])
			{
				return;
			}
		}
	}
	
	if (_needsNewLineBefore)
	{
		if ([tagContents hasPrefix:@" "])
		{
			tagContents = [tagContents substringFromIndex:1];
		}
		
		if ([_tmpString length])
		{
			if (!_outputHasNewline)
			{
				[_tmpString appendString:@"\n"];
				_outputHasNewline = YES;
			}
		}
		
		_needsNewLineBefore = NO;
	}
	else // might be a continuation of a paragraph, then we might need space before it
	{
		NSString *stringSoFar = [_tmpString string];
		
		// prevent double spacing
		if ([stringSoFar hasSuffixCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] && [tagContents hasPrefix:@" "])
		{
			tagContents = [tagContents substringFromIndex:1];
		}
	}
	
	// if we start a list, then we wait until we have actual text
	if (_needsListItemStart && [tagContents length] > 0 && ![tagContents isEqualToString:@" "])
	{
		[self _flushListPrefix];
	}
	
	// we don't want whitespace before first tag to turn into paragraphs
	if (!(_currentTag.displayStyle == DTHTMLElementDisplayStyleNone) && !_currentTag.tagContentInvisible)
	{
		_currentTag.text = tagContents;
		
		if (_willFlushCallback)
		{
			_willFlushCallback(_currentTag);
		}
		
		[_tmpString appendAttributedString:[_currentTag attributedString]];
		_outputHasNewline = NO;
		
		// we've written something
		_currentTagIsEmpty = NO;
	}	
	
	_currentTagContents = nil;
}

#pragma mark DTHTMLParser Delegate

- (void)parser:(DTHTMLParser *)parser didStartElement:(NSString *)elementName attributes:(NSDictionary *)attributeDict
{
	void (^tmpBlock)(void) = ^
	{
		// this brute-force inherits the nextTags attributes from the previous tag
		DTHTMLElement *parent = _currentTag;
		DTHTMLElement *nextTag = [_currentTag copy];
		nextTag.tagName = elementName;
		nextTag.textScale = _textScale;
		nextTag.attributes = attributeDict;
		[parent addChild:nextTag];
		
		// only inherit background-color from inline elements
		if (parent.displayStyle == DTHTMLElementDisplayStyleInline)
		{
			nextTag.backgroundColor = _currentTag.backgroundColor;
		}
		
		// apply style from merged style sheet
		NSDictionary *mergedStyles = [_globalStyleSheet mergedStyleDictionaryForElement:nextTag];
		if (mergedStyles)
		{
			[nextTag applyStyleDictionary:mergedStyles];
		}
		
		BOOL removeUnflushedWhitespace = NO;
		
		// keep currentTag, might be used in flush
		if (_currentTagContents)
		{
			// remove whitespace suffix in current non-block item
			if (nextTag.displayStyle == DTHTMLElementDisplayStyleBlock)
			{
				if (_currentTag.displayStyle != DTHTMLElementDisplayStyleBlock)
				{
					[_currentTagContents removeTrailingWhitespace];
				}
				
				removeUnflushedWhitespace = YES;
			}
		}
		
		[self _flushCurrentTagContent:_currentTagContents normalizeWhitespace:YES];
		
		// avoid transfering space from parent tag
		if (removeUnflushedWhitespace)
		{
			_currentTagContents = nil;
		}
		
		// keep track if something was flushed for this tag
		_currentTagIsEmpty = YES;
		
		// switch to new tag
		_currentTag = nextTag;
		
		if (_currentTag.displayStyle == DTHTMLElementDisplayStyleNone)
		{
			// we don't care about the other stuff in META tags, but styles are inherited
			return;
		}
		
		if (_currentTag.displayStyle == DTHTMLElementDisplayStyleBlock || _currentTag.displayStyle == DTHTMLElementDisplayStyleListItem)
		{
			// make sure that we have a NL before text in this block
			_needsNewLineBefore = YES;
		}
		
		// direction
		NSString *direction = [_currentTag attributeForKey:@"dir"];
		
		if (direction)
		{
			NSString *lowerDirection = [direction lowercaseString];
			
			
			if ([lowerDirection isEqualToString:@"ltr"])
			{
				_currentTag.paragraphStyle.baseWritingDirection = kCTWritingDirectionLeftToRight;
			}
			else if ([lowerDirection isEqualToString:@"rtl"])
			{
				_currentTag.paragraphStyle.baseWritingDirection = kCTWritingDirectionRightToLeft;
			}
		}
		
		// find block to execute for this tag if any
		void (^tagBlock)(void) = [_tagStartHandlers objectForKey:elementName];
		
		if (tagBlock)
		{
			tagBlock();
		}
		
		// output tag content before pseudo-selector
		if (_currentTag.beforeContent)
		{
			[self _flushCurrentTagContent:_currentTag.beforeContent normalizeWhitespace:NO];
		}
	};
	
	dispatch_group_async(_stringAssemblyGroup, _stringAssemblyQueue, tmpBlock);
}

- (void)parser:(DTHTMLParser *)parser didEndElement:(NSString *)elementName
{
	void (^tmpBlock)(void) = ^
	{
		if (_currentTagContents)
		{
			// trim off white space at end if block
			if (_currentTag.displayStyle != DTHTMLElementDisplayStyleInline)
			{
				[_currentTagContents removeTrailingWhitespace];
			}
			
			[self _flushCurrentTagContent:_currentTagContents normalizeWhitespace:YES];
		}
		
		// find block to execute for this tag if any
		void (^tagBlock)(void) = [_tagEndHandlers objectForKey:elementName];
		
		if (tagBlock)
		{
			tagBlock();
		}
		
		if (_currentTag.displayStyle == DTHTMLElementDisplayStyleBlock)
		{
			_needsNewLineBefore = YES;
		}
		
		// check if this tag is indeed closing the currently open one
		if ([elementName isEqualToString:_currentTag.tagName])
		{
			DTHTMLElement *popChild = _currentTag;
			_currentTag = _currentTag.parent;
			[_currentTag removeChild:popChild];
		}
		else 
		{
			// Ignoring non-open tag
		}
	};
	
	dispatch_group_async(_stringAssemblyGroup, _stringAssemblyQueue, tmpBlock);
}

- (void)parser:(DTHTMLParser *)parser foundCharacters:(NSString *)string
{
	dispatch_group_async(_stringAssemblyGroup, _stringAssemblyQueue,^{
		[self _handleTagContent:string];	
	});
}

- (void)parser:(DTHTMLParser *)parser foundCDATA:(NSData *)CDATABlock
{
	dispatch_group_async(_stringAssemblyGroup, _stringAssemblyQueue,^{
		if ([_currentTag.tagName isEqualToString:@"style"])
		{
			NSString *styleBlock = [[NSString alloc] initWithData:CDATABlock encoding:NSUTF8StringEncoding];
			[_globalStyleSheet parseStyleBlock:styleBlock];
		}
	});
}

#pragma mark Properties

@synthesize willFlushCallback = _willFlushCallback;

@end
