//
//  NSAttributedString+HTML.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <CoreText/CoreText.h>
#import <UIKit/UIKit.h>

#import "NSAttributedString+HTML.h"
#import "NSMutableAttributedString+HTML.h"

#import "NSString+HTML.h"
#import "UIColor+HTML.h"
#import "NSScanner+HTML.h"
#import "NSCharacterSet+HTML.h"
#import "NSAttributedStringRunDelegates.h"
#import "DTTextAttachment.h"

#import "DTHTMLElement.h"
#import "DTCoreTextFontDescriptor.h"
#import "DTCoreTextParagraphStyle.h"

#import "CGUtils.h"
#import "NSData+Base64.h"
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
 	// Specify the appropriate text encoding for the passed data, default is UTF8 
	NSString *textEncodingName = [options objectForKey:NSTextEncodingNameDocumentOption];
	NSStringEncoding encoding = NSUTF8StringEncoding; // default
	
	if (textEncodingName)
	{
		CFStringEncoding cfEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)textEncodingName);
		encoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
	}
	
	// custom option to limit image size
	NSValue *maxImageSizeValue = [options objectForKey:DTMaxImageSize];
	
	// custom option to scale text
	CGFloat textScale = [[options objectForKey:NSTextSizeMultiplierDocumentOption] floatValue];
	if (!textScale)
	{
		textScale = 1.0f;
	}
	
	// use baseURL from options if present
	NSURL *baseURL = [options objectForKey:NSBaseURLDocumentOption];
	
	
	// Make it a string
	NSString *htmlString = [[NSString alloc] initWithPotentiallyMalformedUTF8Data:data];
	
	if (!htmlString)
	{
		NSLog(@"No valid HTML passed to to initWithHTML");
		
		[self release];
		return nil;
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
	[htmlString release];
	
	// base tag with font defaults
	DTCoreTextFontDescriptor *defaultFontDescriptor = [[[DTCoreTextFontDescriptor alloc] initWithFontAttributes:nil] autorelease];
	defaultFontDescriptor.pointSize = 12.0 * textScale;
	
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
		defaultParagraphStyle.textAlignment = [defaultTextAlignmentNum integerValue];
	}
	
	DTHTMLElement *defaultTag = [[[DTHTMLElement alloc] init] autorelease];
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
			
			if ([tagName isMetaTag])
			{
				continue;
			}
			
			if (tagOpen)
			{
				// make new tag as copy of previous tag
				DTHTMLElement *parent = currentTag;
				currentTag = [[currentTag copy] autorelease];
				currentTag.tagName = tagName;
				currentTag.textScale = textScale;
				[parent addChild:currentTag];
				
				// convert CSS Styles into our own style
				NSString *styleString = [tagAttributesDict objectForKey:@"style"];
				
				if (styleString)
				{
					[currentTag parseStyleString:styleString];
				}
				
				if (![currentTag isInline] && !tagOpen && ![currentTag isMeta])
				{
					// next text needs a NL
					needsNewLineBefore = YES;
				}
				
				
				// direction
				NSString *direction = [tagAttributesDict objectForKey:@"dir"];
				
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
				
				NSString *src = [tagAttributesDict objectForKey:@"src"];
				
				NSURL *imageURL = nil;
				UIImage *decodedImage = nil;
				
				// get size of width/height if it's not in style
				CGSize imageSize = currentTag.size;
				
				if (!imageSize.width)
				{
					imageSize.width = [[tagAttributesDict objectForKey:@"width"] floatValue];
				}
				
				if (!imageSize.height)
				{
					imageSize.height = [[tagAttributesDict objectForKey:@"height"] floatValue];
				}
				
				// decode data URL
				if ([src hasPrefix:@"data:"])
				{
					NSRange range = [src rangeOfString:@"base64,"];
					
					if (range.length)
					{
						NSString *encodedData = [src substringFromIndex:range.location + range.length];
						NSData *decodedData = [NSData dataFromBase64String:encodedData];
						
						decodedImage = [UIImage imageWithData:decodedData];
						
						if (!imageSize.width)
						{
							imageSize.width = decodedImage.size.width;
						}
						
						if (!imageSize.height)
						{
							imageSize.height = decodedImage.size.height;
						}
					}
				}
				else // normal URL
				{
					imageURL = [NSURL URLWithString:src];
					
					if (![imageURL scheme])
					{
						// possibly a relative url
						if (baseURL)
						{
							imageURL = [NSURL URLWithString:src relativeToURL:baseURL];
						}
						else
						{
							// file in app bundle
							NSString *path = [[NSBundle mainBundle] pathForResource:src ofType:nil];
							imageURL = [NSURL fileURLWithPath:path];
						}
					}
					
					if (!imageSize.width || !imageSize.height)
					{
						// inspect local file
						if ([imageURL isFileURL])
						{
							UIImage *image = [UIImage imageWithContentsOfFile:[imageURL path]];
							
							if (!imageSize.width)
							{
								imageSize.width = image.size.width;
							}
							
							if (!imageSize.height)
							{
								imageSize.height = image.size.height;
							}
						}
						else
						{
							// remote image, we have to relayout once this size is known
							imageSize = CGSizeMake(1, 1); // one pixel so that loading is triggered
						}
					}
				}
				
				CGSize adjustedSize = imageSize;
				
				// option DTMaxImageSize
				if (maxImageSizeValue)
				{
					CGSize maxImageSize = [maxImageSizeValue CGSizeValue];
					
					if (maxImageSize.width < imageSize.width || maxImageSize.height < imageSize.height)
					{
						adjustedSize = sizeThatFitsKeepingAspectRatio(imageSize,maxImageSize);
					}
				}
				
				DTTextAttachment *attachment = [[DTTextAttachment alloc] init];
				attachment.contentURL = imageURL;
				attachment.originalSize = imageSize;
				attachment.displaySize = adjustedSize;
				attachment.attributes = tagAttributesDict;
				attachment.contents = decodedImage;
				
				// to avoid much too much space before the image
				currentTag.paragraphStyle.lineHeightMultiple = 1;
				
				// we copy the link because we might need for it making the custom view
				if (currentTag.link)
				{
					attachment.hyperLinkURL = currentTag.link;
				}
				
				currentTag.textAttachment = attachment;
				
				if (needsNewLineBefore)
				{
					if ([tmpString length] && ![[tmpString string] hasSuffix:@"\n"])
					{
						[tmpString appendNakedString:@"\n"];
					}
					
					needsNewLineBefore = NO;
				}
				
				[tmpString appendAttributedString:[currentTag attributedString]];
				[attachment release];
				
#if ALLOW_IPHONE_SPECIAL_CASES
				// workaround, make float images blocks because we have no float
				if (currentTag.floatStyle || attachment.displaySize.height > 2.0 * currentTag.fontDescriptor.pointSize || ![currentTag isContainedInBlockElement])
				{
					[tmpString appendString:@"\n" withParagraphStyle:currentTag.paragraphStyle];
				}
#endif
			}
			else if ([tagName isEqualToString:@"blockquote"] && tagOpen)
			{
				currentTag.paragraphStyle.headIndent += 25.0 * textScale;
				currentTag.paragraphStyle.firstLineIndent = currentTag.paragraphStyle.headIndent;
				currentTag.paragraphStyle.paragraphSpacing = defaultFontDescriptor.pointSize;
			}
			else if ([tagName isEqualToString:@"video"] && tagOpen)
			{
				// hide contents of recognized tag
				currentTag.tagContentInvisible = YES;
				
				// get size of width/height if it's not in style
				CGSize imageSize = currentTag.size;
				
				if (!imageSize.width)
				{
					imageSize.width = [[tagAttributesDict objectForKey:@"width"] floatValue];
				}
				
				if (!imageSize.height)
				{
					imageSize.height = [[tagAttributesDict objectForKey:@"height"] floatValue];
				}
				
				// if we still have no size then we use standard size
				if (!imageSize.width || !imageSize.height)
				{
					imageSize = CGSizeMake(300, 225);
				}
				
				// option DTMaxImageSize
				if (maxImageSizeValue)
				{
					CGSize maxImageSize = [maxImageSizeValue CGSizeValue];
					
					if (maxImageSize.width < imageSize.width || maxImageSize.height < imageSize.height)
					{
						imageSize = sizeThatFitsKeepingAspectRatio(imageSize,maxImageSize);
					}
				}
				
				DTTextAttachment *attachment = [[[DTTextAttachment alloc] init] autorelease];
				attachment.contentURL = [NSURL URLWithString:[tagAttributesDict objectForKey:@"src"]];
				attachment.contentType = DTTextAttachmentTypeVideoURL;
				attachment.originalSize = imageSize;
				attachment.attributes = tagAttributesDict;
				
				currentTag.textAttachment = attachment;
				
				// to avoid much too much space before the image
				currentTag.paragraphStyle.lineHeightMultiple = 1;
				
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
					NSString *cleanString = [[tagAttributesDict objectForKey:@"href"] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
					cleanString = [cleanString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
					
					NSURL *link = [NSURL URLWithString:cleanString];
					
					// deal with relative URL
					if (![link scheme])
					{
						if ([cleanString length])
						{
							link = [NSURL URLWithString:cleanString relativeToURL:baseURL];
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
					// have inherit the correct list counter from parent
					
					DTHTMLElement *counterElement = currentTag.parent;
					
					NSNumber *valueNum = [tagAttributesDict objectForKey:@"value"];
					if (valueNum)
					{
						NSInteger value = [valueNum integerValue];
						counterElement.listCounter = value;
						currentTag.listCounter = value;
					}
					
					counterElement.listCounter++;
					
					needsListItemStart = YES;
					currentTag.paragraphStyle.paragraphSpacing = 0;
					
#if ALLOW_IPHONE_SPECIAL_CASES                    
					CGFloat indentSize = 27.0 * textScale;
#else
					CGFloat indentSize = 36.0 * textScale;
#endif
					
					CGFloat indentHang = indentSize;
					
					currentTag.paragraphStyle.headIndent += indentSize;
					currentTag.paragraphStyle.firstLineIndent = currentTag.paragraphStyle.headIndent - indentHang;
					
					[currentTag.paragraphStyle addTabStopAtPosition:currentTag.paragraphStyle.headIndent - 5.0*textScale alignment:kCTRightTextAlignment];
					
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
#if ALLOW_IPHONE_SPECIAL_CASES
				else 
				{
					nextParagraphAdditionalSpaceBefore = defaultFontDescriptor.pointSize;
				}
#endif
			}
			else if ([tagName isEqualToString:@"center"] && tagOpen)
			{
				currentTag.paragraphStyle.textAlignment = kCTCenterTextAlignment;
#if ALLOW_IPHONE_SPECIAL_CASES						
				nextParagraphAdditionalSpaceBefore = defaultFontDescriptor.pointSize;
#endif
			}
			else if ([tagName isEqualToString:@"right"] && tagOpen)
			{
				currentTag.paragraphStyle.textAlignment = kCTRightTextAlignment;
#if ALLOW_IPHONE_SPECIAL_CASES						
				nextParagraphAdditionalSpaceBefore = defaultFontDescriptor.pointSize;
#endif
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
					NSNumber *valueNum = [tagAttributesDict objectForKey:@"start"];
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
					currentTag.fontDescriptor.fontFamily = @"Courier";
					currentTag.preserveNewlines = YES;
					currentTag.paragraphStyle.textAlignment = kCTNaturalTextAlignment;
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
			else if ([tagName isEqualToString:@"style"])
			{
				if (tagOpen)
				{
					// TODO: store style info in a dictionary and apply it to tags
					currentTag.tagContentInvisible = YES;
					needsNewLineBefore = NO;
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
								currentTag.paragraphStyle.paragraphSpacing = 0.67 * currentTag.fontDescriptor.pointSize;
								break;
							}
							case 2:
							{
								// H2: 1.5 em, spacing before 0.83 em, after 0.83 em
								currentTag.fontDescriptor.pointSize *= 1.5;
								currentTag.paragraphStyle.paragraphSpacing = 0.83 * currentTag.fontDescriptor.pointSize;
								break;
							}
							case 3:
							{
								// H3: 1.17 em, spacing before 1 em, after 1 em
								currentTag.fontDescriptor.pointSize *= 1.17;
								currentTag.paragraphStyle.paragraphSpacing = 1.0 * currentTag.fontDescriptor.pointSize;
								break;
							}
							case 4:
							{
								// H4: 1 em, spacing before 1.33 em, after 1.33 em
								currentTag.paragraphStyle.paragraphSpacing = 1.33 * currentTag.fontDescriptor.pointSize;
								break;
							}
							case 5:
							{
								// H5: 0.83 em, spacing before 1.67 em, after 1.167 em
								currentTag.fontDescriptor.pointSize *= 0.83;
								currentTag.paragraphStyle.paragraphSpacing = 1.67 * currentTag.fontDescriptor.pointSize;
								break;
							}
							case 6:
							{
								// H6: 0.67 em, spacing before 2.33 em, after 2.33 em
								currentTag.fontDescriptor.pointSize *= 0.67;
								currentTag.paragraphStyle.paragraphSpacing = 2.33 * currentTag.fontDescriptor.pointSize;
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
					NSInteger size = [[tagAttributesDict objectForKey:@"size"] intValue];
					
					switch (size) 
					{
						case 1:
							currentTag.fontDescriptor.pointSize = textScale * 9.0;
							break;
						case 2:
							currentTag.fontDescriptor.pointSize = textScale * 10.0;
							break;
						case 4:
							currentTag.fontDescriptor.pointSize = textScale * 14.0;
							break;
						case 5:
							currentTag.fontDescriptor.pointSize = textScale * 18.0;
							break;
						case 6:
							currentTag.fontDescriptor.pointSize = textScale * 24.0;
							break;
						case 7:
							currentTag.fontDescriptor.pointSize = textScale * 37.0;
							break;	
						case 3:
						default:
							currentTag.fontDescriptor.pointSize = defaultFontDescriptor.pointSize;
							break;
					}
					
					NSString *face = [tagAttributesDict objectForKey:@"face"];
					
					if (face)
					{
						currentTag.fontDescriptor.fontName = face;
					}
					
					NSString *color = [tagAttributesDict objectForKey:@"color"];
					
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
				if (![currentTag isInline] && ![currentTag isMeta] && ![[tmpString string] hasSuffix:@"\n"] && ![[tmpString string] hasSuffix:UNICODE_OBJECT_PLACEHOLDER])
				{
					[tmpString appendString:@"\n"];  // extends attributed area at end
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
						NSAttributedString *prefixString = [currentTag prefixForListItemWithCounter:currentTag.listCounter];
						
						if (prefixString)
						{
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
	[self release];
	return tmpString;
}

#pragma mark Convenience Methods

+ (NSAttributedString *)attributedStringWithHTML:(NSData *)data options:(NSDictionary *)options
{
	NSAttributedString *attrString = [[[NSAttributedString alloc] initWithHTML:data options:options documentAttributes:NULL] autorelease];
	
	return attrString;
}

#pragma mark Utlities

+ (NSAttributedString *)synthesizedSmallCapsAttributedStringWithText:(NSString *)text attributes:(NSDictionary *)attributes
{
	CTFontRef normalFont = (CTFontRef)[attributes objectForKey:(id)kCTFontAttributeName];
	
	DTCoreTextFontDescriptor *smallerFontDesc = [DTCoreTextFontDescriptor fontDescriptorForCTFont:normalFont];
	smallerFontDesc.pointSize *= 0.7;
	CTFontRef smallerFont = [smallerFontDesc newMatchingFont];
	
	NSMutableDictionary *smallAttributes = [attributes mutableCopy];
	[smallAttributes setObject:(id)smallerFont forKey:(id)kCTFontAttributeName];
	CFRelease(smallerFont);
	
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
			[partString release];
		}
		
		if ([scanner scanUpToCharactersFromSet:lowerCaseChars intoString:&part])
		{
			NSAttributedString *partString = [[NSAttributedString alloc] initWithString:part attributes:attributes];
			[tmpString appendAttributedString:partString];
			[partString release];
		}
	}
	
	[smallAttributes release];
	
	return 	[tmpString autorelease];
}

@end
