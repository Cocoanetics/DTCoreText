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
#import "NSDictionary+DTCoreText.h"

@implementation DTHTMLWriter
{
	NSAttributedString *_attributedString;
	NSString *_HTMLString;
	
	CGFloat _textScale;
	BOOL _useAppleConvertedSpace;
	BOOL _iOS6TagsPossible;
	
	NSMutableDictionary *_styleLookup;
}

- (id)initWithAttributedString:(NSAttributedString *)attributedString
{
	self = [super init];
	
	if (self)
	{
		_attributedString = attributedString;

		_useAppleConvertedSpace = YES;

		// default is to leave px sizes as is
		_textScale = 1.0f;
		
#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES
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

- (NSMutableArray *)_styleArrayForElement:(NSString *)elementName
{
	// get array of styles for element
	NSMutableArray *_styleArray = [_styleLookup objectForKey:elementName];
	
	if (!_styleArray)
	{
		// first time we see this element
		_styleArray = [[NSMutableArray alloc] init];
		[_styleLookup setObject:_styleArray forKey:elementName];
	}
	
	return _styleArray;
}

// checks the style against previous styles and returns the style class for this
- (NSString *)_styleClassForElement:(NSString *)elementName style:(NSString *)style
{
	// get array of styles for element
	NSMutableArray *_styleArray = [self _styleArrayForElement:elementName];
	
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

- (NSString *)_tagRepresentationForListStyle:(DTCSSListStyle *)listStyle closingTag:(BOOL)closingTag inlineStyles:(BOOL)inlineStyles
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
			
		case DTCSSListStyleTypeSquare:
		{
			typeString = @"square";
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
			
		case DTCSSListStyleTypeNone:
		{
			typeString = @"none";
			
			break;
		}
			
		case DTCSSListStyleTypeInvalid:
		{
			break;
		}
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
		
		NSString *listElementString = nil;
		if (inlineStyles)
		{
			listElementString = [NSString stringWithFormat:@"<%@ style=\"%@\">", blockElement, listStyleString];
		}
		else
		{
			listElementString = [NSString stringWithFormat:@"<%@ class=\"%@\">", blockElement, className];
		}
		return [NSString stringWithFormat:@"<%@ class=\"%@\">", blockElement, className];
	}
}

- (void)_buildOutput
{
	[self _buildOutputAsHTMLFragment:NO];
}

- (void)_buildOutputAsHTMLFragment:(BOOL)fragment
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
		
		// retrieve the paragraph style
		DTCoreTextParagraphStyle *paragraphStyle = [paraAttributes paragraphStyle];
		NSString *paraStyleString = nil;
		
		if (paragraphStyle)
		{
			if (_textScale!=1.0f)
			{
				paragraphStyle.minimumLineHeight = roundf(paragraphStyle.minimumLineHeight / _textScale);
				paragraphStyle.maximumLineHeight = roundf(paragraphStyle.maximumLineHeight / _textScale);
				
				paragraphStyle.paragraphSpacing = roundf(paragraphStyle.paragraphSpacing/ _textScale);
				paragraphStyle.paragraphSpacingBefore = roundf(paragraphStyle.paragraphSpacingBefore / _textScale);
				
				paragraphStyle.firstLineHeadIndent = roundf(paragraphStyle.firstLineHeadIndent / _textScale);
				paragraphStyle.headIndent = roundf(paragraphStyle.headIndent / _textScale);
				paragraphStyle.tailIndent = roundf(paragraphStyle.tailIndent / _textScale);
			}
			
			paraStyleString = [paragraphStyle cssStyleRepresentation];
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
				[retString appendString:[self _tagRepresentationForListStyle:closingStyle closingTag:YES inlineStyles:fragment]];
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
				[retString appendString:[self _tagRepresentationForListStyle:effectiveListStyle closingTag:NO inlineStyles:fragment]];
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
		
		// Add dir="auto" if the writing direction is unknown
		NSString *directionAttributeString = @"";
		
		if (paragraphStyle)
		{
			switch (paragraphStyle.baseWritingDirection)
			{
				case kCTWritingDirectionNatural:
				{
					directionAttributeString = @" dir=\"auto\"";
					break;
				}
					
				case kCTWritingDirectionRightToLeft:
				{
					directionAttributeString = @" dir=\"rtl\"";
					break;
				}
					
				case kCTWritingDirectionLeftToRight:
				{
					// this is default, so we omit it
					break;
				}
			}
		}
		
		if ([paraStyleString length])
		{
			NSString *className = [self _styleClassForElement:blockElement style:paraStyleString];
			
			if (fragment) {
				[retString appendFormat:@"<%@ style=\"%@\"%@>", blockElement, paraStyleString, directionAttributeString];
			} else {
				[retString appendFormat:@"<%@ class=\"%@\"%@>", blockElement, className, directionAttributeString];
			}
		}
		else
		{
			[retString appendFormat:@"<%@%@>", blockElement, directionAttributeString];
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
				NSRange prefixRange = [_attributedString rangeOfFieldAtIndex:effectiveRange.location];
				
				if (prefixRange.location != NSNotFound)
				{
					if (NSMaxRange(prefixRange)<plainSubString.length)
					{
						plainSubString = [plainSubString substringFromIndex:NSMaxRange(prefixRange) - effectiveRange.location];
					}
					else
					{
						plainSubString = @"";
					}
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
				if ([attachment conformsToProtocol:@protocol(DTTextAttachmentHTMLPersistence)])
				{
					id<DTTextAttachmentHTMLPersistence> persistableAttachment = (id<DTTextAttachmentHTMLPersistence>)attachment;
					
					NSString *HTMLString = [persistableAttachment stringByEncodingAsHTML];
					
					if (HTMLString)
					{
						[retString appendString:HTMLString];
					}
				}
				
				continue;
			}
			
			NSString *fontStyle = nil;
			if (!fontIsBlockLevel)
			{
				DTCoreTextFontDescriptor *fontDescriptor = [attributes fontDescriptor];
				
				if (fontDescriptor)
				{
					if (_textScale!=1.0f)
					{
						fontDescriptor.pointSize /= _textScale;
					}
					
					fontStyle = [fontDescriptor cssStyleRepresentation];
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
					
					if (fragment) {
						[retString appendFormat:@"<a style=\"%@\" href=\"%@\">%@</a>", fontStyle, [url relativeString], subString];
					} else {
						[retString appendFormat:@"<a class=\"%@\" href=\"%@\">%@</a>", className, [url relativeString], subString];
					}
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
					
					if (fragment)
					{
						[retString appendFormat:@"<span style=\"%@\">%@</span>", fontStyle, subString];
					}
					else
					{
						[retString appendFormat:@"<span class=\"%@\">%@</span>", className, subString];
					}
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
			[retString appendString:[self _tagRepresentationForListStyle:closingStyle closingTag:YES inlineStyles:fragment]];
			[retString appendString:@"\n"];
			
			[closingStyles removeLastObject];
		}
		while ([closingStyles count]);
	}
		
	NSMutableString *output = [NSMutableString string];
	
	BOOL hasTab = ([retString rangeOfString:@"\t"].location != NSNotFound);
	
	if (!fragment)
	{
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
		
		if (hasTab)
		{
			[styleBlock appendString:@"span.Apple-tab-span {white-space:pre;}"];
		}
		
		[output appendFormat:@"<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html40/strict.dtd\">\n<html>\n<head>\n<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />\n<meta http-equiv=\"Content-Style-Type\" content=\"text/css\" />\n<meta name=\"Generator\" content=\"DTCoreText HTML Writer\" />\n<style type=\"text/css\">\n%@</style>\n</head>\n<body>\n", styleBlock];
	}


	if (hasTab)
	{
		NSRange range = NSMakeRange(0, [retString length]);
		
		if (fragment)
		{
			[retString replaceOccurrencesOfString:@"\t" withString:@"<span style=\"white-space:pre;\">\t</span>" options:0 range:range];
		}
		else
		{
			[retString replaceOccurrencesOfString:@"\t" withString:@"<span class=\"Apple-tab-span\">\t</span>" options:0 range:range];
		}
	}
	
	if (_useAppleConvertedSpace)
	{
		NSString *convertedSpaces = [retString stringByAddingAppleConvertedSpace];
		
		[output appendString:convertedSpaces];
	}
	else
	{
		[output appendString:retString];
	}

	if (!fragment)
	{
		[output appendString:@"</body>\n</html>\n"];
	}
	
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

- (NSString *)HTMLFragment
{
	if (!_HTMLString)
	{
		[self _buildOutputAsHTMLFragment:true];
	}
	
	return _HTMLString;
}

#pragma mark - Properties

@synthesize attributedString = _attributedString;
@synthesize textScale = _textScale;

@end
