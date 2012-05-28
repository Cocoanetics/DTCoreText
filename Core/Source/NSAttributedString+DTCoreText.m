//
//  NSAttributedString+DTCoreText.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 2/1/12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTCoreText.h"
#import "NSAttributedString+DTCoreText.h"

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
	
	// enumerating through the paragraphs in the plain text string
    [string enumerateSubstringsInRange:range options:NSStringEnumerationByParagraphs usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop)
     {
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
		 
		 // calculate the actual range
		 NSRange actualRange = enclosingRange;  // includes a potential \n
		 actualRange.location += totalRange.location;

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


- (NSRange)_rangeOfObject:(id)object inArrayBehindAttribute:(NSString *)attribute atIndex:(NSUInteger)location
{
	NSInteger searchIndex = location;
	
	NSArray *arrayAtIndex;
	NSInteger minFoundIndex = NSIntegerMax;
	NSInteger maxFoundIndex = 0;
	
	BOOL foundList = NO;
	
	do 
	{
		NSRange effectiveRange;
		arrayAtIndex = [self attribute:attribute atIndex:searchIndex effectiveRange:&effectiveRange];
		
		if([arrayAtIndex containsObject:object])
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
		arrayAtIndex = [self attribute:attribute atIndex:searchIndex effectiveRange:&effectiveRange];
		
		foundList = [arrayAtIndex containsObject:object];
		
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

- (NSRange)rangeOfTextList:(DTCSSListStyle *)list atIndex:(NSUInteger)location
{
	return [self _rangeOfObject:list inArrayBehindAttribute:DTTextListsAttribute atIndex:location];
}

- (NSRange)rangeOfTextBlock:(DTTextBlock *)textBlock atIndex:(NSUInteger)location
{
	return [self _rangeOfObject:textBlock inArrayBehindAttribute:DTTextBlocksAttribute atIndex:location];
}

- (NSRange)rangeOfAnchorNamed:(NSString *)anchorName
{
	__block NSRange foundRange = NSMakeRange(0, NSNotFound);
	
	[self enumerateAttribute:DTAnchorAttribute inRange:NSMakeRange(0, [self length]) options:0 usingBlock:^(NSString *value, NSRange range, BOOL *stop) {
		if ([value isEqualToString:anchorName])
		{
			*stop = YES;
			foundRange = range;
		}
	}];
	
	return foundRange;
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

	for (int i=0; i<[paragraphs count]; i++)
	{
		NSString *oneParagraph = [paragraphs objectAtIndex:i];
		NSRange paragraphRange = NSMakeRange(location, [oneParagraph length]);
		
		// skip empty paragraph at the end
		if (i==[paragraphs count]-1)
		{
			if (!paragraphRange.length)
			{
				continue;
			}
		}
		
		BOOL needsToRemovePrefix = NO;
		
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

#pragma Generating Special Attributed Strings
+ (NSAttributedString *)prefixForListItemWithCounter:(NSUInteger)listCounter listStyle:(DTCSSListStyle *)listStyle listIndent:(CGFloat)listIndent attributes:(NSDictionary *)attributes
{
	// get existing values from attributes
	CTParagraphStyleRef paraStyle = (__bridge CTParagraphStyleRef)[attributes objectForKey:(id)kCTParagraphStyleAttributeName];
	CTFontRef font = (__bridge CTFontRef)[attributes objectForKey:(id)kCTFontAttributeName];
	CGColorRef textColor = (__bridge CGColorRef)[attributes objectForKey:(id)kCTForegroundColorAttributeName];
	
	DTCoreTextFontDescriptor *fontDescriptor = nil;
	DTCoreTextParagraphStyle *paragraphStyle = nil;
	
	if (paraStyle)
	{
		paragraphStyle = [DTCoreTextParagraphStyle paragraphStyleWithCTParagraphStyle:paraStyle];
		
		paragraphStyle.tabStops = nil;
		
		paragraphStyle.headIndent = listIndent;
		paragraphStyle.paragraphSpacing = 0;
		
		if (listStyle.type != DTCSSListStyleTypeNone)
		{
			// first tab is to right-align bullet, numbering against
			CGFloat tabOffset = paragraphStyle.headIndent - 5.0f*1.0; // TODO: change with font size
			[paragraphStyle addTabStopAtPosition:tabOffset alignment:kCTRightTextAlignment];
		}
		
		// second tab is for the beginning of first line after bullet
		[paragraphStyle addTabStopAtPosition:paragraphStyle.headIndent alignment:	kCTLeftTextAlignment];	
	}
	
	if (font)
	{
		fontDescriptor = [DTCoreTextFontDescriptor fontDescriptorForCTFont:font];
	}
	
	NSMutableDictionary *newAttributes = [NSMutableDictionary dictionary];
	
	if (fontDescriptor)
	{
		// make a font without italic or bold
		DTCoreTextFontDescriptor *fontDesc = [fontDescriptor copy];
		
		fontDesc.boldTrait = NO;
		fontDesc.italicTrait = NO;
		
		CTFontRef font = [fontDesc newMatchingFont];
		
		[newAttributes setObject:CFBridgingRelease(font) forKey:(id)kCTFontAttributeName];
	}
	
	// text color for bullet same as text
	if (textColor)
	{
		[newAttributes setObject:(__bridge id)textColor forKey:(id)kCTForegroundColorAttributeName];
	}
	
	// add paragraph style (this has the tabs)
	if (paragraphStyle)
	{
		CTParagraphStyleRef newParagraphStyle = [paragraphStyle createCTParagraphStyle];
		[newAttributes setObject:CFBridgingRelease(newParagraphStyle) forKey:(id)kCTParagraphStyleAttributeName];
	}
	
	if (listStyle)
	{
		[newAttributes setObject:[NSArray arrayWithObject:listStyle] forKey:DTTextListsAttribute];
	}
	
	// add a marker so that we know that this is a field/prefix
	[newAttributes setObject:@"{listprefix}" forKey:DTFieldAttribute];
	
	NSString *prefix = [listStyle prefixWithCounter:listCounter];
	
	if (prefix)
	{
		DTImage *image = nil;
		
		if (listStyle.imageName)
		{
			image = [DTImage imageNamed:listStyle.imageName];
			
			if (!image)
			{
				// image invalid
				listStyle.imageName = nil;
				
				prefix = [listStyle prefixWithCounter:listCounter];
			}
		}
		
		NSMutableAttributedString *tmpStr = [[NSMutableAttributedString alloc] initWithString:prefix attributes:newAttributes];
		
		
		if (image)
		{
			// make an attachment for the image
			DTTextAttachment *attachment = [[DTTextAttachment alloc] init];
			attachment.contents = image;
			attachment.contentType = DTTextAttachmentTypeImage;
			attachment.displaySize = image.size;
			
#if TARGET_OS_IPHONE
			// need run delegate for sizing
			CTRunDelegateRef embeddedObjectRunDelegate = createEmbeddedObjectRunDelegate(attachment);
			[newAttributes setObject:CFBridgingRelease(embeddedObjectRunDelegate) forKey:(id)kCTRunDelegateAttributeName];
#endif
			
			// add attachment
			[newAttributes setObject:attachment forKey:NSAttachmentAttributeName];				
			
			if (listStyle.position == DTCSSListStylePositionInside)
			{
				[tmpStr setAttributes:newAttributes range:NSMakeRange(2, 1)];
			}
			else
			{
				[tmpStr setAttributes:newAttributes range:NSMakeRange(1, 1)];
			}
		}
		
		return tmpStr;
	}
	
	return nil;
}

@end
