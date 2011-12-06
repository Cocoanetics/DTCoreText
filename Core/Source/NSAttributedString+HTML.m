//
//  NSAttributedString+HTML.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <CoreText/CoreText.h>


#import "NSAttributedString+HTML.h"
#import "NSMutableAttributedString+HTML.h"

#import "NSString+HTML.h"
#import "UIColor+HTML.h"
#import "NSScanner+HTML.h"
#import "NSCharacterSet+HTML.h"
#import "NSAttributedStringRunDelegates.h"
#import "DTTextAttachment.h"

#import "DTHTMLElement.h"
#import "DTCSSListStyle.h"
#import "DTCSSStylesheet.h"

#import "DTCoreTextFontDescriptor.h"
#import "DTCoreTextParagraphStyle.h"

#import "CGUtils.h"
#import "NSString+UTF8Cleaner.h"

// standard options
NSString *NSBaseURLDocumentOption = @"NSBaseURLDocumentOption";
NSString *NSTextEncodingNameDocumentOption = @"NSTextEncodingNameDocumentOption";
NSString *NSTextSizeMultiplierDocumentOption = @"NSTextSizeMultiplierDocumentOption";

// custom options
NSString *DTMaxImageSize = @"DTMaxImageSize";
NSString *DTDefaultFontFamily = @"DTDefaultFontFamily";
NSString *DTDefaultTextColor = @"DTDefaultTextColor";
NSString *DTDefaultLinkColor = @"DTDefaultLinkColor";
NSString *DTDefaultLinkDecoration = @"DTDefaultLinkDecoration";
NSString *DTDefaultTextAlignment = @"DTDefaultTextAlignment";
NSString *DTDefaultLineHeightMultiplier = @"DTDefaultLineHeightMultiplier";
NSString *DTDefaultFirstLineHeadIndent = @"DTDefaultFirstLineHeadIndent";
NSString *DTDefaultHeadIndent = @"DTDefaultHeadIndent";
NSString *DTDefaultListIndent = @"DTDefaultListIndent";

NSString *DTDefaultStyleSheet = @"DTDefaultStyleSheet";


@implementation NSAttributedString (HTML)

- (id)initWithHTML:(NSData *)data documentAttributes:(NSDictionary **)dict
{
	return [self initWithHTML:data options:nil documentAttributes:dict];
}

- (id)initWithHTML:(NSData *)data baseURL:(NSURL *)base documentAttributes:(NSDictionary **)dict
{
	NSDictionary *optionsDict = nil;
	
	if (base)
	{
		optionsDict = [NSDictionary dictionaryWithObject:base forKey:NSBaseURLDocumentOption];
	}
	
	return [self initWithHTML:data options:optionsDict documentAttributes:dict];
}

