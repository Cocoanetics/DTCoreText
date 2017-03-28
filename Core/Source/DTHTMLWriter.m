//
//  DTHTMLWriter.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 23.12.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTHTMLWriter.h"
#import "DTVersion.h"
#import "NSDictionary+DTCoreText.h"
#import "DTCSSListStyle.h"
#import "DTCoreTextConstants.h"
#import "DTCoreTextFontDescriptor.h"
#import "DTCoreTextParagraphStyle.h"
#import "NSAttributedString+DTCoreText.h"
#import "NSAttributedString+HTML.h"
#import "DTTextAttachment.h"
#import "NSString+HTML.h"
#import "DTColorFunctions.h"



@implementation DTHTMLWriter
{
	NSAttributedString *_attributedString;
	NSString *_HTMLString;
	CGFloat _textScale;
	BOOL _useAppleConvertedSpace;
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
		
		_paragraphTagName = @"p";
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

- (NSString *)_tagRepresentationForListStyle:(DTCSSListStyle *)listStyle closingTag:(BOOL)closingTag listPadding:(CGFloat)listPadding inlineStyles:(BOOL)inlineStyles
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
			
		case DTCSSListStyleTypeUpperRoman:
		{
			typeString = @"upper-roman";
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
			
		case DTCSSListStyleTypeLowerRoman:
		{
			typeString = @"lower-roman";
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
		
		NSString *listStyleString = [NSString stringWithFormat:@"list-style:'%@';", typeString];
		
		if (listPadding>0)
		{
			listStyleString = [listStyleString stringByAppendingFormat:@"-webkit-padding-start:%.0fpx;padding-left:%.0fpx;", listPadding, listPadding];
		}
		
		NSString *className = [self _styleClassForElement:blockElement style:listStyleString];
		
		if (inlineStyles)
		{
			return [NSString stringWithFormat:@"<%@ style=\"%@\">", blockElement, listStyleString];
		}
		else
		{
			return [NSString stringWithFormat:@"<%@ class=\"%@\">", blockElement, className];
		}
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
		
		__block BOOL needsToRemovePrefix = NO;
		
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
		
		if (paragraphStyle && !effectiveListStyle)
		{
			if (_textScale!=1.0f)
			{
				paragraphStyle.minimumLineHeight = round(paragraphStyle.minimumLineHeight / _textScale);
				paragraphStyle.maximumLineHeight = round(paragraphStyle.maximumLineHeight / _textScale);
				
				paragraphStyle.paragraphSpacing = round(paragraphStyle.paragraphSpacing/ _textScale);
				paragraphStyle.paragraphSpacingBefore = round(paragraphStyle.paragraphSpacingBefore / _textScale);
				
				paragraphStyle.firstLineHeadIndent = round(paragraphStyle.firstLineHeadIndent / _textScale);
				paragraphStyle.headIndent = round(paragraphStyle.headIndent / _textScale);
				paragraphStyle.tailIndent = round(paragraphStyle.tailIndent / _textScale);
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
				[retString appendString:[self _tagRepresentationForListStyle:closingStyle closingTag:YES listPadding:0 inlineStyles:fragment]];
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
			
			
			// get lists that need to be opened here
			NSArray *listsToOpen = nil;
			
			if (!previousListStyles)
			{
				listsToOpen = currentListStyles;
			}
			else
			{
				NSMutableArray *tmpArray = [NSMutableArray array];
				
				for (DTCSSListStyle *oneList in currentListStyles)
				{
					NSRange listRange = [_attributedString rangeOfTextList:oneList atIndex:paragraphRange.location];
					
					if (listRange.location == paragraphRange.location)
					{
						// lists starts here
						[tmpArray addObject:oneList];
					}
				}

				if ([tmpArray count])
				{
					listsToOpen = [tmpArray copy];
				}
			}
			
			[listsToOpen enumerateObjectsUsingBlock:^(DTCSSListStyle *oneList, NSUInteger idx, BOOL *stop) {
				
				// only padding can be reconstructed so far
				CGFloat listPadding = (paragraphStyle.headIndent - paragraphStyle.firstLineHeadIndent) / _textScale;
				
				// beginning of a list block
				[retString appendString:[self _tagRepresentationForListStyle:oneList closingTag:NO listPadding:listPadding inlineStyles:fragment]];
				[retString appendString:@"\n"];
				
				// all but the effective list need an extra LI
				if (oneList != effectiveListStyle)
				{
					[retString appendString:@"<li>"];
				}
			}];
			
			blockElement = @"li";
		}
		else
		{
			blockElement = _paragraphTagName;
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
		
		// find which custom attributes are for the entire paragraph
		NSDictionary *HTMLAttributes = [_attributedString HTMLAttributesAtIndex:paragraphRange.location];
		NSMutableDictionary *paragraphLevelHTMLAttributes = [NSMutableDictionary dictionary];
		
		[HTMLAttributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
			
			// check if range is longer than current paragraph
			NSRange attributeEffectiveRange = [_attributedString rangeOfHTMLAttribute:key atIndex:paragraphRange.location];
			
			if (NSIntersectionRange(attributeEffectiveRange, paragraphRange).length == paragraphRange.length)
			{
				[paragraphLevelHTMLAttributes setObject:value forKey:key];
			}
		}];
		
		// Add dir="auto" if the writing direction is unknown
		if (paragraphStyle)
		{
			switch (paragraphStyle.baseWritingDirection)
			{
				case kCTWritingDirectionNatural:
				{
					[paragraphLevelHTMLAttributes setObject:@"auto" forKey:@"dir"];
					break;
				}
					
				case kCTWritingDirectionRightToLeft:
				{
					[paragraphLevelHTMLAttributes setObject:@"rtl" forKey:@"dir"];
					break;
				}
					
				case kCTWritingDirectionLeftToRight:
				{
					// this is default, so we omit it
					break;
				}
			}
		}
		

		// start paragraph start tag
		[retString appendFormat:@"<%@", blockElement];
		
		// do we have style info?
		if ([paraStyleString length])
		{
			if (fragment)
			{
				// stays style for fragment mode
				[paragraphLevelHTMLAttributes setObject:paraStyleString forKey:@"style"];
			}
			else
			{
				// compress style for document mode
				NSString *className = [self _styleClassForElement:blockElement style:paraStyleString];
				
				NSString *existingClasses = [paragraphLevelHTMLAttributes objectForKey:@"class"];
				
				if (existingClasses)
				{
					NSMutableArray *individualClasses = [[existingClasses componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] mutableCopy];
					
					// insert compressed class at index 0
					[individualClasses insertObject:className atIndex:0];
					
					// rejoin
					className = [individualClasses componentsJoinedByString:@" "];
				}
				
				[paragraphLevelHTMLAttributes setObject:className forKey:@"class"];
			}
		}
		
		// add paragraph level attributes
		[paragraphLevelHTMLAttributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
			[retString appendFormat:@" %@=\"%@\"", key, value];
		}];
		
		// end paragraph start tag
		[retString appendString:@">"];
		
		// add the attributed string ranges in this paragraph to the paragraph container
		
		__block NSRange currentLinkRange = {NSNotFound, 0};
		
		__block NSMutableDictionary *linkLevelHTMLAttributes = nil;
		
		// ----- SPAN enumeration
		
		[_attributedString enumerateAttributesInRange:paragraphRange options:0 usingBlock:^(NSDictionary *attributes, NSRange spanRange, BOOL *stopEnumerateAttributes) {

			NSURL *spanURL = [attributes objectForKey:DTLinkAttribute];
			NSString *spanAnchorName = [attributes objectForKey:DTAnchorAttribute];
			
			BOOL isFirstPartOfHyperlink = NO;
			BOOL isLastPartOfHyperlink = NO;
			
			if ((spanURL || spanAnchorName) && (currentLinkRange.location == NSNotFound))
			{
				if (spanURL)
				{
					currentLinkRange = [_attributedString rangeOfLinkAtIndex:spanRange.location URL:NULL];
				}
				else if (spanAnchorName)
				{
					currentLinkRange = [_attributedString rangeOfAnchorNamed:spanAnchorName];
				}
				
				isFirstPartOfHyperlink = YES;
				
				// build the attributes for the A tag
				linkLevelHTMLAttributes = [NSMutableDictionary dictionary];
				
				if (spanURL)
				{
					[linkLevelHTMLAttributes setObject:[spanURL relativeString] forKey:@"href"];
				}
				
				// add anchor name if present
				if (spanAnchorName)
				{
					[linkLevelHTMLAttributes setObject:spanAnchorName forKey:@"name"];
				}
				
				// find which custom attributes are for the link
				NSDictionary *localHTMLAttributes = [_attributedString HTMLAttributesAtIndex:currentLinkRange.location];
				
				[localHTMLAttributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stopEnumerateKeysAndObjects) {
					
					// check if range is longer than current paragraph
					NSRange attributeEffectiveRange = [_attributedString rangeOfHTMLAttribute:key atIndex:currentLinkRange.location];
					
					if (NSEqualRanges(attributeEffectiveRange, currentLinkRange))
					{
						[linkLevelHTMLAttributes setObject:value forKey:key];
					}
				}];
			}
			
			// check if the current link tag needs to be closed
			if (currentLinkRange.location != NSNotFound && (NSMaxRange(spanRange) >= MIN(NSMaxRange(currentLinkRange), NSMaxRange(paragraphRange))))
			{
				isLastPartOfHyperlink = YES;
			}
			
			NSString *plainSubString =[plainString substringWithRange:spanRange];
			
			if (effectiveListStyle && needsToRemovePrefix)
			{
				NSRange prefixRange = [_attributedString rangeOfFieldAtIndex:spanRange.location];
				
				if (prefixRange.location != NSNotFound)
				{
					if (NSMaxRange(prefixRange)<plainSubString.length)
					{
						plainSubString = [plainSubString substringFromIndex:NSMaxRange(prefixRange) - spanRange.location];
					}
					else
					{
						// avoid output of empty span tag, issue #601
						return;
					}
				}
				
				needsToRemovePrefix = NO;
			}
			
			NSString *subString = [plainSubString stringByAddingHTMLEntities];
			
			if (!subString)
			{
				if (isLastPartOfHyperlink)
				{
					currentLinkRange = NSMakeRange(NSNotFound, 0);
				}
				
				return;
			}
			
			DTTextAttachment *attachment = [attributes objectForKey:NSAttachmentAttributeName];

			if ([plainSubString isEqualToString:UNICODE_OBJECT_PLACEHOLDER]) {
				
				// if there was no old-style attachment let's try new NS-style.
				if (!attachment)
				{
					attachment = [attributes objectForKey:@"NSAttachment"];
				}
				
				// we don't want to output the placeholder character in any case
				subString = @"";
			}
			
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
				
				if (isLastPartOfHyperlink)
				{
					currentLinkRange = NSMakeRange(NSNotFound, 0);
				}

				return;
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
			
			CGFloat kerning = [attributes kerning] / _textScale;
			
			if (kerning != 0)
			{
				fontStyle = [fontStyle stringByAppendingFormat:@"letter-spacing:%.0fpx;", kerning];
			}
			
			DTColor *textColor = [attributes foregroundColor];
			
			if (textColor)
			{
				fontStyle = [fontStyle stringByAppendingFormat:@"color:#%@;",  DTHexStringFromDTColor(textColor)];
			}
			
			DTColor *backgroundColor = [attributes backgroundColor];
			
			if (backgroundColor)
			{
				fontStyle = [fontStyle stringByAppendingFormat:@"background-color:#%@;", DTHexStringFromDTColor(backgroundColor)];
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
			
			NSString *spanTagName = @"span";
			
			__block BOOL needsSpanTag = NO;
			
			// find which custom attributes are only for this span
			NSDictionary *localHTMLAttributes = [attributes objectForKey:DTCustomAttributesAttribute];
			NSMutableDictionary *spanLevelHTMLAttributes = [NSMutableDictionary dictionary];
			
			[localHTMLAttributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
				
				// check if there is already an identical paragraph attribute
				id valueForParagraph = [paragraphLevelHTMLAttributes objectForKey:key];

				if (valueForParagraph)
				{
					if (fragment)
					{
						if ([valueForParagraph isEqual:value])
						{
							return;
						}
					}
					else
					{
						// need to check components
						NSArray *paragraphClassComponents = [valueForParagraph componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
						
						if ([paragraphClassComponents containsObject:value])
						{
							return;
						}
					}
				}
				
				NSRange attributeEffectiveRange = [_attributedString rangeOfHTMLAttribute:key atIndex:spanRange.location];
				
				if (currentLinkRange.location==NSNotFound || !NSEqualRanges(attributeEffectiveRange, currentLinkRange))
				{
					[spanLevelHTMLAttributes setObject:value forKey:key];
					needsSpanTag = YES;
				}
			}];

			if ([fontStyle length])
			{
				needsSpanTag = YES;
				
				if (fragment)
				{
					// stays style for fragment mode
					[spanLevelHTMLAttributes setObject:fontStyle forKey:@"style"];
				}
				else
				{
					// compress style for document mode
					NSString *className = [self _styleClassForElement:spanTagName style:fontStyle];
					
					NSString *existingClasses = [spanLevelHTMLAttributes objectForKey:@"class"];
					
					if (existingClasses)
					{
						NSMutableArray *individualClasses = [[existingClasses componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] mutableCopy];
						
						// insert compressed class at index 0
						[individualClasses insertObject:className atIndex:0];
						
						// rejoin
						className = [individualClasses componentsJoinedByString:@" "];
					}
					
					[spanLevelHTMLAttributes setObject:className forKey:@"class"];
				}
			}
			
			if (isFirstPartOfHyperlink)
			{
				// start link start tag
				[retString appendString:@"<a"];
				
				// add span level attributes
				[linkLevelHTMLAttributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
					[retString appendFormat:@" %@=\"%@\"", key, value];
				}];
				
				// end span start tag
				[retString appendString:@">"];
			}
			
			
			if (needsSpanTag)
			{
				// start span start tag
				[retString appendFormat:@"<%@", spanTagName];
				
				// add span level attributes
				[spanLevelHTMLAttributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
					[retString appendFormat:@" %@=\"%@\"", key, value];
				}];
				
				// end span start tag
				[retString appendString:@">"];
			}
			
			// add string in span
			[retString appendString:subString];
			
			if (needsSpanTag)
			{
				// span end tag
				[retString appendFormat:@"</%@>", spanTagName];
			}
			
			if (isLastPartOfHyperlink)
			{
				[retString appendFormat:@"</a>"];
				currentLinkRange = NSMakeRange(NSNotFound, 0);
			}
		}];  // end of SPAN loop

		
		if ([blockElement isEqualToString:@"li"])
		{
			BOOL shouldCloseLI = YES;

			NSUInteger nextParagraphStart = NSMaxRange([plainString paragraphRangeForRange:paragraphRange]);
			
			if (nextParagraphStart < [plainString length])
			{
				NSArray *nextListStyles = [_attributedString attribute:DTTextListsAttribute atIndex:nextParagraphStart effectiveRange:NULL];
				
				// LI are only closed if there is not a deeper list level following
				if (nextListStyles && ([nextListStyles indexOfObjectIdenticalTo:effectiveListStyle]!=NSNotFound) && [nextListStyles count] > [currentListStyles count])
				{
					// deeper list following
					shouldCloseLI = NO;
				}
			}
			
			if (shouldCloseLI)
			{
				[retString appendString:@"</li>"];
			}
		}
		else
		{
			// other blocks are always closed
			[retString appendFormat:@"</%@>\n", blockElement];
		}
		
		previousListStyles = [currentListStyles copy];
	}  // end of P loop

	
	// close list if still open
	if ([previousListStyles count])
	{
		NSMutableArray *closingStyles = [previousListStyles mutableCopy];
		
		do
		{
			DTCSSListStyle *closingStyle = [closingStyles lastObject];
			
			// end of a list block
			[retString appendString:[self _tagRepresentationForListStyle:closingStyle closingTag:YES listPadding:0 inlineStyles:fragment]];
			[retString appendString:@"\n"];
			
			if ([closingStyles count]>1)
			{
				[retString appendString:@"</li>"];
			}
			
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
@synthesize useAppleConvertedSpace = _useAppleConvertedSpace;

@end
