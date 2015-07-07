//
//  NSAttributedString+DTCoreText.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 2/1/12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTCompatibility.h"
#import "NSAttributedString+DTCoreText.h"
#import "DTHTMLWriter.h"
#import "DTCoreTextConstants.h"
#import "DTCoreTextFontDescriptor.h"
#import "DTCoreTextParagraphStyle.h"
#import "DTCSSListStyle.h"
#import "DTImageTextAttachment.h"
#import "NSString+Paragraphs.h"
#import "NSDictionary+DTCoreText.h"
#import "NSAttributedStringRunDelegates.h"

#import <DTFoundation/NSURL+DTComparing.h>

#if TARGET_OS_IPHONE
#import "UIFont+DTCoreText.h"
#endif

@implementation NSAttributedString (DTCoreText)

#pragma mark Text Attachments
- (NSArray *)textAttachmentsWithPredicate:(NSPredicate *)predicate class:(Class)class
{
	if (![self length])
	{
		return nil;
	}
	
	NSMutableArray *foundAttachments = [NSMutableArray array];
	
	NSRange entireRange = NSMakeRange(0, [self length]);
	[self enumerateAttribute:NSAttachmentAttributeName inRange:entireRange options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(DTTextAttachment *attachment, NSRange range, BOOL *stop) {
		
		if (attachment == nil)
		{
			// no attachment value
			return;
		}
		
		if (predicate && ![predicate evaluateWithObject:attachment])
		{
			// doesn't fit predicate, next
			return;
		}
		
		if (class && ![attachment isKindOfClass:class])
		{
			// doesn't fit class, next
			return;
		}
		
		[foundAttachments addObject:attachment];
	}];
	
	if ([foundAttachments count])
	{
		return foundAttachments;
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
		 
		 NSNumber *key = [NSNumber numberWithInteger:(NSInteger)currentEffectiveList]; // list address is identifier
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
	
	NSNumber *key = [NSNumber numberWithInteger:(NSInteger)list]; // list address is identifier
	NSNumber *currentCounterNum = [countersPerList objectForKey:key];
	
	return [currentCounterNum integerValue];
}

- (NSRange)_rangeOfObject:(id)object inArrayBehindAttribute:(NSString *)attribute atIndex:(NSUInteger)location
{
	@synchronized(self)
	{
		NSUInteger stringLength = [self length];
		NSUInteger searchIndex = location;
		
		NSArray *arrayAtIndex;
		
		NSRange totalRange = NSMakeRange(NSNotFound, 0);
		
		BOOL foundList = NO;
		
		do
		{
			NSRange effectiveRange;
			arrayAtIndex = [self attribute:attribute atIndex:searchIndex effectiveRange:&effectiveRange];
			
			if (!arrayAtIndex || [arrayAtIndex indexOfObjectIdenticalTo:object] == NSNotFound)
			{
				break;
			}
			
			searchIndex = effectiveRange.location;
			foundList = YES;
			
			// enhance found range
			if (totalRange.location == NSNotFound)
			{
				totalRange = effectiveRange;
			}
			else
			{
				totalRange = NSUnionRange(totalRange, effectiveRange);
			}
			
			if (searchIndex == 0)
			{
				// reached beginning of string
				break;
			}
			
			searchIndex--;
		}
		while (foundList);
		
		// if we didn't find the list at all, return
		if (!foundList)
		{
			return NSMakeRange(NSNotFound, 0);
		}
		
		// now search forward
		
		searchIndex = NSMaxRange(totalRange);
		
		while (searchIndex < stringLength)
		{
			NSRange effectiveRange;
			arrayAtIndex = [self attribute:attribute atIndex:searchIndex effectiveRange:&effectiveRange];
			
			if (!arrayAtIndex || [arrayAtIndex indexOfObjectIdenticalTo:object] == NSNotFound)
			{
				break;
			}
			
			searchIndex = NSMaxRange(effectiveRange);
			
			// enhance found range
			totalRange = NSUnionRange(totalRange, effectiveRange);
		}
		
		return totalRange;
	}
}

- (NSRange)rangeOfTextList:(DTCSSListStyle *)list atIndex:(NSUInteger)location
{
	NSParameterAssert(list);
	
	NSRange listRange = [self _rangeOfObject:list inArrayBehindAttribute:DTTextListsAttribute atIndex:location];
	
	if (listRange.location == NSNotFound)
	{
		// list was not found
		return listRange;
	}
	
	// extend list range to full paragraphs to be safe
	listRange = [self.string rangeOfParagraphsContainingRange:listRange parBegIndex:NULL parEndIndex:NULL];
	
	return listRange;
}

- (NSRange)rangeOfTextBlock:(DTTextBlock *)textBlock atIndex:(NSUInteger)location
{
	NSParameterAssert(textBlock);
	
	return [self _rangeOfObject:textBlock inArrayBehindAttribute:DTTextBlocksAttribute atIndex:location];
}

- (NSRange)rangeOfAnchorNamed:(NSString *)anchorName
{
	__block NSRange foundRange = NSMakeRange(NSNotFound, 0);
	
	[self enumerateAttribute:DTAnchorAttribute inRange:NSMakeRange(0, [self length]) options:0 usingBlock:^(NSString *value, NSRange range, BOOL *stop) {
		if ([value isEqualToString:anchorName])
		{
			*stop = YES;
			foundRange = range;
		}
	}];
	
	return foundRange;
}

- (NSRange)rangeOfLinkAtIndex:(NSUInteger)location URL:(NSURL * __autoreleasing*)URL
{
	NSRange rangeSoFar;
	
	NSURL *foundURL = [self attribute:DTLinkAttribute atIndex:location effectiveRange:&rangeSoFar];
	
	if (!foundURL)
	{
		return NSMakeRange(NSNotFound, 0);
	}
	
	// search towards beginning
	while (rangeSoFar.location>0)
	{
		NSRange extendedRange;
		NSURL *extendedURL = [self attribute:DTLinkAttribute atIndex:rangeSoFar.location-1 effectiveRange:&extendedRange];
		
		// abort search if key not found or value not identical
		if (!extendedURL || ![extendedURL isEqualToURL:foundURL])
		{
			break;
		}
		
		rangeSoFar = NSUnionRange(rangeSoFar, extendedRange);
	}
	
	NSUInteger length = [self length];
	
	// search towards end
	while (NSMaxRange(rangeSoFar)<length)
	{
		NSRange extendedRange;
		NSURL *extendedURL = [self attribute:DTLinkAttribute atIndex:NSMaxRange(rangeSoFar) effectiveRange:&extendedRange];
		
		// abort search if key not found or value not identical
		if (!extendedURL || ![extendedURL isEqualToURL:foundURL])
		{
			break;
		}
		
		rangeSoFar = NSUnionRange(rangeSoFar, extendedRange);
	}
	
	if (URL)
	{
		*URL = foundURL;
	}
	
	return rangeSoFar;
}

- (NSRange)rangeOfFieldAtIndex:(NSUInteger)location
{
    if (location<[self length])
    {
        // get range of prefix
        NSRange fieldRange;
        NSString *fieldAttribute = [self attribute:DTFieldAttribute atIndex:location effectiveRange:&fieldRange];
        
        if (fieldAttribute)
        {
            return fieldRange;
        }
    }
    
    return NSMakeRange(NSNotFound, 0);
}

#pragma mark HTML Encoding

#ifndef COVERAGE
// exclude method from coverage testing, those are just convenience methods

- (NSString *)htmlString
{
	// create a writer
	DTHTMLWriter *writer = [[DTHTMLWriter alloc] initWithAttributedString:self];
	
	// return it's output
	return [writer HTMLString];
}

- (NSString *)htmlFragment
{
	// create a writer
	DTHTMLWriter *writer = [[DTHTMLWriter alloc] initWithAttributedString:self];
	
	// return it's output
	return [writer HTMLFragment];
}

- (NSString *)plainTextString
{
	NSString *tmpString = [self string];
	
	return [tmpString stringByReplacingOccurrencesOfString:UNICODE_OBJECT_PLACEHOLDER withString:@""];
}

#endif

#pragma mark Generating Special Attributed Strings
+ (NSAttributedString *)prefixForListItemWithCounter:(NSUInteger)listCounter listStyle:(DTCSSListStyle *)listStyle listIndent:(CGFloat)listIndent attributes:(NSDictionary *)attributes
{
	// get existing values from attributes
	CTParagraphStyleRef paraStyle = (__bridge CTParagraphStyleRef)[attributes objectForKey:(id)kCTParagraphStyleAttributeName];
	CTFontRef font = (__bridge CTFontRef)[attributes objectForKey:(id)kCTFontAttributeName];
	
	DTCoreTextFontDescriptor *fontDescriptor = nil;
	DTCoreTextParagraphStyle *paragraphStyle = nil;
	
	if (paraStyle)
	{
		paragraphStyle = [DTCoreTextParagraphStyle paragraphStyleWithCTParagraphStyle:paraStyle];
		
		paragraphStyle.tabStops = nil;
		
		paragraphStyle.headIndent = listIndent;
		
		if (listStyle.type != DTCSSListStyleTypeNone)
		{
			// first tab is to right-align bullet, numbering against
			CGFloat tabOffset = paragraphStyle.headIndent - (CGFloat)5.0; // TODO: change with font size
			[paragraphStyle addTabStopAtPosition:tabOffset alignment:kCTRightTextAlignment];
		}
		
		// second tab is for the beginning of first line after bullet
		[paragraphStyle addTabStopAtPosition:paragraphStyle.headIndent alignment:kCTLeftTextAlignment];
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
		
		font = [fontDesc newMatchingFont];
		
		if (font)
		{
#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES && __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_5_1
			if (___useiOS6Attributes)
			{
				UIFont *uiFont = [UIFont fontWithCTFont:font];
				[newAttributes setObject:uiFont forKey:NSFontAttributeName];
				
				CFRelease(font);
			}
			else
#endif
			{
				[newAttributes setObject:CFBridgingRelease(font) forKey:(id)kCTFontAttributeName];
			}
		}
	}
	
	CGColorRef textColor = (__bridge CGColorRef)[attributes objectForKey:(id)kCTForegroundColorAttributeName];
	
	if (textColor)
	{
		[newAttributes setObject:(__bridge id)textColor forKey:(id)kCTForegroundColorAttributeName];
	}
#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES
	else if (___useiOS6Attributes)
	{
		DTColor *uiColor = [attributes foregroundColor];
		
		if (uiColor)
		{
			[newAttributes setObject:uiColor forKey:NSForegroundColorAttributeName];
		}
	}
#endif
	
	// add paragraph style (this has the tabs)
	if (paragraphStyle)
	{
#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES
		if (___useiOS6Attributes)
		{
			NSParagraphStyle *style = [paragraphStyle NSParagraphStyle];
			[newAttributes setObject:style forKey:NSParagraphStyleAttributeName];
		}
		else
#endif
		{
			CTParagraphStyleRef newParagraphStyle = [paragraphStyle createCTParagraphStyle];
			[newAttributes setObject:CFBridgingRelease(newParagraphStyle) forKey:(id)kCTParagraphStyleAttributeName];
		}
	}
	
	// add textBlock if there's one (this has padding and background color)
	NSArray *textBlocks = [attributes objectForKey:DTTextBlocksAttribute];
	if (textBlocks)
	{
		[newAttributes setObject:textBlocks forKey:DTTextBlocksAttribute];
	}
	
	// transfer all lists so that
	NSArray *lists = [attributes objectForKey:DTTextListsAttribute];
	if (lists)
	{
		[newAttributes setObject:lists forKey:DTTextListsAttribute];
	}
	
	// add a marker so that we know that this is a field/prefix
	[newAttributes setObject:DTListPrefixField forKey:DTFieldAttribute];
	
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
			DTImageTextAttachment *attachment = [[DTImageTextAttachment alloc] init];
			attachment.image = image;
			attachment.displaySize = image.size;
			
#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES && TARGET_OS_IPHONE
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
