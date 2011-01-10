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


NSString *NSBaseURLDocumentOption = @"BaseURL";
NSString *NSTextEncodingNameDocumentOption = @"TextEncodingName";

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
	
	
	CGFloat currentFontSize = 12.0;
	
	/*
	 kCTParagraphStyleSpecifierAlignment = 0,
	 kCTParagraphStyleSpecifierFirstLineHeadIndent = 1,
	 kCTParagraphStyleSpecifierHeadIndent = 2,
	 kCTParagraphStyleSpecifierTailIndent = 3,
	 kCTParagraphStyleSpecifierTabStops = 4,
	 kCTParagraphStyleSpecifierDefaultTabInterval = 5,
	 kCTParagraphStyleSpecifierLineBreakMode = 6,
	 kCTParagraphStyleSpecifierLineHeightMultiple = 7,
	 kCTParagraphStyleSpecifierMaximumLineHeight = 8,
	 kCTParagraphStyleSpecifierMinimumLineHeight = 9,
	 kCTParagraphStyleSpecifierLineSpacing = 10,
	 kCTParagraphStyleSpecifierParagraphSpacing = 11,
	 kCTParagraphStyleSpecifierParagraphSpacingBefore = 12,
	 kCTParagraphStyleSpecifierBaseWritingDirection = 13,
	 kCTParagraphStyleSpecifierCount = 14
	 };
	 */
	
	
	// same defaults as OSX:
	/*  NSParagraphStyle = "Alignment 4, LineSpacing 0, ParagraphSpacing 0, ParagraphSpacingBefore 0, HeadIndent 0, 
	 TailIndent 0, FirstLineHeadIndent 0, LineHeight 0/0, LineHeightMultiple 0, LineBreakMode 0, Tabs (\n), 
	 DefaultTabInterval 36, Blocks (null), Lists (null), BaseWritingDirection 0, HyphenationFactor 0, TighteningFactor 0.05, HeaderLevel 0";
	 */
	
	CTTextAlignment alignment = kCTNaturalTextAlignment;
	CGFloat firstLineIndent = 0.0;
	CGFloat defaultTabInterval = 36.0;
	CFArrayRef tabStops = NULL;
	
	CTParagraphStyleSetting settings[] = {
		{kCTParagraphStyleSpecifierAlignment, sizeof(alignment), &alignment},
		{kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(firstLineIndent), &firstLineIndent},
		{kCTParagraphStyleSpecifierDefaultTabInterval, sizeof(defaultTabInterval), &defaultTabInterval},
		{kCTParagraphStyleSpecifierTabStops, sizeof(tabStops), &tabStops},
		
	};	
	
	
	CTParagraphStyleRef defaultParagraphStyle = CTParagraphStyleCreate(settings, 4);
	
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
				else if ([lowercaseTag isEqualToString:@"em"])
				{
					[currentTag setObject:[NSNumber numberWithBool:tagOpen] forKey:@"Italic"];
				}
				else if ([lowercaseTag isEqualToString:@"br"])
				{
					NSAttributedString *newLine = [[[NSAttributedString alloc] initWithString:@"\n"] autorelease];
					[tmpString appendAttributedString:newLine];

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
				NSLog(@"push %@ %@", tagName, currentTag);
				[tagStack addObject:currentTag];
			}
			else if (!tagOpen)
			{
				NSLog(@"pop %@ %@", tagName, [tagStack lastObject]);
				
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
				NSLog(@"Immediately closed: %@ %@", tagName, currentTag);
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
				
				NSInteger symbolicStyle = 0;
				
				if ([[currentTag objectForKey:@"Italic"] boolValue])
				{
					symbolicStyle |= kCTFontItalicTrait;
				}
				
				if ([[currentTag objectForKey:@"Bold"] boolValue])
				{
					symbolicStyle |= kCTFontBoldTrait;
				}
				
				
				NSLog(@"text: %@ %@", tagContents, currentTagAttributes);
				
				NSString *fontFace = [currentTagAttributes objectForKey:@"face"];
				
				
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
				CTFontRef font = CTFontCreateWithFontDescriptor(fontDesc, currentFontSize, NULL);
				
				
				NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
				
				[attributes setObject:(id)font forKey:(id)kCTFontAttributeName];
				[attributes setObject:(id)defaultParagraphStyle forKey:(id)kCTParagraphStyleAttributeName];
				
				NSString *fontColor = [currentTagAttributes objectForKey:@"color"];
				
				if (fontColor)
				{
					UIColor *color = [UIColor colorWithHTMLName:fontColor];
					
					if (color)
					{
						[attributes setObject:(id)[color CGColor] forKey:(id)kCTForegroundColorAttributeName];
					}
				}
				
				NSAttributedString *tagString = [[NSAttributedString alloc] initWithString:tagContents attributes:attributes];
				
				[tmpString appendAttributedString:tagString];
				
				CFRelease(font);
				CFRelease(fontDesc);
			}
			
		}
		
	}
	
	CFRelease(defaultParagraphStyle);
	
	return [self initWithAttributedString:tmpString];
}


@end
