//
//  NSAttributedString+DTCoreText.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 2/1/12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "NSAttributedString+DTCoreText.h"

#import "DTCoreTextConstants.h"

#import "DTColor+HTML.h"
#import "NSString+HTML.h"
#import "DTTextAttachment.h"
#import "DTCoreTextParagraphStyle.h"
#import "DTCoreTextFontDescriptor.h"
#import "DTCSSListStyle.h"

#if TARGET_OS_IPHONE
#import "NSAttributedString+HTML.h"
#endif

@implementation NSAttributedString (DTCoreText)

#pragma mark Text Attachments
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


#pragma mark Calculating Ranges

- (NSInteger)itemNumberInTextList:(DTCSSListStyle *)list atIndex:(NSUInteger)location
{
	NSRange effectiveRange;
	NSArray *textListsAtIndex = [self attribute:DTTextListsAttribute atIndex:location effectiveRange:&effectiveRange];
	
	if (!textListsAtIndex)
	{
		return 0;
	}
	
	// get outermost list
	DTCSSListStyle *outermostList = [textListsAtIndex objectAtIndex:0];
	
	// get the range of all lists
	NSRange totalRange = [self rangeOfTextList:outermostList atIndex:location];
	
	// get naked NSString
    NSString *string = [[self string] substringWithRange:totalRange];
	
    // entire string
    NSRange range = NSMakeRange(0, [string length]);
	
	NSMutableDictionary *countersPerList = [NSMutableDictionary dictionary];
	
	
    [string enumerateSubstringsInRange:range options:NSStringEnumerationByParagraphs usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop)
     {
		 NSRange actualRange = substringRange;
		 actualRange.location += totalRange.location;
		 
		 NSRange paragraphListRange;
		 NSArray *textLists = [self attribute:DTTextListsAttribute atIndex:substringRange.location + totalRange.location effectiveRange:&paragraphListRange];
		 
		 DTCSSListStyle *currentEffectiveList = [textLists lastObject];
		 
		 NSNumber *key = [NSNumber numberWithInteger:[currentEffectiveList hash]]; // hash defaults to address
		 NSNumber *currentCounterNum = [countersPerList objectForKey:key];
		 
		 NSInteger currentCounter=0;
		 
		 if (!currentCounterNum)
		 {
			 currentCounter = currentEffectiveList.startingItemNumber;
		 }
		 else
		 {
			 currentCounter = [currentCounterNum integerValue]+1;
		 }
		 
		 currentCounterNum = [NSNumber numberWithInteger:currentCounter];
		 [countersPerList setObject:currentCounterNum forKey:key];
		 
		 if (NSLocationInRange(location, actualRange))
		 {
			 *stop = YES;
		 }
     }
     ];
	
	NSNumber *key = [NSNumber numberWithInteger:[list hash]]; // hash defaults to address
	NSNumber *currentCounterNum = [countersPerList objectForKey:key];
	
	return [currentCounterNum integerValue];
}

- (NSRange)rangeOfTextList:(DTCSSListStyle *)list atIndex:(NSUInteger)location
{
	NSInteger searchIndex = location;
	
	NSArray *textListsAtIndex;
	NSInteger minFoundIndex = NSIntegerMax;
	NSInteger maxFoundIndex = 0;
	
	BOOL foundList = NO;
	
	do 
	{
		NSRange effectiveRange;
		textListsAtIndex = [self attribute:DTTextListsAttribute atIndex:searchIndex effectiveRange:&effectiveRange];
		
		if([textListsAtIndex containsObject:list])
		{
			foundList = YES;
			
			searchIndex = effectiveRange.location;
			
			minFoundIndex = MIN(minFoundIndex, searchIndex);
			maxFoundIndex = MAX(maxFoundIndex, NSMaxRange(effectiveRange));
		}
		
		if (!searchIndex || !foundList)
		{
			// reached beginning of string
			break;
		}
		
		searchIndex--;
	} 
	while (foundList && searchIndex>0);
	
	// if we didn't find the list at all, return 
	if (!foundList)
	{
		return NSMakeRange(0, NSNotFound);
	}
	
	// now search forward
	
	searchIndex = maxFoundIndex;
	
	while (searchIndex < [self length])
	{
		NSRange effectiveRange;
		textListsAtIndex = [self attribute:DTTextListsAttribute atIndex:searchIndex effectiveRange:&effectiveRange];
		
		foundList = [textListsAtIndex containsObject:list];
		
		if (!foundList)
		{
			break;
		}
		
		searchIndex = NSMaxRange(effectiveRange);
		
		minFoundIndex = MIN(minFoundIndex, effectiveRange.location);
		maxFoundIndex = MAX(maxFoundIndex, NSMaxRange(effectiveRange));
	}
	
	return NSMakeRange(minFoundIndex, maxFoundIndex-minFoundIndex);
}

