//
//  DTHTMLDocument.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 21.01.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTHTMLAttributedStringBuilder.h"
#import "DTHTMLParser.h"

#import "NSString+UTF8Cleaner.h"
#import "NSString+HTML.h"
#import "UIColor+HTML.h"
#import "DTCSSStylesheet.h"

#import "DTCoreTextConstants.h"

#import "DTCoreTextFontDescriptor.h"
#import "DTCoreTextParagraphStyle.h"
#import "DTHTMLElement.h"
#import "DTTextAttachment.h"

#import "NSMutableAttributedString+HTML.h"


@implementation DTHTMLAttributedStringBuilder
{
	NSData *_data;
	NSDictionary *_options;
	
	// settings for parsing
	CGFloat textScale;
	UIColor *defaultLinkColor;
	DTCSSStylesheet *_globalStyleSheet;
	NSURL *baseURL;
	DTCoreTextFontDescriptor *defaultFontDescriptor;
	DTCoreTextParagraphStyle *defaultParagraphStyle;
	
	// parsing state
	NSMutableAttributedString *tmpString;
	
	DTHTMLElement *currentTag;
	CGFloat nextParagraphAdditionalSpaceBefore;
	BOOL needsListItemStart;
	BOOL needsNewLineBefore;
	BOOL immediatelyClosed; 
}

- (id)initWithHTML:(NSData *)data options:(NSDictionary *)options documentAttributes:(NSDictionary **)dict
{
	self = [super init];
	if (self)
	{
		_data = data;
		_options = options;
		
		// documentAttributes ignored for now
	}
	
	return self;	
}

- (BOOL)buildString
{
	// only with valid data
	if (![_data length])
	{
		return NO;
	}
	
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
	
	
	// Make it a string
	NSString *htmlString;
	
	if (encoding == NSUTF8StringEncoding)
	{
		// this method can fix malformed UTF8
		htmlString = [[NSString alloc] initWithPotentiallyMalformedUTF8Data:_data];
	}
	else
	{
		// use the specified encoding
		htmlString = [[NSString alloc] initWithData:_data encoding:encoding];
	}
	
	if (!htmlString)
	{
		return NO;
	}
	
	// the combined style sheet for entire document
	_globalStyleSheet = [[DTCSSStylesheet alloc] init]; 
	
	// default styles
	[_globalStyleSheet parseStyleBlock:@"ul {list-style:disc;} ol {list-style:decimal;}"];
	[_globalStyleSheet parseStyleBlock:@"code {font-family: Courier;} pre {font-family: Courier;}"];
	[_globalStyleSheet parseStyleBlock:@"a {color:#0000EE;text-decoration:underline;}"];
	
	// do we have a default style sheet passed as option?
	DTCSSStylesheet *defaultStylesheet = [_options objectForKey:DTDefaultStyleSheet];
	if (defaultStylesheet) 
	{
		// merge the default styles to the combined style sheet
		[_globalStyleSheet mergeStylesheet:defaultStylesheet];
	}
	
	// for performance we will return this mutable string
	tmpString = [[NSMutableAttributedString alloc] init];
	
#if ALLOW_IPHONE_SPECIAL_CASES
	nextParagraphAdditionalSpaceBefore = 0.0;
#endif
	needsListItemStart = NO;
	needsNewLineBefore = NO;
	
	// we cannot skip any characters, NLs turn into spaces and multi-spaces get compressed to singles
	NSScanner *scanner = [NSScanner scannerWithString:htmlString];
	scanner.charactersToBeSkipped = nil;
	
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
			defaultLinkColor = [UIColor colorWithHTMLName:(NSString *)defaultLinkColor];
		}
		
		// get hex code for the passed color
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
		defaultParagraphStyle.textAlignment = (CTTextAlignment)[defaultTextAlignmentNum integerValue];
	}
	
	NSNumber *defaultFirstLineHeadIndent = [_options objectForKey:DTDefaultFirstLineHeadIndent];
	if (defaultFirstLineHeadIndent)
	{
		defaultParagraphStyle.firstLineIndent = [defaultFirstLineHeadIndent integerValue];
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
		if ([defaultColor isKindOfClass:[UIColor class]])
		{
			// already a UIColor
			defaultTag.textColor = defaultColor;
		}
		else
		{
			// need to convert first
			defaultTag.textColor = [UIColor colorWithHTMLName:defaultColor];
		}
	}
	
	
	currentTag = defaultTag; // our defaults are the root
	
	// create a parser
	DTHTMLParser *parser = [[DTHTMLParser alloc] initWithData:_data encoding:encoding];
	parser.delegate = (id)self;
	
	return [parser parse];
}

