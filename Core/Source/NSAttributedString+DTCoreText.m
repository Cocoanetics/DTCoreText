//
//  NSAttributedString+DTCoreText.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 2/1/12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "NSAttributedString+DTCoreText.h"

#import "DTColor+HTML.h"
#import "NSString+HTML.h"
#import "DTTextAttachment.h"
#import "DTCoreTextParagraphStyle.h"
#import "DTCoreTextFontDescriptor.h"

#if TARGET_OS_IPHONE
#import "NSAttributedString+HTML.h"
#endif

@implementation NSAttributedString (DTCoreText)

#pragma mark Convenience Methods

+ (NSAttributedString *)attributedStringWithHTML:(NSData *)data options:(NSDictionary *)options
{
	NSAttributedString *attrString = [[NSAttributedString alloc] initWithHTML:data options:options documentAttributes:NULL];
	
	return attrString;
}

#pragma mark Utlities
- (NSArray *)textAttachmentsWithPredicate:(NSPredicate *)predicate
{
	NSMutableArray *tmpArray = [NSMutableArray array];
	
	NSUInteger index = 0;
	
	while (index<[self length]) 
	{
		NSRange range;
		NSDictionary *attributes = [self attributesAtIndex:index effectiveRange:&range];
		
		DTTextAttachment *attachment = [attributes objectForKey:NSAttachmentAttributeName];
		
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
			
			DTTextAttachment *attachment = [attributes objectForKey:NSAttachmentAttributeName];
			
			
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
				
				if (attachment.verticalAlignment != DTTextAttachmentVerticalAlignmentBaseline)
				{
					switch (attachment.verticalAlignment) 
					{
						case DTTextAttachmentVerticalAlignmentBaseline:
						{
							[styleString appendString:@"vertical-align:baseline;"];
							break;
						}
						case DTTextAttachmentVerticalAlignmentTop:
						{
							[styleString appendString:@"vertical-align:text-top;"];
							break;
						}	
						case DTTextAttachmentVerticalAlignmentCenter:
						{
							[styleString appendString:@"vertical-align:middle;"];
							break;
						}
						case DTTextAttachmentVerticalAlignmentBottom:
						{
							[styleString appendString:@"vertical-align:text-bottom;"];
							break;
						}
					}
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
				DTColor *color = [DTColor colorWithCGColor:textColor];
				
				fontStyle = [fontStyle stringByAppendingFormat:@"color:#%@;", [color htmlHexString]];
			}
			
			CGColorRef backgroundColor = (__bridge CGColorRef)[attributes objectForKey:@"DTBackgroundColor"];
			if (backgroundColor)
			{
				DTColor *color = [DTColor colorWithCGColor:backgroundColor];
				
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
					[retString appendFormat:@"<span style=\"%@\">%@</span>", fontStyle, subString];
				}
				else
				{
					[retString appendString:subString];
				}
			}
		}
		
		[retString appendFormat:@"</%@>\n", blockElement];
	}
	
	return retString;
}

- (NSString *)plainTextString
{
	NSString *tmpString = [self string];
	
	return [tmpString stringByReplacingOccurrencesOfString:UNICODE_OBJECT_PLACEHOLDER withString:@""];
}

@end
