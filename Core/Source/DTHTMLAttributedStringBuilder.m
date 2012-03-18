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
- (void)_flushCurrentTagContent:(NSString *)tagContent;
- (void)_flushListPrefix;

@end


@implementation DTHTMLAttributedStringBuilder
{
	NSData *_data;
	NSDictionary *_options;
	
	// settings for parsing
	CGFloat textScale;
	DTColor *defaultLinkColor;
	DTCSSStylesheet *_globalStyleSheet;
	NSURL *baseURL;
	DTCoreTextFontDescriptor *defaultFontDescriptor;
	DTCoreTextParagraphStyle *defaultParagraphStyle;
	
	// parsing state, accessed from inside blocks
	NSMutableAttributedString *tmpString;
	NSMutableString *_currentTagContents;
	
	DTHTMLElement *currentTag;
	BOOL needsListItemStart;
	BOOL needsNewLineBefore;
	BOOL outputHasNewline;
	BOOL currentTagIsEmpty; // YES for each opened tag, NO for anything flushed including hr, br, img -> adds an extra NL for <p></p>
	
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

- (id)initWithHTML:(NSData *)data options:(NSDictionary *)options documentAttributes:(NSDictionary **)dict
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
	dispatch_release(_stringAssemblyQueue);
	dispatch_release(_stringAssemblyGroup);
	dispatch_release(_stringParsingQueue);
	dispatch_release(_stringParsingGroup);
}