#pragma mark HTML Encoding


- (NSString *)_tagRepresentationForListStyle:(DTCSSListStyle *)listStyle closingTag:(BOOL)closingTag
{
	BOOL isOrdered = NO;
	
	NSString *typeString = nil;
	
	switch (listStyle.type) 
	{
		case DTCSSListStyleTypeInherit:
		case DTCSSListStyleTypeDisc:
		{
			typeString = @"disc";
			isOrdered = NO;
			break;
		}
			
		case DTCSSListStyleTypeCircle:
		{
			typeString = @"circle";
			isOrdered = NO;
			break;
		}
			
		case DTCSSListStyleTypePlus:
		{
			typeString = @"plus";
			isOrdered = NO;
			break;
		}
			
		case DTCSSListStyleTypeUnderscore:
		{
			typeString = @"underscore";
			isOrdered = NO;
			break;
		}
			
		case DTCSSListStyleTypeImage: 
		{
			typeString = @"image";
			isOrdered = NO;
			break;
		}
			
		case DTCSSListStyleTypeDecimal:
		{
			typeString = @"decimal";
			isOrdered = YES;
			break;
		}
			
		case DTCSSListStyleTypeDecimalLeadingZero:
		{
			typeString = @"decimal-leading-zero";
			isOrdered = YES;
			break;
		}
			
		case DTCSSListStyleTypeUpperAlpha:
		{
			typeString = @"upper-alpha";
			isOrdered = YES;
			break;
		}
			
		case DTCSSListStyleTypeUpperLatin:
		{
			typeString = @"upper-latin";
			isOrdered = YES;
			break;
		}
			
		case DTCSSListStyleTypeLowerAlpha:
		{
			typeString = @"lower-alpha";
			isOrdered = YES;
			break;
		}
			
		case DTCSSListStyleTypeLowerLatin:
		{
			typeString = @"lower-latin";
			isOrdered = YES;
			break;
		}
			
		default:
			break;
	}
	
	if (closingTag)
	{
		if (isOrdered)
		{
			return @"</ol>";
		}
		else
		{
			return @"</ul>";
		}
	}
	else
	{
		if (listStyle.position == DTCSSListStylePositionInside)
		{
			typeString = [typeString stringByAppendingString:@" inside"];
		}
		else if (listStyle.position == DTCSSListStylePositionOutside)
		{
			typeString = [typeString stringByAppendingString:@" outside"];
		}
		
		if (isOrdered)
		{
			return [NSString stringWithFormat:@"<ol style=\"list-style='%@';\">", typeString];
		}
		else
		{
			return [NSString stringWithFormat:@"<ul style=\"list-style='%@';\">", typeString];
		}
	}
}

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
	
	NSArray *previousListStyles = nil;
	
	for (NSString *oneParagraph in paragraphs)
	{
		NSRange paragraphRange = NSMakeRange(location, [oneParagraph length]);
		
		BOOL needsToRemovePrefix = NO;
		
		// skip empty paragraph at end
		if (oneParagraph == [paragraphs lastObject] && !paragraphRange.length)
		{
			continue;
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
		
		// lets see if we have a list style
		NSArray *currentListStyles = [paraAttributes objectForKey:DTTextListsAttribute];
		
		DTCSSListStyle *effectiveListStyle = [currentListStyles lastObject];
		
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
		
		// close until we are at current or nil
		if ([previousListStyles count]>[currentListStyles count])
		{
			NSMutableArray *closingStyles = [previousListStyles mutableCopy];
			
			do 
			{
				DTCSSListStyle *closingStyle = [closingStyles lastObject];
				
				if (closingStyle == effectiveListStyle)
				{
					break;
				}
				
				// end of a list block
				[retString appendString:[self _tagRepresentationForListStyle:closingStyle closingTag:YES]];
				[retString appendString:@"\n"];
				
				[closingStyles removeLastObject];
				
				previousListStyles = closingStyles;
			}
			while ([closingStyles count]);
		}
		
		if (effectiveListStyle)
		{
			// next text needs to have list prefix removed
			needsToRemovePrefix = YES;
			
			if (![previousListStyles containsObject:effectiveListStyle])
			{
				// beginning of a list block
				[retString appendString:[self _tagRepresentationForListStyle:effectiveListStyle closingTag:NO]];
				[retString appendString:@"\n"];
			}
			
			blockElement = @"li";
		}
		else
		{
			blockElement = @"p";
		}
		
		NSNumber *headerLevel = [paraAttributes objectForKey:DTHeaderLevelAttribute];
		
		if (headerLevel)
		{
			blockElement = [NSString stringWithFormat:@"h%d", [headerLevel integerValue]];
		}
		
		if ([paragraphs lastObject] == oneParagraph)
		{
			// last paragraph in string
			
			if (![plainString hasSuffix:@"\n"])
			{
				// not a whole paragraph, so we don't put it in P
				blockElement = @"span";
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
			
			NSString *plainSubString =[plainString substringWithRange:effectiveRange];
			
			if (effectiveListStyle && needsToRemovePrefix)
			{
				NSInteger counter = [self itemNumberInTextList:effectiveListStyle atIndex:index];
				NSString *prefix = [effectiveListStyle prefixWithCounter:counter];
				
				if ([plainSubString hasPrefix:prefix])
				{
					plainSubString = [plainSubString substringFromIndex:[prefix length]];
				}
				
				needsToRemovePrefix = NO;
			}
			
			index += effectiveRange.length;
			
			NSString *subString = [plainSubString stringByAddingHTMLEntities];
			
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
			
			CGColorRef backgroundColor = (__bridge CGColorRef)[attributes objectForKey:DTBackgroundColorAttribute];
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
				NSNumber *strikout = [attributes objectForKey:DTStrikeOutAttribute];
				if ([strikout boolValue])
				{
					fontStyle = [fontStyle stringByAppendingString:@"text-decoration:line-through;"];
				}
			}
			
			
			NSURL *url = [attributes objectForKey:DTLinkAttribute];
			
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
		
		
		// end of paragraph loop
		previousListStyles = [currentListStyles copy];
	}
	
	// close list if still open
	if ([previousListStyles count])
	{
		NSMutableArray *closingStyles = [previousListStyles mutableCopy];
		
		do 
		{
			DTCSSListStyle *closingStyle = [closingStyles lastObject];
			
			// end of a list block
			[retString appendString:[self _tagRepresentationForListStyle:closingStyle closingTag:YES]];
			[retString appendString:@"\n"];
			
			[closingStyles removeLastObject];
		}
		while ([closingStyles count]);
	}
	
	return retString;
}

- (NSString *)plainTextString
{
	NSString *tmpString = [self string];
	
	return [tmpString stringByReplacingOccurrencesOfString:UNICODE_OBJECT_PLACEHOLDER withString:@""];
}

@end
