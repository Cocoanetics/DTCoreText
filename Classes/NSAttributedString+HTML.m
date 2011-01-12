//
//  NSAttributedString+HTML.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "NSAttributedString+HTML.h"

#import "NSString+HTML.h"
#import "UIColor+HTML.h"
#import "NSScanner+HTML.h"

// allows variations to cater for different behavior on iOS than OSX to have similar visual output
#define ALLOW_IPHONE_SPECIAL_CASES 1

/* Known Differences:
 - OSX has an entire attributes block for an UL block
 - OSX does not add extra space after UL block
 */

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
		
		// convert from NSNumber to CTTextTab
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
	// specify the appropriate text encoding for the passed data, default is UTF8 
	NSString *textEncodingName = [options objectForKey:NSTextEncodingNameDocumentOption];
	NSStringEncoding encoding = NSUTF8StringEncoding; // default
	
	if (textEncodingName)
	{
		CFStringEncoding cfEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)textEncodingName);
		encoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
	}
	
	// make it a string
	NSString *htmlString = [[NSString alloc] initWithData:data encoding:encoding];
	
	
	NSMutableAttributedString *tmpString = [[[NSMutableAttributedString alloc] init] autorelease];
	NSCharacterSet *tagCharacters = [NSCharacterSet alphanumericCharacterSet];
	
	NSMutableArray *tagStack = [NSMutableArray array];
	
	CGFloat nextParagraphAdditionalSpaceBefore = 0.0;
	CGFloat currentFontSize = 12.0;
	BOOL seenPreviousParagraph = NO;
		
	NSScanner *scanner = [NSScanner scannerWithString:htmlString];
	scanner.charactersToBeSkipped = [NSCharacterSet newlineCharacterSet];
	
	NSMutableDictionary *currentTag = [tagStack lastObject];
	
	while (![scanner isAtEnd]) 
	{
		if ([scanner scanString:@"<" intoString:NULL])
		{
			// tag
			BOOL tagOpen = YES;
			BOOL immediatelyClosed = NO;
			
			if ([scanner scanString:@"/" intoString:NULL])
			{
				// close of tag
				tagOpen = NO;
			}
			
			// read the tag name
			NSString *tagName = nil;
			if ([scanner scanCharactersFromSet:tagCharacters intoString:&tagName])
			{
				NSString *lowercaseTag = [tagName lowercaseString];
				
				currentTag = [NSMutableDictionary dictionaryWithObject:tagName forKey:@"Tag"];
				
				[currentTag setDictionary:[tagStack lastObject]];
				
				[currentTag setObject:lowercaseTag forKey:@"_tag"];
				
				
				if ([lowercaseTag isEqualToString:@"b"])
				{
					[currentTag setObject:[NSNumber numberWithBool:tagOpen] forKey:@"Bold"];
				}
				else if ([lowercaseTag isEqualToString:@"i"])
				{
					[currentTag setObject:[NSNumber numberWithBool:tagOpen] forKey:@"Italic"];
				}
				else if ([lowercaseTag isEqualToString:@"strong"])
				{
					[currentTag setObject:[NSNumber numberWithBool:tagOpen] forKey:@"Bold"];
				}
				else if ([lowercaseTag isEqualToString:@"li"]) 
				{
					if (tagOpen)
					{
						
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
				}
				else if ([lowercaseTag isEqualToString:@"ul"]) 
				{
					if (!tagOpen)
					{
#if ALLOW_IPHONE_SPECIAL_CASES						
						nextParagraphAdditionalSpaceBefore = 12.0;
#endif
					}
				}
				else if ([lowercaseTag isEqualToString:@"em"])
				{
					[currentTag setObject:[NSNumber numberWithBool:tagOpen] forKey:@"Italic"];
				}
				else if ([lowercaseTag hasPrefix:@"h"])
				{
					if (tagOpen)
					{
						NSInteger headerLevel = 0;
						NSScanner *scanner = [NSScanner scannerWithString:lowercaseTag];
						
						// skip h
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
						
						/*
						if (![[tmpString string] hasSuffix:@"\n"])
						{
							// add newline
							NSAttributedString *newLine = [[[NSAttributedString alloc] initWithString:@"\n"] autorelease];
							[tmpString appendAttributedString:newLine];
						}
						 */
						
						// first paragraph after a header needs a newline to not stick to header
						seenPreviousParagraph = NO;
					}
				}
				else if ([lowercaseTag isEqualToString:@"p"])
				{
					if (tagOpen)
					{
						if (nextParagraphAdditionalSpaceBefore>0)
						{
							[currentTag setObject:[NSNumber numberWithFloat:12.0] forKey:@"ParagraphSpacingBefore"];	
							nextParagraphAdditionalSpaceBefore = 0;
						}
						
						[currentTag setObject:[NSNumber numberWithFloat:12.0] forKey:@"ParagraphSpacing"];
					}

					seenPreviousParagraph = YES;
				}
				else if ([lowercaseTag isEqualToString:@"br"])
				{
					immediatelyClosed = YES; 
				}
			}
			
			
			// read until end of tag
			
			
			NSString *attributesStr = nil;
			NSDictionary *tagAttributesDict = nil;
			if ([scanner scanUpToString:@">" intoString:&attributesStr])
			{
				// do something with the attributes
				tagAttributesDict = [[[attributesStr dictionaryOfAttributesFromTag] mutableCopy] autorelease];
				
				NSMutableDictionary *existingDict = [currentTag objectForKey:@"Attributes"];
				
				if (tagAttributesDict)
				{
					if (existingDict)
					{
						[existingDict setDictionary:tagAttributesDict];
					}
					else 
					{
						[currentTag setObject:tagAttributesDict forKey:@"Attributes"];
					}
				}
				
				if ([attributesStr hasSuffix:@"/"])
				{
					// tag is immediately terminated like <br/>
					immediatelyClosed = YES;
				}
			}
			
			// skip ending of tag
			[scanner scanString:@">" intoString:NULL];
			
			if (tagOpen&&!immediatelyClosed)
			{
				[tagStack addObject:currentTag];
			}
			else if (!tagOpen)
			{
				if ([tagStack count])
				{
					[tagStack removeLastObject];
					currentTag = [tagStack lastObject];
				}
				else 
				{
					currentTag = nil;
				}

					
				;
			}
			else if (immediatelyClosed)
			{
				// if it's immediately closed it's not relevant for following body
				currentTag = [tagStack lastObject];
			}
		}
		else 
		{
			// must be contents of tag
			NSString *tagContents = nil;
			
			if ([scanner scanUpToString:@"<" intoString:&tagContents])
			{
				NSMutableDictionary *fontAttributes = [NSMutableDictionary dictionary];
				NSMutableDictionary *fontStyleAttributes = [NSMutableDictionary dictionary];
				
				NSDictionary *currentTagAttributes = [currentTag objectForKey:@"Attributes"];
				
				NSLog(@"%@", currentTag);
				
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

				
				CTFontDescriptorRef fontDesc = CTFontDescriptorCreateWithAttributes((CFDictionaryRef)fontAttributes);
				CTFontRef font = CTFontCreateWithFontDescriptor(fontDesc, fontSize, NULL);
				
				CGFloat paragraphSpacing = [[currentTag objectForKey:@"ParagraphSpacing"] floatValue];
				CGFloat paragraphSpacingBefore = [[currentTag objectForKey:@"ParagraphSpacingBefore"] floatValue];
				CGFloat headIndent = [[currentTag objectForKey:@"HeadIndent"] floatValue];

				NSArray *tabStops = [currentTag objectForKey:@"TabStops"];
				
				CTParagraphStyleRef paragraphStyle = createParagraphStyle(paragraphSpacingBefore, paragraphSpacing, headIndent, tabStops);
				
				NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
				
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

				// HTML ignores newlines
				tagContents = [tagContents stringByReplacingOccurrencesOfString:@"\n" withString:@" "];

				
				
				if ([[currentTag objectForKey:@"_tag"] isEqualToString:@"li"])
				{
					// li prefixes bullet
					tagContents = [@"\x09\u2022\x09" stringByAppendingString:tagContents];
				}
				
				// add newline after block contents if a new block follows
				
				NSString *nextTag = [scanner peekNextTag];
				
				if ([nextTag isEqualToString:@"br"])
				{
					// add linefeed
					tagContents = [tagContents stringByAppendingString:@"\u2028"];
				}
				
				if (![nextTag isInlineTag])
				{
					tagContents = [tagContents stringByAppendingString:@"\n"];
				}

				NSAttributedString *tagString = [[NSAttributedString alloc] initWithString:tagContents attributes:attributes];
				[tmpString appendAttributedString:tagString];
				
				
								
				CFRelease(font);
				CFRelease(fontDesc);
				CFRelease(paragraphStyle);
			}
			
		}
		
	}
	
	return [self initWithAttributedString:tmpString];
}


@end