- (BOOL)buildString
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
	textScale = [[_options objectForKey:NSTextSizeMultiplierDocumentOption] floatValue];
	if (!textScale)
	{
		textScale = 1.0f;
	}
	
	// use baseURL from options if present
	baseURL = [_options objectForKey:NSBaseURLDocumentOption];
	
	// the combined style sheet for entire document
	_globalStyleSheet = [DTCSSStylesheet defaultStyleSheet]; 
	
	// do we have a default style sheet passed as option?
	DTCSSStylesheet *defaultStylesheet = [_options objectForKey:DTDefaultStyleSheet];
	if (defaultStylesheet) 
	{
		// merge the default styles to the combined style sheet
		[_globalStyleSheet mergeStylesheet:defaultStylesheet];
	}
	
	// for performance we will return this mutable string
	tmpString = [[NSMutableAttributedString alloc] init];
	
	needsListItemStart = NO;
	needsNewLineBefore = NO;
	
	// base tag with font defaults
	defaultFontDescriptor = [[DTCoreTextFontDescriptor alloc] initWithFontAttributes:nil];
	defaultFontDescriptor.pointSize = 12.0f * textScale;
	
	NSString *defaultFontFamily = [_options objectForKey:DTDefaultFontFamily];
	if (defaultFontFamily)
	{
		defaultFontDescriptor.fontFamily = defaultFontFamily;
	}
	else
	{
		defaultFontDescriptor.fontFamily = @"Times New Roman";
	}
	
	defaultLinkColor = [_options objectForKey:DTDefaultLinkColor];
	
	if (defaultLinkColor)
	{
		if ([defaultLinkColor isKindOfClass:[NSString class]])
		{
			// convert from string to color
			defaultLinkColor = [DTColor colorWithHTMLName:(NSString *)defaultLinkColor];
		}
		
		// get hex code for t   he passed color
		NSString *colorHex = [defaultLinkColor htmlHexString];
		
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
	defaultParagraphStyle = [DTCoreTextParagraphStyle defaultParagraphStyle];
	
	NSNumber *defaultLineHeightMultiplierNum = [_options objectForKey:DTDefaultLineHeightMultiplier];
	
	if (defaultLineHeightMultiplierNum)
	{
		CGFloat defaultLineHeightMultiplier = [defaultLineHeightMultiplierNum floatValue];
		defaultParagraphStyle.lineHeightMultiple = defaultLineHeightMultiplier;
	}
	
	NSNumber *defaultTextAlignmentNum = [_options objectForKey:DTDefaultTextAlignment];
	
	if (defaultTextAlignmentNum)
	{
		defaultParagraphStyle.alignment = (CTTextAlignment)[defaultTextAlignmentNum integerValue];
	}
	
	NSNumber *defaultFirstLineHeadIndent = [_options objectForKey:DTDefaultFirstLineHeadIndent];
	if (defaultFirstLineHeadIndent)
	{
		defaultParagraphStyle.firstLineHeadIndent = [defaultFirstLineHeadIndent integerValue];
	}
	
	NSNumber *defaultHeadIndent = [_options objectForKey:DTDefaultHeadIndent];
	if (defaultHeadIndent)
	{
		defaultParagraphStyle.headIndent = [defaultHeadIndent integerValue];
	}
	
	NSNumber *defaultListIndent = [_options objectForKey:DTDefaultListIndent];
	if (defaultListIndent)
	{
		defaultParagraphStyle.listIndent = [defaultListIndent integerValue];
	}
	
	DTHTMLElement *defaultTag = [[DTHTMLElement alloc] init];
	defaultTag.fontDescriptor = defaultFontDescriptor;
	defaultTag.paragraphStyle = defaultParagraphStyle;
	defaultTag.textScale = textScale;
	
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
	
	
	currentTag = defaultTag; // our defaults are the root
	
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
	return tmpString;
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
		if (currentTag.floatStyle != DTHTMLElementFloatStyleNone)
		{
			currentTag.displayStyle = DTHTMLElementDisplayStyleBlock;
		}
		
		// hide contents of recognized tag
		currentTag.tagContentInvisible = YES;
		
		// make appropriate attachment
		DTTextAttachment *attachment = [DTTextAttachment textAttachmentWithElement:currentTag options:_options];
		
		// add it to tag
		currentTag.textAttachment = attachment;
		
		// to avoid much too much space before the image
		currentTag.paragraphStyle.lineHeightMultiple = 1;
		
		// specifiying line height interfers with correct positioning
		currentTag.paragraphStyle.minimumLineHeight = 0;
		currentTag.paragraphStyle.maximumLineHeight = 0;
		
		// caller gets opportunity to modify image tag before it is written
		if (_willFlushCallback)
		{
			_willFlushCallback(currentTag);
		}
		
		// maybe the image is forced to show as block, then we want a newline before and after
		if (currentTag.displayStyle == DTHTMLElementDisplayStyleBlock)
		{
			needsNewLineBefore = YES;
		}
		
		if (needsNewLineBefore)
		{
			if ([tmpString length] && !outputHasNewline)
			{
				[tmpString appendNakedString:@"\n"];
				outputHasNewline = YES;
			}
			
			needsNewLineBefore = NO;
		}
		
		// add it to output
		[tmpString appendAttributedString:[currentTag attributedString]];	
		outputHasNewline = NO;
		currentTagIsEmpty = NO;
	};
	
	[_tagStartHandlers setObject:[imgBlock copy] forKey:@"img"];
	
	
	void (^blockquoteBlock)(void) = ^ 
	{
		currentTag.paragraphStyle.headIndent += 25.0 * textScale;
		currentTag.paragraphStyle.firstLineHeadIndent = currentTag.paragraphStyle.headIndent;
		currentTag.paragraphStyle.paragraphSpacing = defaultFontDescriptor.pointSize;
	};
	
	[_tagStartHandlers setObject:[blockquoteBlock copy] forKey:@"blockquote"];
	
	
	void (^objectBlock)(void) = ^ 
	{
		// hide contents of recognized tag
		currentTag.tagContentInvisible = YES;
		
		// make appropriate attachment
		DTTextAttachment *attachment = [DTTextAttachment textAttachmentWithElement:currentTag options:_options];
		
		// add it to tag
		currentTag.textAttachment = attachment;
		
		// to avoid much too much space before the image
		currentTag.paragraphStyle.lineHeightMultiple = 1;
		
		// caller gets opportunity to modify object tag before it is written
		if (_willFlushCallback)
		{
			_willFlushCallback(currentTag);
		}
		
		// maybe the image is forced to show as block, then we want a newline before and after
		if (currentTag.displayStyle == DTHTMLElementDisplayStyleBlock)
		{
			needsNewLineBefore = YES;
		}
		
		if (needsNewLineBefore)
		{
			if ([tmpString length] && !outputHasNewline)
			{
				[tmpString appendNakedString:@"\n"];
				outputHasNewline = YES;
			}
			
			needsNewLineBefore = NO;
		}
		
		// add it to output
		[tmpString appendAttributedString:[currentTag attributedString]];
		outputHasNewline = NO;
		currentTagIsEmpty = NO;
	};
	
	[_tagStartHandlers setObject:[objectBlock copy] forKey:@"object"];
	[_tagStartHandlers setObject:[objectBlock copy] forKey:@"video"];
	[_tagStartHandlers setObject:[objectBlock copy] forKey:@"iframe"];
	
	
	void (^aBlock)(void) = ^ 
	{
		if (currentTag.isColorInherited || !currentTag.textColor)
		{
			currentTag.textColor = defaultLinkColor;
			currentTag.isColorInherited = NO;
		}
		
		// remove line breaks and whitespace in links
		NSString *cleanString = [[currentTag attributeForKey:@"href"] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
		cleanString = [cleanString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		
		NSURL *link = [NSURL URLWithString:cleanString];
		
		// deal with relative URL
		if (![link scheme])
		{
			if ([cleanString length])
			{
				link = [NSURL URLWithString:cleanString relativeToURL:baseURL];
				
				if (!link)
				{
					// NSURL did not like the link, so let's encode it
					cleanString = [cleanString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
					
					link = [NSURL URLWithString:cleanString relativeToURL:baseURL];
				}
			}
			else
			{
				link = baseURL;
			}
		}
		
		currentTag.link = link;
	};
	
	[_tagStartHandlers setObject:[aBlock copy] forKey:@"a"];
	
	
	void (^liBlock)(void) = ^ 
	{
		needsListItemStart = YES;
		currentTag.paragraphStyle.paragraphSpacing = 0;
		currentTag.paragraphStyle.firstLineHeadIndent = currentTag.paragraphStyle.headIndent;
		currentTag.paragraphStyle.headIndent += currentTag.paragraphStyle.listIndent;
		
		// first tab is to right-align bullet, numbering against
		CGFloat tabOffset = currentTag.paragraphStyle.headIndent - 5.0f*textScale;
		[currentTag.paragraphStyle addTabStopAtPosition:tabOffset alignment:kCTRightTextAlignment];
		
		// second tab is for the beginning of first line after bullet
		[currentTag.paragraphStyle addTabStopAtPosition:currentTag.paragraphStyle.headIndent alignment:	kCTLeftTextAlignment];			
	};
	
	[_tagStartHandlers setObject:[liBlock copy] forKey:@"li"];
	

	void (^listBlock)(void) = ^ 
	{
#if TARGET_OS_IPHONE		
		if (needsListItemStart)
		{
			// we have an opening but not have flushed text since
			needsNewLineBefore = YES;
			
			currentTag.paragraphStyle.paragraphSpacing = 0;
			
			if (needsNewLineBefore)
			{
				if (!outputHasNewline)
				{
					[tmpString appendString:@"\n"];
					outputHasNewline = YES;
				}
				
				needsNewLineBefore = NO;
			}
			
			// output the prefix
			[self _flushListPrefix];
		}
#endif		
		needsNewLineBefore = YES;
		
		// create the appropriate list style from CSS
		NSDictionary *styles = [currentTag styles];
		DTCSSListStyle *newListStyle = [[DTCSSListStyle alloc] initWithStyles:styles];
		
		// append this list style to the current paragraph style text lists
		NSMutableArray *textLists = [currentTag.paragraphStyle.textLists mutableCopy];
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
		
		currentTag.paragraphStyle.textLists = textLists;
		
		// next text needs a NL before it
		needsNewLineBefore = YES;
	};
	
	[_tagStartHandlers setObject:[listBlock copy] forKey:@"ul"];
	[_tagStartHandlers setObject:[listBlock copy] forKey:@"ol"];
	
	
	
	void (^hrBlock)(void) = ^ 
	{
		// open block needs closing
		if (needsNewLineBefore)
		{
			if ([tmpString length] && !outputHasNewline)
			{
				[tmpString appendString:@"\n"];
				outputHasNewline = YES;
			}
			
			needsNewLineBefore = NO;
		}
		
		currentTag.text = @"\n";
		
		NSMutableDictionary *styleDict = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"Dummy"];
		
		if (currentTag.backgroundColor)
		{
			[styleDict setObject:currentTag.backgroundColor forKey:@"BackgroundColor"];
		}
		[currentTag addAdditionalAttribute:styleDict forKey:DTHorizontalRuleStyleAttribute];
		
		[tmpString appendAttributedString:[currentTag attributedString]];
		outputHasNewline = YES;
		currentTagIsEmpty = NO;
	};
	
	[_tagStartHandlers setObject:[hrBlock copy] forKey:@"hr"];
	
	
	void (^h1Block)(void) = ^ 
	{
		currentTag.headerLevel = 1;
	};
	[_tagStartHandlers setObject:[h1Block copy] forKey:@"h1"];
	
	
	void (^h2Block)(void) = ^ 
	{
		currentTag.headerLevel = 2;
	};
	[_tagStartHandlers setObject:[h2Block copy] forKey:@"h2"];
	
	
	void (^h3Block)(void) = ^ 
	{
		currentTag.headerLevel = 3;
	};
	[_tagStartHandlers setObject:[h3Block copy] forKey:@"h3"];
	
	
	void (^h4Block)(void) = ^ 
	{
		currentTag.headerLevel = 4;
	};
	[_tagStartHandlers setObject:[h4Block copy] forKey:@"h4"];
	
	
	void (^h5Block)(void) = ^ 
	{
		currentTag.headerLevel = 5;
	};
	[_tagStartHandlers setObject:[h5Block copy] forKey:@"h5"];
	
	
	void (^h6Block)(void) = ^ 
	{
		currentTag.headerLevel = 6;
	};
	[_tagStartHandlers setObject:[h6Block copy] forKey:@"h6"];
	
	
	void (^fontBlock)(void) = ^ 
	{
		NSInteger size = [[currentTag attributeForKey:@"size"] intValue];
		
		switch (size) 
		{
			case 1:
				currentTag.fontDescriptor.pointSize = textScale * 9.0f;
				break;
			case 2:
				currentTag.fontDescriptor.pointSize = textScale * 10.0f;
				break;
			case 4:
				currentTag.fontDescriptor.pointSize = textScale * 14.0f;
				break;
			case 5:
				currentTag.fontDescriptor.pointSize = textScale * 18.0f;
				break;
			case 6:
				currentTag.fontDescriptor.pointSize = textScale * 24.0f;
				break;
			case 7:
				currentTag.fontDescriptor.pointSize = textScale * 37.0f;
				break;	
			case 3:
			default:
				currentTag.fontDescriptor.pointSize = defaultFontDescriptor.pointSize;
				break;
		}
		
		NSString *face = [currentTag attributeForKey:@"face"];
		
		if (face)
		{
			currentTag.fontDescriptor.fontName = face;
			
			// face usually invalidates family
			currentTag.fontDescriptor.fontFamily = nil; 
		}
		
		NSString *color = [currentTag attributeForKey:@"color"];
		
		if (color)
		{
			currentTag.textColor = [DTColor colorWithHTMLName:color];       
		}
	};
	
	[_tagStartHandlers setObject:[fontBlock copy] forKey:@"font"];
	
	
	void (^pBlock)(void) = ^ 
	{
		currentTag.paragraphStyle.firstLineHeadIndent = currentTag.paragraphStyle.headIndent + defaultParagraphStyle.firstLineHeadIndent;
	};
	
	[_tagStartHandlers setObject:[pBlock copy] forKey:@"p"];
	
	
	void (^brBlock)(void) = ^ 
	{
		currentTag.text = UNICODE_LINE_FEED;
		
		// NOTE: cannot use flush because that removes the break
		[tmpString appendAttributedString:[currentTag attributedString]];
		outputHasNewline = NO;
		currentTagIsEmpty = NO;
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
		if (needsNewLineBefore)
		{
			if ([tmpString length] && !outputHasNewline)
			{
				[tmpString appendString:@"\n"];
				outputHasNewline = YES;
			}
			
			needsNewLineBefore = NO;
		}
	};
	
	[_tagEndHandlers setObject:[bodyBlock copy] forKey:@"body"];
	
	
	void (^liBlock)(void) = ^ 
	{
		needsListItemStart = NO;
	};
	
	[_tagEndHandlers setObject:[liBlock copy] forKey:@"li"];
	
	
	void (^ulBlock)(void) = ^ 
	{
		// pop the current list style from the paragraph style text lists
		NSMutableArray *textLists = [currentTag.paragraphStyle.textLists mutableCopy];
		[textLists removeLastObject];
		currentTag.paragraphStyle.textLists = textLists;
		
		// if this was the last active list
		if ([textLists count]==0) 
		{
			// adjust spacing after last li to be the one defined for ol/ul
			NSInteger index = [tmpString length];
			
			if (index)
			{
				index--;
				
				// get the paragraph style for the previous paragraph
				NSRange effectiveRange;
				CTParagraphStyleRef prevParagraphStyle = (__bridge CTParagraphStyleRef)[tmpString attribute:(id)kCTParagraphStyleAttributeName
																									atIndex:index 
																							 effectiveRange:&effectiveRange];
				
				// convert it to DTCoreText
				DTCoreTextParagraphStyle *paragraphStyle = [DTCoreTextParagraphStyle paragraphStyleWithCTParagraphStyle:prevParagraphStyle];
				
				if (paragraphStyle.paragraphSpacing != currentTag.paragraphStyle.paragraphSpacing)
				{
					paragraphStyle.paragraphSpacing = currentTag.paragraphStyle.paragraphSpacing;
					
					CTParagraphStyleRef newParagraphStyle = [paragraphStyle createCTParagraphStyle];
					
					// because we have multiple paragraph styles per paragraph still, we need to extend towards the begin of the paragraph
					NSRange paragraphRange = [[tmpString string] rangeOfParagraphAtIndex:effectiveRange.location];
					
					[tmpString addAttribute:(id)kCTParagraphStyleAttributeName value:CFBridgingRelease(newParagraphStyle) range:paragraphRange];
				}
			}
		}
	};
	
	[_tagEndHandlers setObject:[ulBlock copy] forKey:@"ul"];
	[_tagEndHandlers setObject:[ulBlock copy] forKey:@"ol"];
	
	void (^pBlock)(void) = ^ 
	{
		if (currentTagIsEmpty)
		{
			// empty paragraph
			
			// end of P we always add a newline
			[tmpString appendString:@"\n" withParagraphStyle:currentTag.paragraphStyle fontDescriptor:currentTag.fontDescriptor];
		}
		else
		{
			// extend previous tag contents
			[tmpString appendString:@"\n"];
		}
		outputHasNewline = YES;
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
	// if we start a list, then we wait until we have actual text
	if (needsListItemStart)
	{
		DTCSSListStyle *effectiveList = [currentTag.paragraphStyle.textLists lastObject];
		
		NSInteger index = [tmpString length]-1;
		NSInteger counter = 0;
		
		if (index>0)
		{
			// check if there was a list item before this one
			index--;
			
			NSRange prevListRange;
			NSArray *prevLists = [tmpString attribute:DTTextListsAttribute atIndex:index effectiveRange:&prevListRange];
			
			if ([prevLists containsObject:effectiveList])
			{
				NSInteger prevItemIndex = [tmpString itemNumberInTextList:effectiveList atIndex:index];
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
		
		NSDictionary *tagAttributes = [currentTag attributesDictionary];
		NSAttributedString *prefixString = [NSAttributedString prefixForListItemWithCounter:counter listStyle:effectiveList attributes:tagAttributes];
		
		if (prefixString)
		{
			[tmpString appendAttributedString:prefixString]; 
			outputHasNewline = NO;
		}
		
		needsListItemStart = NO;
	}
}

- (void)_flushCurrentTagContent:(NSString *)tagContent
{
	NSAssert(dispatch_get_current_queue() == _stringAssemblyQueue, @"method called from invalid queue");
	
	// trim newlines
	NSString *tagContents = tagContent;
	
	if (![tagContents length])
	{
		// nothing to do
		return;
	}
	
	if (currentTag.preserveNewlines)
	{
		tagContents = [tagContent stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
		
		tagContents = [tagContents stringByReplacingOccurrencesOfString:@"\n" withString:UNICODE_LINE_FEED];
	}
	else
	{
		tagContents = [tagContents stringByNormalizingWhitespace];
		
		if ([tagContents isEqualToString:@" "])
		{
			return;
		}
	}
	
	if (needsNewLineBefore)
	{
		if ([tagContents hasPrefix:@" "])
		{
			tagContents = [tagContents substringFromIndex:1];
		}
		
		if ([tmpString length])
		{
			if (!outputHasNewline)
			{
				[tmpString appendString:@"\n"];
				outputHasNewline = YES;
			}
		}
		
		needsNewLineBefore = NO;
	}
	else // might be a continuation of a paragraph, then we might need space before it
	{
		NSString *stringSoFar = [tmpString string];
		
		// prevent double spacing
		if ([stringSoFar hasSuffixCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] && [tagContents hasPrefix:@" "])
		{
			tagContents = [tagContents substringFromIndex:1];
		}
	}
	
	// if we start a list, then we wait until we have actual text
	if (needsListItemStart && [tagContents length] > 0 && ![tagContents isEqualToString:@" "])
	{
		[self _flushListPrefix];
	}
	
	// we don't want whitespace before first tag to turn into paragraphs
	if (!(currentTag.displayStyle == DTHTMLElementDisplayStyleNone) && !currentTag.tagContentInvisible)
	{
		currentTag.text = tagContents;
		
		if (_willFlushCallback)
		{
			_willFlushCallback(currentTag);
		}
		
		[tmpString appendAttributedString:[currentTag attributedString]];
		outputHasNewline = NO;
		
		// we've written something
		currentTagIsEmpty = NO;
	}	
	
	_currentTagContents = nil;
}

#pragma mark DTHTMLParser Delegate

- (void)parser:(DTHTMLParser *)parser didStartElement:(NSString *)elementName attributes:(NSDictionary *)attributeDict
{
	void (^tmpBlock)(void) = ^
	{
		DTHTMLElement *parent = currentTag;
		DTHTMLElement *nextTag = [currentTag copy];
		nextTag.tagName = elementName;
		nextTag.textScale = textScale;
		nextTag.attributes = attributeDict;
		[parent addChild:nextTag];
		
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
				if (currentTag.displayStyle != DTHTMLElementDisplayStyleBlock)
				{
					[_currentTagContents removeTrailingWhitespace];
				}
				
				removeUnflushedWhitespace = YES;
			}
		}
		
		[self _flushCurrentTagContent:_currentTagContents];
		
		// avoid transfering space from parent tag
		if (removeUnflushedWhitespace)
		{
			_currentTagContents = nil;
		}
		
		// keep track of something was flushed for this tag
		currentTagIsEmpty = YES;
		
		// switch to new tag
		currentTag = nextTag;
		
		if (currentTag.displayStyle == DTHTMLElementDisplayStyleNone)
		{
			// we don't care about the other stuff in META tags, but styles are inherited
			return;
		}
		
		if (currentTag.displayStyle == DTHTMLElementDisplayStyleBlock || currentTag.displayStyle == DTHTMLElementDisplayStyleListItem)
		{
			// make sure that we have a NL before text in this block
			needsNewLineBefore = YES;
		}
		
		// direction
		NSString *direction = [currentTag attributeForKey:@"dir"];
		
		if (direction)
		{
			NSString *lowerDirection = [direction lowercaseString];
			
			
			if ([lowerDirection isEqualToString:@"ltr"])
			{
				currentTag.paragraphStyle.baseWritingDirection = kCTWritingDirectionLeftToRight;
			}
			else if ([lowerDirection isEqualToString:@"rtl"])
			{
				currentTag.paragraphStyle.baseWritingDirection = kCTWritingDirectionRightToLeft;
			}
		}
		
		// find block to execute for this tag if any
		void (^tagBlock)(void) = [_tagStartHandlers objectForKey:elementName];
		
		if (tagBlock)
		{
			tagBlock();
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
			if (currentTag.displayStyle != DTHTMLElementDisplayStyleInline)
			{
				[_currentTagContents removeTrailingWhitespace];
			}
			
			[self _flushCurrentTagContent:_currentTagContents];
		}
		
		// find block to execute for this tag if any
		void (^tagBlock)(void) = [_tagEndHandlers objectForKey:elementName];
		
		if (tagBlock)
		{
			tagBlock();
		}
		
		if (currentTag.displayStyle == DTHTMLElementDisplayStyleBlock)
		{
			needsNewLineBefore = YES;
		}
		
		// check if this tag is indeed closing the currently open one
		if ([elementName isEqualToString:currentTag.tagName])
		{
			DTHTMLElement *popChild = currentTag;
			currentTag = currentTag.parent;
			[currentTag removeChild:popChild];
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
		if ([currentTag.tagName isEqualToString:@"style"])
		{
			NSString *styleBlock = [[NSString alloc] initWithData:CDATABlock encoding:NSUTF8StringEncoding];
			[_globalStyleSheet parseStyleBlock:styleBlock];
		}
	});
}

#pragma mark Properties

@synthesize willFlushCallback = _willFlushCallback;

@end
