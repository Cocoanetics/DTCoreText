//
//  NSAttributedString+HTML.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <CoreText/CoreText.h>

#import "NSAttributedString+HTML.h"
#import "NSString+HTML.h"
#import "UIColor+HTML.h"
#import "NSScanner+HTML.h"
#import "NSAttributedStringRunDelegates.h"
#import "DTTextAttachment.h"

// Allows variations to cater for different behavior on iOS than OSX to have similar visual output
#define ALLOW_IPHONE_SPECIAL_CASES 1

/* Known Differences:
 - OSX has an entire attributes block for an UL block
 - OSX does not add extra space after UL block
 */

// TODO: Decode HTML Entities
// TODO: make attributes case independent (currently lowercase)

#define UNICODE_OBJECT_PLACEHOLDER @"\ufffc"
#define UNICODE_LINE_FEED @"\u2028"


NSString *NSBaseURLDocumentOption = @"BaseURL";
NSString *NSTextEncodingNameDocumentOption = @"TextEncodingName";

CTParagraphStyleRef createDefaultParagraphStyle()
{
	CTTextAlignment alignment = kCTNaturalTextAlignment;
	CGFloat firstLineIndent = 0.0;
	CGFloat defaultTabInterval = 36.0;
	CFArrayRef tabStops = NULL;
	
	CTParagraphStyleSetting settings[] = {
		{kCTParagraphStyleSpecifierAlignment, sizeof(alignment), &alignment},
		{kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(firstLineIndent), &firstLineIndent},
		{kCTParagraphStyleSpecifierDefaultTabInterval, sizeof(defaultTabInterval), &defaultTabInterval},
		{kCTParagraphStyleSpecifierTabStops, sizeof(tabStops), &tabStops}
		
	};	
	
	return CTParagraphStyleCreate(settings, 4);
}

CTParagraphStyleRef createParagraphStyle(CGFloat paragraphSpacingBefore, CGFloat paragraphSpacing, CGFloat headIndent, NSArray *tabStops)
{
	CTTextAlignment alignment = kCTNaturalTextAlignment;
	CGFloat firstLineIndent = 0.0;
	CGFloat defaultTabInterval = 36.0;
	
	NSMutableArray *textTabs = nil;
	
	NSInteger numTabs = [tabStops count];
	if (numTabs)
	{
		textTabs = [NSMutableArray array];
		
		// Convert from NSNumber to CTTextTab
		for (NSNumber *num in tabStops)
		{
			CTTextTabRef tab = CTTextTabCreate(kCTLeftTextAlignment, [num floatValue], NULL);
			[textTabs addObject:(id)tab];
			CFRelease(tab);
		}
	}
	
	CTParagraphStyleSetting settings[] = {
		{kCTParagraphStyleSpecifierAlignment, sizeof(alignment), &alignment},
		{kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(firstLineIndent), &firstLineIndent},
		{kCTParagraphStyleSpecifierDefaultTabInterval, sizeof(defaultTabInterval), &defaultTabInterval},
		{kCTParagraphStyleSpecifierTabStops, sizeof(textTabs), &textTabs},
		{kCTParagraphStyleSpecifierParagraphSpacing, sizeof(paragraphSpacing), &paragraphSpacing},
		{kCTParagraphStyleSpecifierParagraphSpacingBefore, sizeof(paragraphSpacingBefore), &paragraphSpacingBefore},
		{kCTParagraphStyleSpecifierHeadIndent, sizeof(headIndent), &headIndent}
	};	
	
	return CTParagraphStyleCreate(settings, 7);
}


@implementation NSAttributedString (HTML)

- (id)initWithHTML:(NSData *)data documentAttributes:(NSDictionary **)dict
{
	return [self initWithHTML:data options:nil documentAttributes:dict];
}