- (id)initWithHTML:(NSData *)data options:(NSDictionary *)options documentAttributes:(NSDictionary **)dict
{
	// only with valid data
	if (![data length])
	{
		
		return nil;
	}
	
 	// Specify the appropriate text encoding for the passed data, default is UTF8 
	NSString *textEncodingName = [options objectForKey:NSTextEncodingNameDocumentOption];
	NSStringEncoding encoding = NSUTF8StringEncoding; // default
	
	if (textEncodingName)
	{
		CFStringEncoding cfEncoding = CFStringConvertIANACharSetNameToEncoding((__bridge CFStringRef)textEncodingName);
		encoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
	}
	
	// custom option to scale text
	CGFloat textScale = [[options objectForKey:NSTextSizeMultiplierDocumentOption] floatValue];
	if (!textScale)
	{
		textScale = 1.0f;
	}
	
	// use baseURL from options if present
	NSURL *baseURL = [options objectForKey:NSBaseURLDocumentOption];
	
	
	// Make it a string
	NSString *htmlString;
	
	if (encoding == NSUTF8StringEncoding)
	{
		// this method can fix malformed UTF8
		htmlString = [[NSString alloc] initWithPotentiallyMalformedUTF8Data:data];
	}
	else
	{
		// use the specified encoding
		htmlString = [[NSString alloc] initWithData:data encoding:encoding];
	}
	
	if (!htmlString)
	{
		//NSLog(@"No valid HTML passed to to initWithHTML");
		return nil;
	}
	
	// the combined style sheet for entire document
	DTCSSStylesheet *styleSheet = [[DTCSSStylesheet alloc] init]; 
	// default list styles
	[styleSheet parseStyleBlock:@"ul {list-style:disc;} ol {list-style:decimal;}"];
	[styleSheet parseStyleBlock:@"code {font-family: Courier;} pre {font-family: Courier;}"];

	// do we have a default style sheet passed as option?
	DTCSSStylesheet *defaultStylesheet = [options objectForKey:DTDefaultStyleSheet];
	if (defaultStylesheet) {
		// merge the default styles to the combined style sheet
		[styleSheet mergeStylesheet:defaultStylesheet];
	}
	

	// for performance we will return this mutable string
	NSMutableAttributedString *tmpString = [[NSMutableAttributedString alloc] init];
	
#if ALLOW_IPHONE_SPECIAL_CASES
	CGFloat nextParagraphAdditionalSpaceBefore = 0.0;
#endif
	BOOL needsListItemStart = NO;
	BOOL needsNewLineBefore = NO;
	
	// we cannot skip any characters, NLs turn into spaces and multi-spaces get compressed to singles
	NSScanner *scanner = [NSScanner scannerWithString:htmlString];
	scanner.charactersToBeSkipped = nil;
	
	// base tag with font defaults
	DTCoreTextFontDescriptor *defaultFontDescriptor = [[DTCoreTextFontDescriptor alloc] initWithFontAttributes:nil];
	defaultFontDescriptor.pointSize = 12.0f * textScale;
	
	NSString *defaultFontFamily = [options objectForKey:DTDefaultFontFamily];
	if (defaultFontFamily)
	{
		defaultFontDescriptor.fontFamily = defaultFontFamily;
	}
	else
	{
		defaultFontDescriptor.fontFamily = @"Times New Roman";
	}
	
	id defaultLinkColor = [options objectForKey:DTDefaultLinkColor];
	
	if (defaultLinkColor)
	{
		if ([defaultLinkColor isKindOfClass:[NSString class]])
		{
			// convert from string to color
			defaultLinkColor = [UIColor colorWithHTMLName:defaultLinkColor];
		}
	}
	else
	{
		defaultLinkColor = [UIColor colorWithHTMLName:@"#0000EE"];
	}
	
	// default is to have A underlined
	BOOL defaultLinkDecoration = YES;
	
	NSNumber *linkDecorationDefault = [options objectForKey:DTDefaultLinkDecoration];
	
	if (linkDecorationDefault)
	{
		defaultLinkDecoration = [linkDecorationDefault boolValue];
	}
	
	// default paragraph style
	DTCoreTextParagraphStyle *defaultParagraphStyle = [DTCoreTextParagraphStyle defaultParagraphStyle];
	
	NSNumber *defaultLineHeightMultiplierNum = [options objectForKey:DTDefaultLineHeightMultiplier];
	
	if (defaultLineHeightMultiplierNum)
	{
		CGFloat defaultLineHeightMultiplier = [defaultLineHeightMultiplierNum floatValue];
		defaultParagraphStyle.lineHeightMultiple = defaultLineHeightMultiplier;
	}
	
	NSNumber *defaultTextAlignmentNum = [options objectForKey:DTDefaultTextAlignment];
	
	if (defaultTextAlignmentNum)
	{
		defaultParagraphStyle.textAlignment = (CTTextAlignment)[defaultTextAlignmentNum integerValue];
	}
	
	NSNumber *defaultFirstLineHeadIndent = [options objectForKey:DTDefaultFirstLineHeadIndent];
	if (defaultFirstLineHeadIndent)
	{
		defaultParagraphStyle.firstLineIndent = [defaultFirstLineHeadIndent integerValue];
	}
	
	NSNumber *defaultHeadIndent = [options objectForKey:DTDefaultHeadIndent];
	if (defaultHeadIndent)
	{
		defaultParagraphStyle.headIndent = [defaultHeadIndent integerValue];
	}
	
	NSNumber *defaultListIndent = [options objectForKey:DTDefaultListIndent];
	if (defaultListIndent)
	{
		defaultParagraphStyle.listIndent = [defaultListIndent integerValue];
	}
	
	DTHTMLElement *defaultTag = [[DTHTMLElement alloc] init];
	defaultTag.fontDescriptor = defaultFontDescriptor;
	defaultTag.paragraphStyle = defaultParagraphStyle;
	defaultTag.textScale = textScale;
	
	id defaultColor = [options objectForKey:DTDefaultTextColor];
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
	
	
	DTHTMLElement *currentTag = defaultTag; // our defaults are the root
	
	// skip initial whitespace
	[scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
 	
	// skip doctype tag
	[scanner scanDOCTYPE:NULL];
	
	// skip initial whitespace
	[scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
	
	while (![scanner isAtEnd]) 
	{
		NSString *tagName = nil;
		NSDictionary *tagAttributesDict = nil;
		BOOL tagOpen = YES;
		BOOL immediatelyClosed = NO;
		
		if ([scanner scanHTMLTag:&tagName attributes:&tagAttributesDict isOpen:&tagOpen isClosed:&immediatelyClosed] && tagName)
		{
			if ([tagName isEqualToString:@"style"] && tagOpen)
			{
				// get contents, there cannot be anything contained in this block
				NSString *tagContents = nil;
				if ([scanner scanUpToString:@"<" intoString:&tagContents])
				{
					[styleSheet parseStyleBlock:tagContents];
				}
				
				continue;
			}
			
			if (tagOpen)
			{
				// make new tag as copy of previous tag
				DTHTMLElement *parent = currentTag;
				currentTag = [currentTag copy];
				currentTag.tagName = tagName;
				currentTag.textScale = textScale;
				currentTag.attributes = tagAttributesDict;
				[parent addChild:currentTag];
				
				// apply style from merged style sheet
				NSDictionary *mergedStyles = [styleSheet mergedStyleDictionaryForElement:currentTag];
				if (mergedStyles)
				{
					[currentTag applyStyleDictionary:mergedStyles];
				}

				if ([tagName isMetaTag])
				{
					// we don't care about the other stuff in META tags, but styles are inherited
					continue;
				}
				else if (![currentTag isInline] && !tagOpen)
				{
					// next text needs a NL
					needsNewLineBefore = YES;
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
			}
			
			// ---------- Processing
			
			if ([tagName isEqualToString:@"#COMMENT#"])
			{
				continue;
			}
			else if ([tagName isEqualToString:@"img"] && tagOpen)
			{
				immediatelyClosed = YES;
				
				if (![currentTag.parent.tagName isEqualToString:@"p"])
				{
					needsNewLineBefore = YES;
				}
				
				// hide contents of recognized tag
				currentTag.tagContentInvisible = YES;
				
				// make appropriate attachment
				DTTextAttachment *attachment = [DTTextAttachment textAttachmentWithElement:currentTag options:options];
				
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
			else if ([tagName isEqualToString:@"blockquote"] && tagOpen)
			{
				currentTag.paragraphStyle.headIndent += 25.0 * textScale;
				currentTag.paragraphStyle.firstLineIndent = currentTag.paragraphStyle.headIndent;
				currentTag.paragraphStyle.paragraphSpacing = defaultFontDescriptor.pointSize;
			}
			else if (([tagName isEqualToString:@"iframe"] || [tagName isEqualToString:@"video"] || [tagName isEqualToString:@"object"]) && tagOpen)
			{
				// hide contents of recognized tag
				currentTag.tagContentInvisible = YES;
				
				// make appropriate attachment
				DTTextAttachment *attachment = [DTTextAttachment textAttachmentWithElement:currentTag options:options];
				
				// add it to tag
				currentTag.textAttachment = attachment;
				
				// to avoid much too much space before the image
				currentTag.paragraphStyle.lineHeightMultiple = 1;
				
				// add it to output
				[tmpString appendAttributedString:[currentTag attributedString]];
			}
			else if ([tagName isEqualToString:@"a"])
			{
				if (tagOpen)
				{
					if (defaultLinkDecoration)
					{
						currentTag.underlineStyle = kCTUnderlineStyleSingle;
					}
					
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
			}
			else if ([tagName isEqualToString:@"b"] || [tagName isEqualToString:@"strong"])
			{
				currentTag.fontDescriptor.boldTrait = YES;
			}
			else if ([tagName isEqualToString:@"i"] || [tagName isEqualToString:@"em"])
			{
				currentTag.fontDescriptor.italicTrait = YES;
			}
			else if ([tagName isEqualToString:@"li"]) 
			{
				if (tagOpen)
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
				else 
				{
					needsListItemStart = NO;
				}
				
			}
			else if ([tagName isEqualToString:@"left"])
			{
				if (tagOpen)
				{
					currentTag.paragraphStyle.textAlignment = kCTLeftTextAlignment;
				}
			}
			else if ([tagName isEqualToString:@"center"] && tagOpen)
			{
				currentTag.paragraphStyle.textAlignment = kCTCenterTextAlignment;
			}
			else if ([tagName isEqualToString:@"right"] && tagOpen)
			{
				currentTag.paragraphStyle.textAlignment = kCTRightTextAlignment;
			}
			else if ([tagName isEqualToString:@"del"] || [tagName isEqualToString:@"strike"] ) 
			{
				if (tagOpen)
				{
					currentTag.strikeOut = YES;
				}
			}
			else if ([tagName isEqualToString:@"ol"]) 
			{
				if (tagOpen)
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
				else 
				{
#if ALLOW_IPHONE_SPECIAL_CASES
					if (currentTag.listDepth < 1)
						nextParagraphAdditionalSpaceBefore = defaultFontDescriptor.pointSize;
#endif
				}
			}
			else if ([tagName isEqualToString:@"ul"]) 
			{
				if (tagOpen)
				{
					needsNewLineBefore = YES;
					
					currentTag.listCounter = 0;
				}
				else 
				{
#if ALLOW_IPHONE_SPECIAL_CASES
					if (currentTag.listDepth < 1)
						nextParagraphAdditionalSpaceBefore = defaultFontDescriptor.pointSize;
#endif
				}
			}
			
			else if ([tagName isEqualToString:@"u"])
			{
				if (tagOpen)
				{
					currentTag.underlineStyle = kCTUnderlineStyleSingle;
				}
			}
			else if ([tagName isEqualToString:@"sup"])
			{
				if (tagOpen)
				{
					currentTag.superscriptStyle = 1;
					currentTag.fontDescriptor.pointSize *= 0.83;
				}
			}
			else if ([tagName isEqualToString:@"pre"])
			{
				if (tagOpen)
				{
					currentTag.preserveNewlines = YES;
					currentTag.paragraphStyle.textAlignment = kCTNaturalTextAlignment;
				}
			}
            else if ([tagName isEqualToString:@"code"]) 
            {
                if (tagOpen) 
                {
                }
            }
			else if ([tagName isEqualToString:@"sub"])
			{
				if (tagOpen)
				{
					currentTag.superscriptStyle = -1;
					currentTag.fontDescriptor.pointSize *= 0.83;
				}
			}
			else if ([tagName isEqualToString:@"hr"])
			{
				if (tagOpen)
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
			}
			else if ([tagName hasPrefix:@"h"])
			{
				if (tagOpen)
				{
					NSString *levelString = [tagName substringFromIndex:1];
					
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
			}
			else if ([tagName isEqualToString:@"big"])
			{
				if (tagOpen)
				{
					currentTag.fontDescriptor.pointSize *= 1.2;
				}
			}
			else if ([tagName isEqualToString:@"small"])
			{
				if (tagOpen)
				{
					currentTag.fontDescriptor.pointSize /= 1.2;
				}
			}
			else if ([tagName isEqualToString:@"font"])
			{
				if (tagOpen)
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
			}
			else if ([tagName isEqualToString:@"p"])
			{
				if (tagOpen)
				{
					currentTag.paragraphStyle.paragraphSpacing = defaultFontDescriptor.pointSize;
					currentTag.paragraphStyle.firstLineIndent = currentTag.paragraphStyle.headIndent + defaultParagraphStyle.firstLineIndent;
				}
			}
			else if ([tagName isEqualToString:@"br"])
			{
				immediatelyClosed = YES; 
				
				currentTag.text = UNICODE_LINE_FEED;
				[tmpString appendAttributedString:[currentTag attributedString]];
			}
			
			// --------------------- push tag on stack if it's opening
			if (tagOpen&&immediatelyClosed)
			{
				DTHTMLElement *popChild = currentTag;
				currentTag = currentTag.parent;
				[currentTag removeChild:popChild];
			}
			else if (!tagOpen)
			{
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
				if ([tagName isEqualToString:currentTag.tagName])
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
			else if (immediatelyClosed)
			{
				// If it's immediately closed it's not relevant for following body
				//	currentTag = [tagStack lastObject];
			}
		}
		else 
		{
			//----------------------------------------- TAG CONTENTS -----------------------------------------
			NSString *tagContents = nil;
			
			// if we find a < at this stage then we can assume it was a malformed tag, need to skip it to prevent endless loop
			
			BOOL skippedAngleBracket = NO;
			if ([scanner scanString:@"<" intoString:NULL])
			{
				skippedAngleBracket = YES;
			}
			
			if ((skippedAngleBracket||[scanner scanUpToString:@"<" intoString:&tagContents]) && !currentTag.tagContentInvisible)
			{
				if (skippedAngleBracket)
				{
					if (tagContents)
					{
						tagContents = [@"<" stringByAppendingString:tagContents];
					}
					else
					{
						tagContents = @"<";
					}
				}
				
				if ([[tagContents stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] length])
				{
					if (currentTag.preserveNewlines)
					{
						tagContents = [tagContents stringByReplacingOccurrencesOfString:@"\n" withString:UNICODE_LINE_FEED];
					}
					else
					{
						tagContents = [tagContents stringByNormalizingWhitespace];
					}
					tagContents = [tagContents stringByReplacingHTMLEntities];
					
					tagName = currentTag.tagName;
					
#if ALLOW_IPHONE_SPECIAL_CASES				
					if (tagOpen && ![currentTag isInline] && ![tagName isEqualToString:@"li"])
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
					if (![currentTag isMeta])
					{
						currentTag.text = tagContents;
						
						[tmpString appendAttributedString:[currentTag attributedString]];
					}
				}
			}
		}
	}
	
	// returning the temporary mutable string is faster
	//return [self initWithAttributedString:tmpString];
	
	return tmpString;
}

#pragma mark Convenience Methods

+ (NSAttributedString *)attributedStringWithHTML:(NSData *)data options:(NSDictionary *)options
{
	NSAttributedString *attrString = [[NSAttributedString alloc] initWithHTML:data options:options documentAttributes:NULL];
	
	return attrString;
}

#pragma mark Utlities

+ (NSAttributedString *)synthesizedSmallCapsAttributedStringWithText:(NSString *)text attributes:(NSDictionary *)attributes
{
	CTFontRef normalFont = (__bridge CTFontRef)[attributes objectForKey:(id)kCTFontAttributeName];
	
	DTCoreTextFontDescriptor *smallerFontDesc = [DTCoreTextFontDescriptor fontDescriptorForCTFont:normalFont];
	smallerFontDesc.pointSize *= 0.7;
	CTFontRef smallerFont = [smallerFontDesc newMatchingFont];
	
	NSMutableDictionary *smallAttributes = [attributes mutableCopy];
	[smallAttributes setObject:CFBridgingRelease(smallerFont) forKey:(id)kCTFontAttributeName];
	//CFRelease(smallerFont);
	
	NSMutableAttributedString *tmpString = [[NSMutableAttributedString alloc] init];
	NSScanner *scanner = [NSScanner scannerWithString:text];
	[scanner setCharactersToBeSkipped:nil];
	
	NSCharacterSet *lowerCaseChars = [NSCharacterSet lowercaseLetterCharacterSet];
	
	while (![scanner isAtEnd])
	{
		NSString *part;
		
		if ([scanner scanCharactersFromSet:lowerCaseChars intoString:&part])
		{
			part = [part uppercaseString];
			NSAttributedString *partString = [[NSAttributedString alloc] initWithString:part attributes:smallAttributes];
			[tmpString appendAttributedString:partString];
		}
		
		if ([scanner scanUpToCharactersFromSet:lowerCaseChars intoString:&part])
		{
			NSAttributedString *partString = [[NSAttributedString alloc] initWithString:part attributes:attributes];
			[tmpString appendAttributedString:partString];
		}
	}
	
	
	return 	tmpString;
}

- (NSArray *)textAttachmentsWithPredicate:(NSPredicate *)predicate
{
	NSMutableArray *tmpArray = [NSMutableArray array];
	
	NSUInteger index = 0;
	
	while (index<[self length]) 
	{
		NSRange range;
		NSDictionary *attributes = [self attributesAtIndex:index effectiveRange:&range];
		
		DTTextAttachment *attachment = [attributes objectForKey:@"DTTextAttachment"];
		
		if (attachment)
		{
			if ([predicate evaluateWithObject:attachment])
			{
				[tmpArray addObject:attachment];
			}
		}
		
		index += range.length;
	}
	
	if ([tmpArray count])
	{
		return tmpArray;
	}
	
	return nil;
}

#pragma mark HTML Encoding

// TO DO: aggregate common styles (like font) into one span
// TO DO: correctly encode LI/OL/UL
// TO DO: correctly encode shadows

- (NSString *)htmlString
{
	NSString *plainString = [self string];
	
	// divide the string into it's blocks, we assume that these are the P
	NSArray *paragraphs = [plainString componentsSeparatedByString:@"\n"];
	
	NSMutableString *retString = [NSMutableString string];
	
	NSInteger location = 0;
	
	for (NSString *oneParagraph in paragraphs)
	{
		NSRange paragraphRange = NSMakeRange(location, [oneParagraph length]);
		
		// skip empty paragraph at end
		if (oneParagraph == [paragraphs lastObject] && !paragraphRange.length)
		{
			break;
		}
		
		BOOL fontIsBlockLevel = NO;
		
		// check if font is same in all paragraph
		NSRange fontEffectiveRange;
		CTFontRef paragraphFont = (__bridge CTFontRef)[self attribute:(id)kCTFontAttributeName atIndex:paragraphRange.location longestEffectiveRange:&fontEffectiveRange inRange:paragraphRange];
		
		if (NSEqualRanges(paragraphRange, fontEffectiveRange))
		{
			fontIsBlockLevel = YES;
		}
		
		// next paragraph start
		location = location + paragraphRange.length + 1;
		
		NSDictionary *paraAttributes = [self attributesAtIndex:paragraphRange.location effectiveRange:NULL];
		
		CTParagraphStyleRef paraStyle = (__bridge CTParagraphStyleRef)[paraAttributes objectForKey:(id)kCTParagraphStyleAttributeName];
		NSString *paraStyleString = nil;
		
		if (paraStyle)
		{
			DTCoreTextParagraphStyle *para = [DTCoreTextParagraphStyle paragraphStyleWithCTParagraphStyle:paraStyle];
			
			paraStyleString = [para cssStyleRepresentation];
		}
		
		if (!paraStyleString)
		{
			paraStyleString = @"";
		}
		
		if (fontIsBlockLevel)
		{
			if (paragraphFont)
			{
				DTCoreTextFontDescriptor *desc = [DTCoreTextFontDescriptor fontDescriptorForCTFont:paragraphFont];
				NSString *paraFontStyle = [desc cssStyleRepresentation];
				
				if (paraFontStyle)
				{
					paraStyleString = [paraStyleString stringByAppendingString:paraFontStyle];
				}
			}
		}
		
		NSString *blockElement;
		
		NSNumber *headerLevel = [paraAttributes objectForKey:@"DTHeaderLevel"];
		
		if (headerLevel)
		{
			blockElement = [NSString stringWithFormat:@"h%d", [headerLevel integerValue]];
		}
		else
		{
			blockElement = @"p";
			
			if ([paragraphs lastObject] == oneParagraph)
			{
				// last paragraph in string
				
				if (![plainString hasSuffix:@"\n"])
				{
					// not a whole paragraph, so we don't put it in P
					blockElement = @"span";
				}
			}
		}
		
		if ([paraStyleString length])
		{
			[retString appendFormat:@"<%@ style=\"%@\">", blockElement, paraStyleString];
		}
		else
		{
			[retString appendFormat:@"<%@>", blockElement];
		}
		
		// add the attributed string ranges in this paragraph to the paragraph container
		NSRange effectiveRange;
		NSUInteger index = paragraphRange.location;
		
		while (index < NSMaxRange(paragraphRange))
		{
			NSDictionary *attributes = [self attributesAtIndex:index longestEffectiveRange:&effectiveRange inRange:paragraphRange];
			
			index += effectiveRange.length;
			
			
			NSString *subString = [[plainString substringWithRange:effectiveRange] stringByAddingHTMLEntities];
			
			if (!subString)
			{
				continue;
			}
			
			DTTextAttachment *attachment = [attributes objectForKey:@"DTTextAttachment"];
			
			
			if (attachment)
			{
				NSString *urlString;
				
				if (attachment.contentURL)
				{
					
					if ([attachment.contentURL isFileURL])
					{
						NSString *path = [attachment.contentURL path];
						
						NSRange range = [path rangeOfString:@".app/"];
						
						if (range.length)
						{
							urlString = [path substringFromIndex:NSMaxRange(range)];
						}
						else
						{
							urlString = [attachment.contentURL absoluteString];
						}
					}
					else
					{
						urlString = [attachment.contentURL relativeString];
					}
				}
				else
				{
					if (attachment.contentType == DTTextAttachmentTypeImage && attachment.contents)
					{
						urlString = [attachment dataURLRepresentation];
					}
					else
					{
						// no valid image remote or local
						continue;
					}
				}
				
				// write appropriate tag
				if (attachment.contentType == DTTextAttachmentTypeVideoURL)
				{
					[retString appendFormat:@"<video src=\"%@\"", urlString];
				}
				else if (attachment.contentType == DTTextAttachmentTypeImage)
				{
					[retString appendFormat:@"<img src=\"%@\"", urlString];
				}
				
				
				// build a HTML 5 conformant size style if set
				NSMutableString *styleString = [NSMutableString string];
				
				if (attachment.originalSize.width>0)
				{
					[styleString appendFormat:@"width:%.0fpx;", attachment.originalSize.width];
				}
				
				if (attachment.originalSize.height>0)
				{
					[styleString appendFormat:@"height:%.0fpx;", attachment.originalSize.height];
				}
				
				if ([styleString length])
				{
					[retString appendFormat:@" style=\"%@\"", styleString];
				}
				
				// attach the attributes dictionary
				NSMutableDictionary *tmpAttributes = [attachment.attributes mutableCopy];
				
				// remove src and style, we already have that
				[tmpAttributes removeObjectForKey:@"src"];
				[tmpAttributes removeObjectForKey:@"style"];
				
				for (__strong NSString *oneKey in [tmpAttributes allKeys])
				{
					oneKey = [oneKey stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
					NSString *value = [[tmpAttributes objectForKey:oneKey] stringByAddingHTMLEntities];
					[retString appendFormat:@" %@=\"%@\"", oneKey, value];
				}
				
				// end
				[retString appendString:@" />"];
				
				
				continue;
			}
			
			NSString *fontStyle = nil;
			if (!fontIsBlockLevel)
			{
				CTFontRef font = (__bridge CTFontRef)[attributes objectForKey:(id)kCTFontAttributeName];
				if (font)
				{
					DTCoreTextFontDescriptor *desc = [DTCoreTextFontDescriptor fontDescriptorForCTFont:font];
					fontStyle = [desc cssStyleRepresentation];
				}
			}
			
			if (!fontStyle)
			{
				fontStyle = @"";
			}
			
			CGColorRef textColor = (__bridge CGColorRef)[attributes objectForKey:(id)kCTForegroundColorAttributeName];
			if (textColor)
			{
				UIColor *color = [UIColor colorWithCGColor:textColor];
				
				fontStyle = [fontStyle stringByAppendingFormat:@"color:#%@;", [color htmlHexString]];
			}
			
			CGColorRef backgroundColor = (__bridge CGColorRef)[attributes objectForKey:@"DTBackgroundColor"];
			if (backgroundColor)
			{
				UIColor *color = [UIColor colorWithCGColor:backgroundColor];
				
				fontStyle = [fontStyle stringByAppendingFormat:@"background-color:#%@;", [color htmlHexString]];
			}
			
			NSNumber *underline = [attributes objectForKey:(id)kCTUnderlineStyleAttributeName];
			if (underline)
			{
				fontStyle = [fontStyle stringByAppendingString:@"text-decoration:underline;"];
			}
			else
			{
				// there can be no underline and strike-through at the same time
				NSNumber *strikout = [attributes objectForKey:@"DTStrikeOut"];
				if ([strikout boolValue])
				{
					fontStyle = [fontStyle stringByAppendingString:@"text-decoration:line-through;"];
				}
			}
			
			
			NSURL *url = [attributes objectForKey:@"DTLink"];
			
			if (url)
			{
				if ([fontStyle length])
				{
					[retString appendFormat:@"<a href=\"%@\" style=\"%@\">%@</a>", [url relativeString], fontStyle, subString];
				}
				else
				{
					[retString appendFormat:@"<a href=\"%@\">%@</a>", [url relativeString], subString];
				}			
			}
			else
			{
				if ([fontStyle length])
				{
					[retString appendFormat:@"<span style=\"%@\">%@</span>\n", fontStyle, subString];
				}
				else
				{
					[retString appendString:subString];
				}
			}
		}
		
		[retString appendFormat:@"</%@>\n", blockElement];
	}
	
	//NSLog(@"%@", retString);
	
	return retString;
}

- (NSString *)plainTextString
{
	NSString *tmpString = [self string];
	
	return [tmpString stringByReplacingOccurrencesOfString:UNICODE_OBJECT_PLACEHOLDER withString:@""];
}

@end