- (NSAttributedString *)generatedAttributedString
{
	return tmpString;
}

- (void)parser:(DTHTMLParser *)parser didStartElement:(NSString *)elementName attributes:(NSDictionary *)attributeDict
{
	// make new tag as copy of previous tag
	DTHTMLElement *parent = currentTag;
	currentTag = [currentTag copy];
	currentTag.tagName = elementName;
	currentTag.textScale = textScale;
	currentTag.attributes = attributeDict;
	[parent addChild:currentTag];
	
	// apply style from merged style sheet
	NSDictionary *mergedStyles = [_globalStyleSheet mergedStyleDictionaryForElement:currentTag];
	if (mergedStyles)
	{
		[currentTag applyStyleDictionary:mergedStyles];
	}
	
	if ([elementName isMetaTag])
	{
		// we don't care about the other stuff in META tags, but styles are inherited
		return;
	}
	
	// direction
	NSString *direction = [currentTag attributeForKey:@"dir"];
	
	if (direction)
	{
		NSString *lowerDirection = [direction lowercaseString];
		
		
		if ([lowerDirection isEqualToString:@"ltr"])
		{
			currentTag.paragraphStyle.writingDirection = kCTWritingDirectionLeftToRight;
		}
		else if ([lowerDirection isEqualToString:@"rtl"])
		{
			currentTag.paragraphStyle.writingDirection = kCTWritingDirectionRightToLeft;
		}
	}
	
	if ([elementName isEqualToString:@"img"])
	{
		immediatelyClosed = YES;
		
		if (![currentTag.parent.tagName isEqualToString:@"p"])
		{
			needsNewLineBefore = YES;
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
		
		if (needsNewLineBefore)
		{
			if ([tmpString length] && ![[tmpString string] hasSuffix:@"\n"])
			{
				[tmpString appendNakedString:@"\n"];
			}
			
			needsNewLineBefore = NO;
		}
		
		// add it to output
		[tmpString appendAttributedString:[currentTag attributedString]];				
	}
	else if ([elementName isEqualToString:@"blockquote"])
	{
		currentTag.paragraphStyle.headIndent += 25.0 * textScale;
		currentTag.paragraphStyle.firstLineIndent = currentTag.paragraphStyle.headIndent;
		currentTag.paragraphStyle.paragraphSpacing = defaultFontDescriptor.pointSize;
	}
	else if (([elementName isEqualToString:@"iframe"] || [elementName isEqualToString:@"video"] || [elementName isEqualToString:@"object"]))
	{
		// hide contents of recognized tag
		currentTag.tagContentInvisible = YES;
		
		// make appropriate attachment
		DTTextAttachment *attachment = [DTTextAttachment textAttachmentWithElement:currentTag options:_options];
		
		// add it to tag
		currentTag.textAttachment = attachment;
		
		// to avoid much too much space before the image
		currentTag.paragraphStyle.lineHeightMultiple = 1;
		
		// add it to output
		[tmpString appendAttributedString:[currentTag attributedString]];
	}
	else if ([elementName isEqualToString:@"a"])
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
	}
	else if ([elementName isEqualToString:@"b"] || [elementName isEqualToString:@"strong"])
	{
		currentTag.fontDescriptor.boldTrait = YES;
	}
	else if ([elementName isEqualToString:@"i"] || [elementName isEqualToString:@"em"])
	{
		currentTag.fontDescriptor.italicTrait = YES;
	}
	else if ([elementName isEqualToString:@"li"]) 
	{
		// have inherited the correct list counter from parent
		DTHTMLElement *counterElement = currentTag.parent;
		
		NSString *valueNum = [currentTag attributeForKey:@"value"];
		if (valueNum)
		{
			NSInteger value = [valueNum integerValue];
			counterElement.listCounter = value;
			currentTag.listCounter = value;
		}
		
		counterElement.listCounter++;
		
		needsListItemStart = YES;
		currentTag.paragraphStyle.paragraphSpacing = 0;
		currentTag.paragraphStyle.firstLineIndent = currentTag.paragraphStyle.headIndent;
		currentTag.paragraphStyle.headIndent += currentTag.paragraphStyle.listIndent;
		
		// first tab is to right-align bullet, numbering against
		CGFloat tabOffset = currentTag.paragraphStyle.headIndent - 5.0f*textScale;
		[currentTag.paragraphStyle addTabStopAtPosition:tabOffset alignment:kCTRightTextAlignment];
		
		// second tab is for the beginning of first line after bullet
		[currentTag.paragraphStyle addTabStopAtPosition:currentTag.paragraphStyle.headIndent alignment:	kCTLeftTextAlignment];			
	}
	else if ([elementName isEqualToString:@"left"])
	{
		currentTag.paragraphStyle.textAlignment = kCTLeftTextAlignment;
	}
	else if ([elementName isEqualToString:@"center"])
	{
		currentTag.paragraphStyle.textAlignment = kCTCenterTextAlignment;
	}
	else if ([elementName isEqualToString:@"right"])
	{
		currentTag.paragraphStyle.textAlignment = kCTRightTextAlignment;
	}
	else if ([elementName isEqualToString:@"del"] || [elementName isEqualToString:@"strike"] ) 
	{
		currentTag.strikeOut = YES;
	}
	else if ([elementName isEqualToString:@"ol"]) 
	{
		NSString *valueNum = [currentTag attributeForKey:@"start"];
		if (valueNum)
		{
			NSInteger value = [valueNum integerValue];
			currentTag.listCounter = value;
		}
		else
		{
			currentTag.listCounter = 1;
		}
		
		needsNewLineBefore = YES;
	}
	else if ([elementName isEqualToString:@"ul"]) 
	{
		needsNewLineBefore = YES;
		
		currentTag.listCounter = 0;
	}
	
	else if ([elementName isEqualToString:@"u"])
	{
		currentTag.underlineStyle = kCTUnderlineStyleSingle;
	}
	else if ([elementName isEqualToString:@"sup"])
	{
		currentTag.superscriptStyle = 1;
		currentTag.fontDescriptor.pointSize *= 0.83;
	}
	else if ([elementName isEqualToString:@"pre"])
	{
		currentTag.preserveNewlines = YES;
		currentTag.paragraphStyle.textAlignment = kCTNaturalTextAlignment;
	}
	else if ([elementName isEqualToString:@"code"]) 
	{
	}
	else if ([elementName isEqualToString:@"sub"])
	{
		currentTag.superscriptStyle = -1;
		currentTag.fontDescriptor.pointSize *= 0.83;
	}
	else if ([elementName isEqualToString:@"hr"])
	{
		immediatelyClosed = YES;
		
		// open block needs closing
		if (needsNewLineBefore)
		{
			if ([tmpString length] && ![[tmpString string] hasSuffix:@"\n"])
			{
				[tmpString appendNakedString:@"\n"];
			}
			
			needsNewLineBefore = NO;
		}
		
		currentTag.text = @"\n";
		
		NSMutableDictionary *styleDict = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"Dummy"];
		
		if (currentTag.backgroundColor)
		{
			[styleDict setObject:currentTag.backgroundColor forKey:@"BackgroundColor"];
		}
		[currentTag addAdditionalAttribute:styleDict forKey:@"DTHorizontalRuleStyle"];
		
		[tmpString appendAttributedString:[currentTag attributedString]];
	}
	else if ([elementName hasPrefix:@"h"])
	{
		NSString *levelString = [elementName substringFromIndex:1];
		
		NSInteger headerLevel = [levelString integerValue];
		
		if (headerLevel)
		{
			currentTag.headerLevel = headerLevel;
			currentTag.fontDescriptor.boldTrait = YES;
			
			switch (headerLevel) 
			{
				case 1:
				{
					// H1: 2 em, spacing before 0.67 em, after 0.67 em
					currentTag.fontDescriptor.pointSize *= 2.0;
					currentTag.paragraphStyle.paragraphSpacing = 0.67f * currentTag.fontDescriptor.pointSize;
					break;
				}
				case 2:
				{
					// H2: 1.5 em, spacing before 0.83 em, after 0.83 em
					currentTag.fontDescriptor.pointSize *= 1.5;
					currentTag.paragraphStyle.paragraphSpacing = 0.83f * currentTag.fontDescriptor.pointSize;
					break;
				}
				case 3:
				{
					// H3: 1.17 em, spacing before 1 em, after 1 em
					currentTag.fontDescriptor.pointSize *= 1.17;
					currentTag.paragraphStyle.paragraphSpacing = 1.0f * currentTag.fontDescriptor.pointSize;
					break;
				}
				case 4:
				{
					// H4: 1 em, spacing before 1.33 em, after 1.33 em
					currentTag.paragraphStyle.paragraphSpacing = 1.33f * currentTag.fontDescriptor.pointSize;
					break;
				}
				case 5:
				{
					// H5: 0.83 em, spacing before 1.67 em, after 1.167 em
					currentTag.fontDescriptor.pointSize *= 0.83;
					currentTag.paragraphStyle.paragraphSpacing = 1.67f * currentTag.fontDescriptor.pointSize;
					break;
				}
				case 6:
				{
					// H6: 0.67 em, spacing before 2.33 em, after 2.33 em
					currentTag.fontDescriptor.pointSize *= 0.67;
					currentTag.paragraphStyle.paragraphSpacing = 2.33f * currentTag.fontDescriptor.pointSize;
					break;
				}
				default:
					break;
			}
		}
	}
	else if ([elementName isEqualToString:@"big"])
	{
		currentTag.fontDescriptor.pointSize *= 1.2;
	}
	else if ([elementName isEqualToString:@"small"])
	{
		currentTag.fontDescriptor.pointSize /= 1.2;
	}
	else if ([elementName isEqualToString:@"font"])
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
			currentTag.textColor = [UIColor colorWithHTMLName:color];       
		}
	}
	else if ([elementName isEqualToString:@"p"])
	{
		currentTag.paragraphStyle.paragraphSpacing = defaultFontDescriptor.pointSize;
		currentTag.paragraphStyle.firstLineIndent = currentTag.paragraphStyle.headIndent + defaultParagraphStyle.firstLineIndent;
	}
	else if ([elementName isEqualToString:@"br"])
	{
		immediatelyClosed = YES; 
		
		currentTag.text = UNICODE_LINE_FEED;
		[tmpString appendAttributedString:[currentTag attributedString]];
	}
}

