//
//  DTHTMLWriter.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 23.12.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTHTMLWriter.h"
#import "DTCoreText.h"
#import "DTVersion.h"

@implementation DTHTMLWriter
{
	NSAttributedString *_attributedString;
	NSString *_HTMLString;
	
	CGFloat _textScale;
	BOOL _iOS6TagsPossible;
	
	NSMutableDictionary *_styleLookup;
}

- (id)initWithAttributedString:(NSAttributedString *)attributedString
{
	self = [super init];
	
	if (self)
	{
		_attributedString = attributedString;
		
		// default is to leave px sizes as is
		_textScale = 1.0f;
		
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_5_1
		// if running on iOS6 or higher
		if ([DTVersion osVersionIsLessThen:@"6.0"])
		{
			_iOS6TagsPossible = NO;
		}
		else
		{
			_iOS6TagsPossible = YES;
		}
#endif
	}
	
	return self;
}

#pragma mark - Generating HTML

// checks the style against previous styles and returns the style class for this
- (NSString *)_styleClassForElement:(NSString *)elementName style:(NSString *)style
{
	// get array of styles for element
	NSMutableArray *_styleArray = [_styleLookup objectForKey:elementName];

	if (!_styleArray)
	{
		// first time we see this element
		_styleArray = [[NSMutableArray alloc] init];
		[_styleLookup setObject:_styleArray forKey:elementName];
	}
	
	NSInteger index = [_styleArray indexOfObject:style];
	
	if (index==NSNotFound)
	{
		// need to add this style
		[_styleArray addObject:style];
		index = [_styleArray count];
	}
	else
	{
		index++;
	}
	
	return [NSString stringWithFormat:@"%@%d", [elementName substringToIndex:1],(int)index];
}

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

		NSString *blockElement;
		if (isOrdered)
		{
			blockElement = @"ol";
		}
		else
		{
			blockElement = @"ul";
		}
		
		NSString *listStyleString = [NSString stringWithFormat:@"list-style='%@';\">", typeString];
		NSString *className = [self _styleClassForElement:blockElement style:listStyleString];
		
		return [NSString stringWithFormat:@"<%@ class=\"%@\">", blockElement, className];
	}
}


