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

// Allows variations to cater for different behavior on iOS than OSX to have similar visual output
#define ALLOW_IPHONE_SPECIAL_CASES 1

// adds the path of tags to attributes dict
//#define ADD_TAG_PATH 1

/* Known Differences:
 - OSX has an entire attributes block for an UL block
 - OSX does not add extra space after UL block
 */

// standard options
NSString *NSBaseURLDocumentOption = @"NSBaseURLDocumentOption";
NSString *NSTextEncodingNameDocumentOption = @"NSTextEncodingNameDocumentOption";
NSString *NSTextSizeMultiplierDocumentOption = @"NSTextSizeMultiplierDocumentOption";

// custom options
NSString *DTMaxImageSize = @"DTMaxImageSize";
NSString *DTDefaultFontFamily = @"DTDefaultFontFamily";
NSString *DTDefaultTextColor = @"DTDefaultTextColor";
NSString *DTDefaultLinkColor = @"DTDefaultLinkColor";


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
	NSString *htmlString = [[NSString alloc] initWithData:data encoding:encoding];
	
    // for performance we will return this mutable string
	NSMutableAttributedString *tmpString = [[NSMutableAttributedString alloc] init];
	
	NSMutableArray *tagStack = [NSMutableArray array];
    // NSMutableDictionary *fontCache = [NSMutableDictionary dictionaryWithCapacity:10];
	
	CGFloat nextParagraphAdditionalSpaceBefore = 0.0;
	BOOL seenPreviousParagraph = NO;
	NSInteger listCounter = 0;  // Unordered, set to 1 to get ordered list
	BOOL needsListItemStart = NO;
	BOOL needsNewLineBefore = NO;
	
	
	// we cannot skip any characters, NLs turn into spaces and multi-spaces get compressed to singles
	NSScanner *scanner = [NSScanner scannerWithString:htmlString];
	scanner.charactersToBeSkipped = nil;
    
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
    
    // default paragraph style
    DTCoreTextParagraphStyle *defaultParagraphStyle = [DTCoreTextParagraphStyle defaultParagraphStyle];
    
    DTHTMLElement *defaultTag = [[[DTHTMLElement alloc] init] autorelease];
    defaultTag.fontDescriptor = defaultFontDescriptor;
    defaultTag.paragraphStyle = defaultParagraphStyle;
    
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
    
	[tagStack addObject:defaultTag];
	
	DTHTMLElement *currentTag = [tagStack lastObject];
	
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
			if (tagOpen)
			{
                // make new tag as copy of previous tag
                currentTag = [[currentTag copy] autorelease];
                currentTag.tagName = tagName;
                
                if (![currentTag isInline])
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
			
			if ([tagName isEqualToString:@"img"] && tagOpen)
			{
				immediatelyClosed = YES;
				
				NSString *src = [tagAttributesDict objectForKey:@"src"];
				CGFloat width = [[tagAttributesDict objectForKey:@"width"] intValue];
				CGFloat height = [[tagAttributesDict objectForKey:@"height"] intValue];
				
				// assume it's a relative file URL
                UIImage *image;
                
                if (baseURL)
                {
                    // relative file URL
                    
                    NSURL *imageURL = [NSURL URLWithString:src relativeToURL:baseURL];
                    image = [UIImage imageWithContentsOfFile:[imageURL path]];
                }
                else
                {
                    // file in app bundle
                    NSString *path = [[NSBundle mainBundle] pathForResource:src ofType:nil];
                    image = [UIImage imageWithContentsOfFile:path];
                }
				
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
                
                // option DTMaxImageSize
                if (maxImageSizeValue)
                {
                    CGSize maxImageSize = [maxImageSizeValue CGSizeValue];
                    
                    if (maxImageSize.width < width || maxImageSize.height < height)
                    {
                        CGSize adjustedSize = sizeThatFitsKeepingAspectRatio(image.size,maxImageSize);
                        
                        width = adjustedSize.width;
                        height = adjustedSize.height;
                    }
                }
				
				DTTextAttachment *attachment = [[[DTTextAttachment alloc] init] autorelease];
				attachment.contents = image;
				attachment.size = CGSizeMake(width, height);
                
                currentTag.textAttachment = attachment;
                
				if (needsNewLineBefore)
				{
					if ([tmpString length] && ![[tmpString string] hasSuffix:@"\n"])
					{
                        [tmpString appendString:@"\n"];
					}
					
					needsNewLineBefore = NO;
				}
                
                [tmpString appendAttributedString:[currentTag attributedString]];
			}
			else if ([tagName isEqualToString:@"video"] && tagOpen)
			{
				// hide contents of recognized tag
                currentTag.tagContentInvisible = YES;
                
				CGFloat width = [[tagAttributesDict objectForKey:@"width"] intValue];
				CGFloat height = [[tagAttributesDict objectForKey:@"height"] intValue];
				
				if (width==0 || height==0)
				{
					width = 300;
					height = 225;
				}
				
				DTTextAttachment *attachment = [[[DTTextAttachment alloc] init] autorelease];
				attachment.contents = [NSURL URLWithString:[tagAttributesDict objectForKey:@"src"]];
                attachment.contentType = DTTextAttachmentTypeVideoURL;
				attachment.size = CGSizeMake(width, height);
                
                currentTag.textAttachment = attachment;
                
                [tmpString appendAttributedString:[currentTag attributedString]];
			}
			else if ([tagName isEqualToString:@"a"])
			{
				if (tagOpen)
				{
                    currentTag.underlineStyle = kCTUnderlineStyleSingle;
					
					// remove line breaks and whitespace in links
					NSString *cleanString = [[tagAttributesDict objectForKey:@"href"] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
					cleanString = [cleanString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
					
					NSURL *link = [NSURL URLWithString:cleanString];
					
					// deal with relative URL
					if (![link scheme])
					{
						link = [NSURL URLWithString:cleanString relativeToURL:baseURL];
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
					needsListItemStart = YES;
                    currentTag.paragraphStyle.paragraphSpacing = 0;
					
                    currentTag.paragraphStyle.headIndent = 25.0 * textScale;
                    [currentTag.paragraphStyle addTabStopAtPosition:11.0 alignment:kCTLeftTextAlignment];
					
#if ALLOW_IPHONE_SPECIAL_CASES
                    [currentTag.paragraphStyle addTabStopAtPosition:25.0 * textScale alignment:kCTLeftTextAlignment];
#else
                    [currentTag.paragraphStyle addTabStopAtPosition:36.0 * textScale alignment:kCTLeftTextAlignment];
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
			else if ([tagName isEqualToString:@"del"]) 
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
					listCounter = 1;
				} 
				else 
				{
#if ALLOW_IPHONE_SPECIAL_CASES						
					nextParagraphAdditionalSpaceBefore = defaultFontDescriptor.pointSize;
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
				}
			}
			else if ([tagName isEqualToString:@"sub"])
			{
				if (tagOpen)
				{
                    currentTag.superscriptStyle = -1;
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
                                currentTag.paragraphStyle.paragraphSpacing = 16.0;
								currentTag.fontDescriptor.pointSize = textScale * 24.0;
								break;
							}
							case 2:
							{
                                currentTag.paragraphStyle.paragraphSpacing = 14.0;
								currentTag.fontDescriptor.pointSize = textScale * 18.0;
								break;
							}
							case 3:
							{
                                currentTag.paragraphStyle.paragraphSpacing = 14.0;
								currentTag.fontDescriptor.pointSize = textScale * 14.0;
								break;
							}
							case 4:
							{
                                currentTag.paragraphStyle.paragraphSpacing = 15.0;
								currentTag.fontDescriptor.pointSize = textScale * 12.0;
								break;
							}
							case 5:
							{
                                currentTag.paragraphStyle.paragraphSpacing = 16.0;
								currentTag.fontDescriptor.pointSize = textScale * 10.0;
								break;
							}
							case 6:
							{
                                currentTag.paragraphStyle.paragraphSpacing = 20.0;
								currentTag.fontDescriptor.pointSize = textScale * 9.0;
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
						currentTag.fontDescriptor.fontFamily = face;
					}
				}
			}
			else if ([tagName isEqualToString:@"p"])
			{
				if (tagOpen)
				{
                    currentTag.paragraphStyle.paragraphSpacing = defaultFontDescriptor.pointSize;
					
					seenPreviousParagraph = YES;
				}
				
			}
			else if ([tagName isEqualToString:@"br"])
			{
				immediatelyClosed = YES; 
                
                [tmpString appendString:UNICODE_LINE_FEED];
			}
			
			
			// convert CSS Styles into our own style
            NSString *styleString = [tagAttributesDict objectForKey:@"style"];
            
            if (styleString)
            {
                [currentTag parseStyleString:styleString];
            }
			
			// --------------------- push tag on stack if it's opening
			if (tagOpen&&!immediatelyClosed)
			{
				[tagStack addObject:currentTag];
			}
			else if (!tagOpen)
			{
				// block items have to have a NL at the end.
				if (![currentTag isInline] && ![[tmpString string] hasSuffix:@"\n"] && ![[tmpString string] hasSuffix:UNICODE_OBJECT_PLACEHOLDER])
				{
                    [tmpString appendString:@"\n"];  // extends attributed area at end
				}
				
				needsNewLineBefore = NO;
				
				
				if ([tagStack count])
				{
					// check if this tag is indeed closing the currently open one
					DTHTMLElement *topStackTag = [tagStack lastObject];
					
					if ([tagName isEqualToString:topStackTag.tagName])
					{
						[tagStack removeLastObject];
						currentTag = [tagStack lastObject];
					}
					else 
					{
						NSLog(@"Ignoring non-open tag %@", topStackTag.tagName);
					}
					
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
					tagContents = [tagContents stringByNormalizingWhitespace];
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
								tagContents = [@"\n" stringByAppendingString:tagContents];
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
                    
#if ADD_TAG_PATH 
                    // adds the path of the tag containing this string to the attribute dictionary
                    NSMutableArray *tagPath = [[NSMutableArray alloc] init];
                    for (NSDictionary *oneTag in tagStack)
                    {
                        NSString *tag = [oneTag objectForKey:@"_tag"];
                        if (!tag)
                        {
                            tag = @"";
                        }
                        [tagPath addObject:tag];  
                    }
                    
                    [attributes setObject:[tagPath componentsJoinedByString:@"/"] forKey:@"Path"];
                    [tagPath release];
#endif
                    
                    // we don't want whitespace before first tag to turn into paragraphs
                    if (![tagName isEqualToString:@"html"])
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
	NSAttributedString *attrString = [[[NSAttributedString alloc] initWithHTML:data options:options documentAttributes:NULL] autorelease];
	
	return attrString;
}

@end