- (void)parser:(DTHTMLParser *)parser didEndElement:(NSString *)elementName
{
	if ([elementName isMetaTag])
	{
		return;
	}
	
	if (![currentTag isInline])
	{
		// next text needs a NL
		needsNewLineBefore = YES;
	}
	
	if ([elementName isEqualToString:@"li"])
	{
		needsListItemStart = NO;
	}
	else if ([elementName isEqualToString:@"ol"]) 
	{
#if ALLOW_IPHONE_SPECIAL_CASES
		if (currentTag.listDepth < 1)
			nextParagraphAdditionalSpaceBefore = defaultFontDescriptor.pointSize;
#endif
	}
	else if ([elementName isEqualToString:@"ul"]) 
	{
#if ALLOW_IPHONE_SPECIAL_CASES
		if (currentTag.listDepth < 1)
			nextParagraphAdditionalSpaceBefore = defaultFontDescriptor.pointSize;
#endif
	}
	
	// block items have to have a NL at the end.
	if (![currentTag isInline] && ![currentTag isMeta] && ![[tmpString string] hasSuffix:@"\n"] /* && ![[tmpString string] hasSuffix:UNICODE_OBJECT_PLACEHOLDER] */)
	{
		if ([tmpString length])
		{
			[tmpString appendString:@"\n"];  // extends attributed area at end
		}
		else
		{
			currentTag.text = @"\n";
			[tmpString appendAttributedString:[currentTag attributedString]];
		}
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
}

- (void)parser:(DTHTMLParser *)parser foundCharacters:(NSString *)string
{
	// trim newlines
	NSString *tagContents = [string stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	
	if (![tagContents length])
	{
		// nothing to do
		return;
	}

	if (currentTag.preserveNewlines)
	{
		tagContents = [tagContents stringByReplacingOccurrencesOfString:@"\n" withString:UNICODE_LINE_FEED];
	}
	else
	{
		tagContents = [tagContents stringByNormalizingWhitespace];
	}
	
#if ALLOW_IPHONE_SPECIAL_CASES				
	if (![currentTag isInline] && ![currentTag.tagName isEqualToString:@"li"])
	{
		if (nextParagraphAdditionalSpaceBefore>0)
		{
			// FIXME: add extra space properly
			// this also works, but breaks UnitTest for lists
			tagContents = [UNICODE_LINE_FEED stringByAppendingString:tagContents];
			
			// this causes problems on the paragraph after a List
			//paragraphSpacingBefore += nextParagraphAdditionalSpaceBefore;
			nextParagraphAdditionalSpaceBefore = 0;
		}
	}
#endif
	
	if (needsNewLineBefore)
	{
		if ([tagContents hasPrefix:@" "])
		{
			tagContents = [tagContents substringFromIndex:1];
		}
		
		if ([tmpString length])
		{
			if (![[tmpString string] hasSuffix:@"\n"])
			{
				[tmpString appendNakedString:@"\n"];
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
		NSAttributedString *prefixString = [currentTag prefixForListItem];
		
		if (prefixString)
		{
#if ALLOW_IPHONE_SPECIAL_CASES							
			// need to add paragraph space after previous paragraph
			if (nextParagraphAdditionalSpaceBefore>0)
			{
				NSRange effectiveRange;
				
				NSMutableDictionary *finalAttributes = [[tmpString attributesAtIndex:[tmpString length]-1 effectiveRange:&effectiveRange] mutableCopy];
				CTParagraphStyleRef style = (__bridge CTParagraphStyleRef)[finalAttributes objectForKey:(id)kCTParagraphStyleAttributeName];
				DTCoreTextParagraphStyle *paragraphStyle = [DTCoreTextParagraphStyle paragraphStyleWithCTParagraphStyle:style];
				paragraphStyle.paragraphSpacing += nextParagraphAdditionalSpaceBefore;
				
				CTParagraphStyleRef newParagraphStyle = [paragraphStyle createCTParagraphStyle];
				[finalAttributes setObject:CFBridgingRelease(newParagraphStyle) forKey:(id)kCTParagraphStyleAttributeName];
				//CFRelease(newParagraphStyle);
				
				[tmpString setAttributes:finalAttributes range:effectiveRange];
				
				nextParagraphAdditionalSpaceBefore = 0;
			}
#endif							
			[tmpString appendAttributedString:prefixString]; 
		}
		
		needsListItemStart = NO;
	}
	
	
	// we don't want whitespace before first tag to turn into paragraphs
	if (![currentTag isMeta] && !currentTag.tagContentInvisible)
	{
		currentTag.text = tagContents;
		
		[tmpString appendAttributedString:[currentTag attributedString]];
	}	
}

@end