- (void)_buildOutput
{
	// reusable styles
	_styleLookup = [[NSMutableDictionary alloc] init];
	
	NSString *plainString = [_attributedString string];
	
	// divide the string into it's blocks (we assume that these are the P)
	NSArray *paragraphs = [plainString componentsSeparatedByString:@"\n"];
	
	NSMutableString *retString = [NSMutableString string];
	
	NSInteger location = 0;
	
	NSArray *previousListStyles = nil;
	
	for (NSUInteger i=0; i<[paragraphs count]; i++)
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
		
		// check if font is same in the entire paragraph
		NSRange fontEffectiveRange;
		CTFontRef paragraphFont = (__bridge CTFontRef)[_attributedString attribute:(id)kCTFontAttributeName atIndex:paragraphRange.location longestEffectiveRange:&fontEffectiveRange inRange:paragraphRange];
		
		if (NSEqualRanges(paragraphRange, fontEffectiveRange))
		{
			fontIsBlockLevel = YES;
		}
		
		// next paragraph start
		location = location + paragraphRange.length + 1;
		
		NSDictionary *paraAttributes = [_attributedString attributesAtIndex:paragraphRange.location effectiveRange:NULL];
		
		// lets see if we have a list style
		NSArray *currentListStyles = [paraAttributes objectForKey:DTTextListsAttribute];
		
		DTCSSListStyle *effectiveListStyle = [currentListStyles lastObject];
		
		CTParagraphStyleRef paraStyle = (__bridge CTParagraphStyleRef)[paraAttributes objectForKey:(id)kCTParagraphStyleAttributeName];
		NSString *paraStyleString = nil;
		
		if (paraStyle)
		{
			DTCoreTextParagraphStyle *para = [DTCoreTextParagraphStyle paragraphStyleWithCTParagraphStyle:paraStyle];
			
			if (_textScale!=1.0f)
			{
				para.minimumLineHeight = roundf(para.minimumLineHeight / _textScale);
				para.maximumLineHeight = roundf(para.maximumLineHeight / _textScale);
				
				para.paragraphSpacing = roundf(para.paragraphSpacing/ _textScale);
				para.paragraphSpacingBefore = roundf(para.paragraphSpacingBefore / _textScale);
				
				para.firstLineHeadIndent = roundf(para.firstLineHeadIndent / _textScale);
				para.headIndent = roundf(para.headIndent / _textScale);
				para.tailIndent = roundf(para.tailIndent / _textScale);
			}
			
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
				
				if (_textScale!=1.0f)
				{
					desc.pointSize /= _textScale;
				}
				
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
			blockElement = [NSString stringWithFormat:@"h%d", (int)[headerLevel integerValue]];
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
			NSString *className = [self _styleClassForElement:blockElement style:paraStyleString];
			[retString appendFormat:@"<%@ class=\"%@\">", blockElement, className];
		}
		else
		{
			[retString appendFormat:@"<%@>", blockElement];
		}
		
		// add the attributed string ranges in this paragraph to the paragraph container
		NSRange effectiveRange;
		NSUInteger index = paragraphRange.location;
		
		NSUInteger paragraphRangeEnd = NSMaxRange(paragraphRange);
		
		while (index < paragraphRangeEnd)
		{
			NSDictionary *attributes = [_attributedString attributesAtIndex:index longestEffectiveRange:&effectiveRange inRange:paragraphRange];
			
			NSString *plainSubString =[plainString substringWithRange:effectiveRange];
			
			if (effectiveListStyle && needsToRemovePrefix)
			{
				NSInteger counter = [_attributedString itemNumberInTextList:effectiveListStyle atIndex:index];
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
				
				NSString *blockName;
				
				switch (attachment.contentType)
				{
					case DTTextAttachmentTypeVideoURL:
					{
						blockName = @"video";
						break;
					}
						
					case DTTextAttachmentTypeImage:
					{
						blockName = @"img";
						break;
					}

					case DTTextAttachmentTypeObject:
					{
						blockName = @"object";
						break;
					}

					case DTTextAttachmentTypeIframe:
					{
						blockName = @"iframe";
						break;
					}

					default:
					{
						// we don't know how to output this
						continue;
					}
				}
				
				// output tag start
				[retString appendFormat:@"<%@", blockName];

				// build style for img/video
				NSMutableString *classStyleString = [NSMutableString string];
				
				if (attachment.verticalAlignment != DTTextAttachmentVerticalAlignmentBaseline)
				{
					switch (attachment.verticalAlignment)
					{
						case DTTextAttachmentVerticalAlignmentBaseline:
						{
							[classStyleString appendString:@"vertical-align:baseline;"];
							break;
						}
						case DTTextAttachmentVerticalAlignmentTop:
						{
							[classStyleString appendString:@"vertical-align:text-top;"];
							break;
						}
						case DTTextAttachmentVerticalAlignmentCenter:
						{
							[classStyleString appendString:@"vertical-align:middle;"];
							break;
						}
						case DTTextAttachmentVerticalAlignmentBottom:
						{
							[classStyleString appendString:@"vertical-align:text-bottom;"];
							break;
						}
					}
				}
				
				// only add class if there was some content
				if ([classStyleString length])
				{
					NSString *className = [self _styleClassForElement:blockName style:classStyleString];
					
					[retString appendFormat:@" class=\"%@\"", className];
				}
				
				// build a HTML 5 conformant size style if set
				NSMutableString *sizeStyleString = [NSMutableString string];
				
				if (attachment.originalSize.width>0)
				{
					[sizeStyleString appendFormat:@"width:%.0fpx;", attachment.originalSize.width];
				}
				
				if (attachment.originalSize.height>0)
				{
					[sizeStyleString appendFormat:@"height:%.0fpx;", attachment.originalSize.height];
				}
				
				// add local style for size, since sizes might vary quite a bit
				if ([sizeStyleString length])
				{
					[retString appendFormat:@" style=\"%@\"", sizeStyleString];
				}
				
				[retString appendFormat:@" src=\"%@\"", urlString];
				
				// attach the attributes dictionary
				NSMutableDictionary *tmpAttributes = [attachment.attributes mutableCopy];
				
				// remove src,style, width and height we already have these
				[tmpAttributes removeObjectForKey:@"src"];
				[tmpAttributes removeObjectForKey:@"style"];
				[tmpAttributes removeObjectForKey:@"width"];
				[tmpAttributes removeObjectForKey:@"height"];
				
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
					
					if (_textScale!=1.0f)
					{
						desc.pointSize /= _textScale;
					}
					
					fontStyle = [desc cssStyleRepresentation];
				}
			}
			
			if (!fontStyle)
			{
				fontStyle = @"";
			}
			
			CGColorRef textColor = (__bridge CGColorRef)[attributes objectForKey:(id)kCTForegroundColorAttributeName];
			
			if (!textColor && _iOS6TagsPossible)
			{
				// could also be the iOS 6 color
				DTColor *color = [attributes objectForKey:NSForegroundColorAttributeName];
				textColor = color.CGColor;
			}
			
			if (textColor)
			{
				DTColor *color = [DTColor colorWithCGColor:textColor];
				
				fontStyle = [fontStyle stringByAppendingFormat:@"color:#%@;", [color htmlHexString]];
			}
			
			CGColorRef backgroundColor = (__bridge CGColorRef)[attributes objectForKey:DTBackgroundColorAttribute];
			
			if (!backgroundColor && _iOS6TagsPossible)
			{
					// could also be the iOS 6 background color
					DTColor *color = [attributes objectForKey:NSBackgroundColorAttributeName];
					backgroundColor = color.CGColor;
			}
			
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
			
			NSNumber *superscript = [attributes objectForKey:(id)kCTSuperscriptAttributeName];
			if (superscript)
			{
				NSInteger style = [superscript integerValue];
				
				switch (style)
				{
					case 1:
					{
						fontStyle = [fontStyle stringByAppendingString:@"vertical-align:super;"];
						break;
					}
						
					case -1:
					{
						fontStyle = [fontStyle stringByAppendingString:@"vertical-align:sub;"];
						break;
					}
						
					default:
					{
						// all other are baseline because we don't support anything else for text
						fontStyle = [fontStyle stringByAppendingString:@"vertical-align:baseline;"];
						
						break;
					}
				}
			}
			
			NSURL *url = [attributes objectForKey:DTLinkAttribute];
			
			if (url)
			{
				if ([fontStyle length])
				{
					NSString *className = [self _styleClassForElement:@"a" style:fontStyle];
					[retString appendFormat:@"<a class=\"%@\" href=\"%@\">%@</a>", className, [url relativeString], subString];
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
					NSString *className = [self _styleClassForElement:@"span" style:fontStyle];
					[retString appendFormat:@"<span class=\"%@\">%@</span>", className, subString];
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
	
	// append style block before text
	NSMutableString *styleBlock = [NSMutableString string];
	
	NSArray *keys = [[_styleLookup allKeys] sortedArrayUsingSelector:@selector(compare:)];
	
	for (NSString *oneKey in keys)
	{
		NSArray *styleArray = [_styleLookup objectForKey:oneKey];
		
		[styleArray enumerateObjectsUsingBlock:^(NSString *style, NSUInteger idx, BOOL *stop) {
			NSString *className = [NSString stringWithFormat:@"%@%d", [oneKey substringToIndex:1], (int)idx+1];
			[styleBlock appendFormat:@"%@.%@ {%@}\n", oneKey, className, style];
		}];
	}
	
	NSMutableString *output = [NSMutableString string];
	
	[output appendFormat:@"<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html40/strict.dtd\">\n<html>\n<head>\n<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />\n<meta http-equiv=\"Content-Style-Type\" content=\"text/css\" />\n<meta name=\"Generator\" content=\"DTCoreText HTML Writer\" />\n<style type=\"text/css\">\n%@</style>\n</head>\n<body>\n", styleBlock];
	[output appendString:[retString stringByAddingAppleConvertedSpace]];
	[output appendString:@"</body>\n</html>\n"];
	
	_HTMLString = output;
}

#pragma mark - Public

- (NSString *)HTMLString
{
	if (!_HTMLString)
	{
		[self _buildOutput];
	}
	
	return _HTMLString;
}

#pragma mark - Properties

@synthesize attributedString = _attributedString;
@synthesize textScale = _textScale;

@end