- (id)initWithHTML:(NSData *)data baseURL:(NSURL *)base documentAttributes:(NSDictionary **)dict
{
	NSDictionary *optionsDict = [NSDictionary dictionaryWithObject:base forKey:NSBaseURLDocumentOption];
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
	
	// Make it a string
	NSString *htmlString = [[NSString alloc] initWithData:data encoding:encoding];
	
	// trim whitespace
	htmlString = [htmlString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	NSMutableAttributedString *tmpString = [[[NSMutableAttributedString alloc] init] autorelease];
	
	NSMutableArray *tagStack = [NSMutableArray array];
	
	CGFloat nextParagraphAdditionalSpaceBefore = 0.0;
	CGFloat currentFontSize = 12.0;
	BOOL seenPreviousParagraph = NO;
	NSInteger listCounter = 0;  // Unordered, set to 1 to get ordered list
	BOOL needsListItemStart = NO;
	BOOL needsNewLineBefore = NO;
	
	NSScanner *scanner = [NSScanner scannerWithString:htmlString];
	scanner.charactersToBeSkipped = [NSCharacterSet newlineCharacterSet];
	
	NSMutableDictionary *currentTag = [tagStack lastObject];
	NSDictionary *previousAttributes = NULL;
	
	while (![scanner isAtEnd]) 
	{
		NSString *tagName = nil;
		NSDictionary *tagAttributesDict = nil;
		BOOL tagOpen = YES;
		BOOL immediatelyClosed = NO;
		
		if ([scanner scanHTMLTag:&tagName attributes:&tagAttributesDict isOpen:&tagOpen isClosed:&immediatelyClosed])
		{
			if (![tagName isInlineTag])
			{
				// next text needs a NL
				needsNewLineBefore = YES;
			}
			
			NSDictionary *previousTag = currentTag;
			
			currentTag = [NSMutableDictionary dictionaryWithObject:tagName forKey:@"Tag"];
			[currentTag setDictionary:[tagStack lastObject]];
			[currentTag setObject:tagName forKey:@"_tag"];
			
			if (tagOpen)
			{
				NSDictionary *previousAttributes = [previousTag objectForKey:@"Attributes"];
				
				NSMutableDictionary *mutableAttributes = [NSMutableDictionary dictionaryWithDictionary:previousAttributes];
				
				for (NSString *oneKey in [tagAttributesDict allKeys])
				{
					[mutableAttributes setObject:[tagAttributesDict objectForKey:oneKey] forKey:oneKey];
				}
				
				tagAttributesDict = mutableAttributes;
				
				[currentTag setObject:mutableAttributes forKey:@"Attributes"];
			}
			
			// ---------- Processing
			
			if ([tagName isEqualToString:@"img"] && tagOpen)
			{
				immediatelyClosed = YES;
				
				NSString *src = [tagAttributesDict objectForKey:@"src"];
				CGFloat width = [[tagAttributesDict objectForKey:@"width"] intValue];
				CGFloat height = [[tagAttributesDict objectForKey:@"height"] intValue];
				
				// assume it's a relative file URL
				NSString *path = [[NSBundle mainBundle] pathForResource:src ofType:nil];
				UIImage *image = [UIImage imageWithContentsOfFile:path];
				
				if (image)
				{
					if (!width)
					{
						width = image.size.width;
					}
					
					if (!height)
					{
						height = image.size.height;
					}
				}
				
				DTTextAttachment *attachment = [[[DTTextAttachment alloc] init] autorelease];
				attachment.contents = image;
				attachment.size = CGSizeMake(width, height);
				
				CTRunDelegateRef embeddedObjectRunDelegate = createEmbeddedObjectRunDelegate(attachment);
				
				CTParagraphStyleRef paragraphStyle = createParagraphStyle(0, 0, 0, 0);
				
			//	[localAttributes setObject:(id)paragraphStyle forKey:(id)kCTParagraphStyleAttributeName];
				
			//	NSString *fontColor = [currentTagAttributes objectForKey:@"color"];
				
	//					[attributes setObject:(id)[color CGColor] forKey:(id)kCTForegroundColorAttributeName];
				
				NSMutableDictionary *localAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:attachment, @"DTTextAttachment",
												 (id)embeddedObjectRunDelegate, kCTRunDelegateAttributeName, 
												 (id)paragraphStyle, kCTParagraphStyleAttributeName, nil];
				CFRelease(embeddedObjectRunDelegate);
				
				id link = [currentTag objectForKey:@"DTLink"];
				if (link)
				{
					[localAttributes setObject:link forKey:@"DTLink"];
				}
				
				if (needsNewLineBefore)
				{
					if ([tmpString length] && ![[tmpString string] hasSuffix:@"\n"])
					{
						NSAttributedString *string = [[[NSAttributedString alloc] initWithString:@"\n" attributes:previousAttributes] autorelease];
						[tmpString appendAttributedString:string];
					}
					
					needsNewLineBefore = NO;
				}
				
				NSAttributedString *string = [[[NSAttributedString alloc] initWithString:UNICODE_OBJECT_PLACEHOLDER attributes:localAttributes] autorelease];
				[tmpString appendAttributedString:string];
			}
			else if ([tagName isEqualToString:@"a"])
			{
				if (tagOpen)
				{
					[currentTag setObject:[NSNumber numberWithInt:kCTUnderlineStyleSingle] forKey:@"UnderlineStyle"];
					NSMutableDictionary *currentTagAttributes = [currentTag objectForKey:@"Attributes"];
					[currentTagAttributes setObject:@"#0000EE" forKey:@"color"];
					
					NSURL *link = [NSURL URLWithString:[tagAttributesDict objectForKey:@"href"]];
					
					if (link)
					{
						[currentTag setObject:link forKey:@"DTLink"];
					}
				}
			}
			else if ([tagName isEqualToString:@"b"])
			{
				[currentTag setObject:[NSNumber numberWithBool:tagOpen] forKey:@"Bold"];
			}
			else if ([tagName isEqualToString:@"i"])
			{
				[currentTag setObject:[NSNumber numberWithBool:tagOpen] forKey:@"Italic"];
			}
			else if ([tagName isEqualToString:@"strong"])
			{
				[currentTag setObject:[NSNumber numberWithBool:tagOpen] forKey:@"Bold"];
			}
			else if ([tagName isEqualToString:@"li"]) 
			{
				if (tagOpen)
				{
					needsListItemStart = YES;
					[currentTag setObject:[NSNumber numberWithFloat:0.0] forKey:@"ParagraphSpacing"];
					
					
					
#if ALLOW_IPHONE_SPECIAL_CASES						
					[currentTag setObject:[NSNumber numberWithFloat:25.0] forKey:@"HeadIndent"];
					[currentTag setObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:11.0],
										   [NSNumber numberWithFloat:25.0], nil] forKey:@"TabStops"];
#else
					[currentTag setObject:[NSNumber numberWithFloat:25.0] forKey:@"HeadIndent"];
					[currentTag setObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:11.0],
										   [NSNumber numberWithFloat:36.0], nil] forKey:@"TabStops"];
					
#endif
				}
				else 
				{
					needsListItemStart = NO;
					
					if (listCounter)
					{
						listCounter++;
					}
				}
				
			}
			else if ([tagName isEqualToString:@"del"]) 
			{
				if (tagOpen)
				{
					[currentTag setObject:[NSNumber numberWithBool:YES] forKey:@"_StrikeOut"];
				}
			}
			else if ([tagName isEqualToString:@"ol"]) 
			{
				if (tagOpen)
				{
					listCounter = 1;
				} 
				else 
				{
#if ALLOW_IPHONE_SPECIAL_CASES						
					nextParagraphAdditionalSpaceBefore = 12.0;
#endif
				}
			}
			else if ([tagName isEqualToString:@"ul"]) 
			{
				if (tagOpen)
				{
					listCounter = 0;
				}
				else 
				{
#if ALLOW_IPHONE_SPECIAL_CASES						
					nextParagraphAdditionalSpaceBefore = 12.0;
#endif
				}
			}
			else if ([tagName isEqualToString:@"em"])
			{
				[currentTag setObject:[NSNumber numberWithBool:tagOpen] forKey:@"Italic"];
			}
			else if ([tagName isEqualToString:@"u"])
			{
				if (tagOpen)
				{
					[currentTag setObject:[NSNumber numberWithInt:kCTUnderlineStyleSingle] forKey:@"UnderlineStyle"];
				}
			}
			else if ([tagName isEqualToString:@"sup"])
			{
				if (tagOpen)
				{
					[currentTag setObject:[NSNumber numberWithInt:1] forKey:@"Superscript"];
				}
			}
			else if ([tagName isEqualToString:@"sub"])
			{
				if (tagOpen)
				{
					[currentTag setObject:[NSNumber numberWithInt:-1] forKey:@"Superscript"];
				}
			}
			else if ([tagName hasPrefix:@"h"])
			{
				if (tagOpen)
				{
					NSInteger headerLevel = 0;
					NSScanner *scanner = [NSScanner scannerWithString:tagName];
					
					// Skip h
					[scanner scanString:@"h" intoString:NULL];
					
					if ([scanner scanInteger:&headerLevel])
					{
						[currentTag setObject:[NSNumber numberWithInteger:headerLevel] forKey:@"HeaderLevel"];	
						[currentTag setObject:[NSNumber numberWithBool:YES] forKey:@"Bold"];
						
						switch (headerLevel) 
						{
							case 1:
							{
								[currentTag setObject:[NSNumber numberWithFloat:16.0] forKey:@"ParagraphSpacing"];
								[currentTag setObject:[NSNumber numberWithFloat:24.0] forKey:@"FontSize"];
								break;
							}
							case 2:
							{
								[currentTag setObject:[NSNumber numberWithFloat:14.0] forKey:@"ParagraphSpacing"];	
								[currentTag setObject:[NSNumber numberWithFloat:18.0] forKey:@"FontSize"];
								break;
							}
							case 3:
							{
								[currentTag setObject:[NSNumber numberWithFloat:14.0] forKey:@"ParagraphSpacing"];
								[currentTag setObject:[NSNumber numberWithFloat:14.0] forKey:@"FontSize"];
								
								break;
							}
							case 4:
							{
								[currentTag setObject:[NSNumber numberWithFloat:15.0] forKey:@"ParagraphSpacing"];	
								[currentTag setObject:[NSNumber numberWithFloat:12.0] forKey:@"FontSize"];
								break;
							}
							case 5:
							{
								[currentTag setObject:[NSNumber numberWithFloat:16.0] forKey:@"ParagraphSpacing"];	
								[currentTag setObject:[NSNumber numberWithFloat:10.0] forKey:@"FontSize"];
								break;
							}
							case 6:
							{
								[currentTag setObject:[NSNumber numberWithFloat:20.0] forKey:@"ParagraphSpacing"];	
								[currentTag setObject:[NSNumber numberWithFloat:9.0] forKey:@"FontSize"];
								break;
							}
							default:
								break;
						}
					}
					
					// First paragraph after a header needs a newline to not stick to header
					seenPreviousParagraph = NO;
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
							[currentTag setObject:[NSNumber numberWithFloat:9.0] forKey:@"FontSize"];
							break;
						case 2:
							[currentTag setObject:[NSNumber numberWithFloat:10.0] forKey:@"FontSize"];
							break;
						case 4:
							[currentTag setObject:[NSNumber numberWithFloat:14.0] forKey:@"FontSize"];
							break;
						case 5:
							[currentTag setObject:[NSNumber numberWithFloat:18.0] forKey:@"FontSize"];
							break;
						case 6:
							[currentTag setObject:[NSNumber numberWithFloat:24.0] forKey:@"FontSize"];
							break;
						case 7:
							[currentTag setObject:[NSNumber numberWithFloat:37.0] forKey:@"FontSize"];
							break;	
						case 3:
						default:
							[currentTag setObject:[NSNumber numberWithFloat:12.0] forKey:@"FontSize"];
							break;
					}
				}
			}
			else if ([tagName isEqualToString:@"p"])
			{
				if (tagOpen)
				{
					[currentTag setObject:[NSNumber numberWithFloat:12.0] forKey:@"ParagraphSpacing"];
					
					seenPreviousParagraph = YES;
				}
				
			}
			else if ([tagName isEqualToString:@"br"])
			{
				immediatelyClosed = YES; 
			}
			
			if (tagOpen&&!immediatelyClosed)
			{
				[tagStack addObject:currentTag];
			}
			else if (!tagOpen)
			{
				// block items have to have a NL at the end.
				if (![tagName isInlineTag] && ![[tmpString string] hasSuffix:@"\n"] && ![[tmpString string] hasSuffix:UNICODE_OBJECT_PLACEHOLDER])
				{
					// remove extra space
					previousAttributes = nil;
					
					NSAttributedString *string = [[[NSAttributedString alloc] initWithString:@"\n" attributes:previousAttributes] autorelease];
					[tmpString appendAttributedString:string];
				}
				
				needsNewLineBefore = NO;
				
				
				if ([tagStack count])
				{
					[tagStack removeLastObject];
					currentTag = [tagStack lastObject];
				}
				else 
				{
					currentTag = nil;
				}
			}
			else if (immediatelyClosed)
			{
				// If it's immediately closed it's not relevant for following body
				currentTag = [tagStack lastObject];
			}
		}
		else 
		{
			//----------------------------------------- TAG CONTENTS -----------------------------------------
			NSString *tagContents = nil;
			
			if ([scanner scanUpToString:@"<" intoString:&tagContents])
			{
				NSMutableDictionary *fontAttributes = [NSMutableDictionary dictionary];
				NSMutableDictionary *fontStyleAttributes = [NSMutableDictionary dictionary];
				
				NSDictionary *currentTagAttributes = [currentTag objectForKey:@"Attributes"];
				
				NSInteger symbolicStyle = 0;
				
				if ([[currentTag objectForKey:@"Italic"] boolValue])
				{
					symbolicStyle |= kCTFontItalicTrait;
				}
				
				if ([[currentTag objectForKey:@"Bold"] boolValue])
				{
					symbolicStyle |= kCTFontBoldTrait;
				}
				
				NSString *fontFace = [currentTagAttributes objectForKey:@"face"];
				CGFloat fontSize = [[currentTag objectForKey:@"FontSize"] floatValue];
				
				if (fontSize==0)
				{
					fontSize = currentFontSize;
				}				
				
				[fontStyleAttributes setObject:[NSNumber numberWithInt:symbolicStyle] forKey:(NSString *)kCTFontSymbolicTrait];
				
				[fontAttributes setObject:fontStyleAttributes forKey:(id)kCTFontTraitsAttribute];
				
				if (fontFace)
				{
					[fontAttributes setObject:fontFace forKey:(id)kCTFontFamilyNameAttribute];
				}
				else 
				{
					[fontAttributes setObject:@"Times New Roman" forKey:(id)kCTFontFamilyNameAttribute];
				}
				
				NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
				
				NSNumber *superscriptStyle = [currentTag objectForKey:@"Superscript"];
				if ([superscriptStyle intValue])
				{
					fontSize = fontSize / 1.2;
					[attributes setObject:superscriptStyle forKey:(id)kCTSuperscriptAttributeName];
					
				}
				
				id runDelegate = [currentTag objectForKey:@"_RunDelegate"];
				if (runDelegate)
				{
					[attributes setObject:runDelegate forKey:(id)kCTRunDelegateAttributeName];
				}
				
				id link = [currentTag objectForKey:@"DTLink"];
				if (link)
				{
					[attributes setObject:link forKey:@"DTLink"];
				}
				
				CTFontDescriptorRef fontDesc = CTFontDescriptorCreateWithAttributes((CFDictionaryRef)fontAttributes);
				CTFontRef font = CTFontCreateWithFontDescriptor(fontDesc, fontSize, NULL);
				
				CGFloat paragraphSpacing = [[currentTag objectForKey:@"ParagraphSpacing"] floatValue];
				CGFloat paragraphSpacingBefore = [[currentTag objectForKey:@"ParagraphSpacingBefore"] floatValue];
				
#if ALLOW_IPHONE_SPECIAL_CASES				
				if (tagOpen && ![tagName isInlineTag] && ![tagName isEqualToString:@"li"])
				{
					if (nextParagraphAdditionalSpaceBefore>0)
					{
						// FIXME: add extra space properly
						// this also works, but breaks UnitTest for lists
						//tagContents = [UNICODE_LINE_FEED stringByAppendingString:tagContents];
						
						//paragraphSpacingBefore += nextParagraphAdditionalSpaceBefore;
						nextParagraphAdditionalSpaceBefore = 0;
					}
				}
#endif
				
				
				CGFloat headIndent = [[currentTag objectForKey:@"HeadIndent"] floatValue];
				
				NSArray *tabStops = [currentTag objectForKey:@"TabStops"];
				
				CTParagraphStyleRef paragraphStyle = createParagraphStyle(paragraphSpacingBefore, paragraphSpacing, headIndent, tabStops);
				
				[attributes setObject:(id)font forKey:(id)kCTFontAttributeName];
				[attributes setObject:(id)paragraphStyle forKey:(id)kCTParagraphStyleAttributeName];
				
				NSString *fontColor = [currentTagAttributes objectForKey:@"color"];
				
				if (fontColor)
				{
					UIColor *color = [UIColor colorWithHTMLName:fontColor];
					
					if (color)
					{
						[attributes setObject:(id)[color CGColor] forKey:(id)kCTForegroundColorAttributeName];
					}
				}
				
				NSNumber *underlineStyle = [currentTag objectForKey:@"UnderlineStyle"];
				if (underlineStyle)
				{
					[attributes setObject:underlineStyle forKey:(id)kCTUnderlineStyleAttributeName];
				}
				
				NSNumber *strikeOut = [currentTag objectForKey:@"_StrikeOut"];
				
				if (strikeOut)
				{
					[attributes setObject:strikeOut forKey:@"_StrikeOut"];
				}
				
				// HTML ignores newlines
				tagContents = [tagContents stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
				
				if (needsListItemStart)
				{
					if (listCounter)
					{
						NSString *prefix = [NSString stringWithFormat:@"\x09%d.\x09", listCounter];
						
						tagContents = [prefix stringByAppendingString:tagContents];
					}
					else
					{
						// Ul li prefixes bullet
						tagContents = [@"\x09\u2022\x09" stringByAppendingString:tagContents];
					}
					
					needsListItemStart = NO;
				}
				
				
				// TODO: Needs better handling of whitespace compression and adding space between tags if there are newlines
				if (![tagContents hasPrefix:@" "])
				{
					
					
					if ([[tmpString string] length] && ![[tmpString string] hasSuffix:@" "] && ![[tmpString string] hasSuffix:@"\n"])
					{
						tagContents = [@" " stringByAppendingString:tagContents];
					}
				}
				
				
				// Add newline after block contents if a new block follows
				NSString *nextTag = [scanner peekNextTagSkippingClosingTags:YES];
				
				if ([nextTag isEqualToString:@"br"])
				{
					// Add linefeed
					tagContents = [tagContents stringByAppendingString:UNICODE_LINE_FEED];
				}
				else
				{
					
					// add paragraph break if this is the end of paragraph
					if (nextTag && ![nextTag isInlineTag])
					{
						if ([tagContents length])
						{
							tagContents = [tagContents stringByAppendingString:@"\n"];
						}
					}
				}
				
				if (needsNewLineBefore)
				{
					if ([tmpString length])
					{
						if (![[tmpString string] hasSuffix:@"\n"])
						{
							tagContents = [@"\n" stringByAppendingString:tagContents];
						}
					}
					needsNewLineBefore = NO;
				}
				
				NSAttributedString *tagString = [[NSAttributedString alloc] initWithString:tagContents attributes:attributes];
				[tmpString appendAttributedString:tagString];
				[tagString release];
				
				previousAttributes = attributes;
				
				CFRelease(font);
				CFRelease(fontDesc);
				CFRelease(paragraphStyle);
			}
			
		}
		
	}
	
	return [self initWithAttributedString:tmpString];
}


@end
