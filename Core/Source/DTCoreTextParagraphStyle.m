//
//  DTCoreTextParagraphStyle.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 4/14/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCoreTextParagraphStyle.h"

static NSCache *_paragraphStyleCache;

#if ALLOW_IPHONE_SPECIAL_CASES
#define SPECIAL_LIST_INDENT		27.0f
#else
#define SPECIAL_LIST_INDENT		36.0
#endif

static dispatch_semaphore_t selfLock;

@implementation DTCoreTextParagraphStyle
{
    CGFloat firstLineIndent;
	CGFloat defaultTabInterval;
    CGFloat paragraphSpacingBefore;
    CGFloat paragraphSpacing;
    CGFloat headIndent;
    CGFloat listIndent;
    CGFloat lineHeightMultiple;
    CGFloat minimumLineHeight;
    CGFloat maximumLineHeight;
    
    CTTextAlignment textAlignment;
    CTWritingDirection writingDirection;
    
    NSMutableArray *_tabStops;
}

+ (DTCoreTextParagraphStyle *)defaultParagraphStyle
{
	return [[DTCoreTextParagraphStyle alloc] init];
}

+ (DTCoreTextParagraphStyle *)paragraphStyleWithCTParagraphStyle:(CTParagraphStyleRef)ctParagraphStyle
{
	DTCoreTextParagraphStyle *returnParagraphStyle = NULL;
	static dispatch_once_t predicate;
  
	dispatch_once(&predicate, ^{
		
		_paragraphStyleCache = [[NSCache alloc] init];
		selfLock = dispatch_semaphore_create(1);
	});

	// synchronize class-wide

	dispatch_semaphore_wait(selfLock, DISPATCH_TIME_FOREVER);
	{
		
		// this is naughty: CTParagraphStyle has a description
		NSString *key = [(__bridge id)ctParagraphStyle description];
		
		returnParagraphStyle = [_paragraphStyleCache objectForKey:key];
		
		if (!returnParagraphStyle) 
		{
			returnParagraphStyle = [[DTCoreTextParagraphStyle alloc] initWithCTParagraphStyle:ctParagraphStyle];
			[_paragraphStyleCache setObject:returnParagraphStyle forKey:key];
		}
	}
	dispatch_semaphore_signal(selfLock);
	
	return returnParagraphStyle;
}

- (id)init
{	
	if ((self = [super init]))
	{
		// defaults
		firstLineIndent = 0.0;
		defaultTabInterval = 36.0;
		writingDirection = kCTWritingDirectionNatural;
		textAlignment = kCTNaturalTextAlignment;
		lineHeightMultiple = 0.0;
		minimumLineHeight = 0.0;
		maximumLineHeight = 0.0;
		paragraphSpacing = 12.0;
		listIndent = SPECIAL_LIST_INDENT;
	}
	
	return self;
}


- (id)initWithCTParagraphStyle:(CTParagraphStyleRef)ctParagraphStyle
{	
	if ((self = [super init]))
	{
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierAlignment,sizeof(textAlignment), &textAlignment);
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(firstLineIndent), &firstLineIndent);
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierDefaultTabInterval, sizeof(defaultTabInterval), &defaultTabInterval);

		
		__unsafe_unretained NSArray *stops; // Could use a CFArray too, leave as a reminder how to do this in the future
		if (CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierTabStops, sizeof(stops), &stops))
		if(stops) {
			self.tabStops = stops;
		}
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierParagraphSpacing, sizeof(paragraphSpacing), &paragraphSpacing);
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierParagraphSpacingBefore,sizeof(paragraphSpacingBefore), &paragraphSpacingBefore);
		
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierHeadIndent, sizeof(headIndent), &headIndent);
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierBaseWritingDirection, sizeof(writingDirection), &writingDirection);
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierLineHeightMultiple, sizeof(lineHeightMultiple), &lineHeightMultiple);
		
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierMinimumLineHeight, sizeof(minimumLineHeight), &minimumLineHeight);
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierMaximumLineHeight, sizeof(maximumLineHeight), &maximumLineHeight);
		
		if (lineHeightMultiple)
		{
			// paragraph space is pre-multiplied
			if (paragraphSpacing)
			{
				paragraphSpacing /= lineHeightMultiple;
			}
			
			if (paragraphSpacingBefore)
			{
				paragraphSpacingBefore /= lineHeightMultiple;
			}
		}
	}
	
	return self;
}



- (CTParagraphStyleRef)createCTParagraphStyle
{
	// need to multiple paragraph spacing with line height multiplier
	float tmpParagraphSpacing = paragraphSpacing;
	float tmpParagraphSpacingBefore = paragraphSpacingBefore;
	
	if (lineHeightMultiple&&(lineHeightMultiple!=1.0))
	{
		tmpParagraphSpacing *= lineHeightMultiple;
		tmpParagraphSpacingBefore *= lineHeightMultiple;
	}
	
	// This just makes it that much easier to track down memory issues with tabstops
	CFArrayRef stops = _tabStops ? CFArrayCreateCopy (NULL, (__bridge CFArrayRef)_tabStops) : NULL;

	CTParagraphStyleSetting settings[] = 
	{
		{kCTParagraphStyleSpecifierAlignment, sizeof(textAlignment), &textAlignment},
		{kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(firstLineIndent), &firstLineIndent},
		{kCTParagraphStyleSpecifierDefaultTabInterval, sizeof(defaultTabInterval), &defaultTabInterval},
		
		{kCTParagraphStyleSpecifierTabStops, sizeof(stops), &stops},
		
		{kCTParagraphStyleSpecifierParagraphSpacing, sizeof(tmpParagraphSpacing), &tmpParagraphSpacing},
		{kCTParagraphStyleSpecifierParagraphSpacingBefore, sizeof(tmpParagraphSpacingBefore), &tmpParagraphSpacingBefore},
		
		{kCTParagraphStyleSpecifierHeadIndent, sizeof(headIndent), &headIndent},
		{kCTParagraphStyleSpecifierBaseWritingDirection, sizeof(writingDirection), &writingDirection},
		{kCTParagraphStyleSpecifierLineHeightMultiple, sizeof(lineHeightMultiple), &lineHeightMultiple},
		
		{kCTParagraphStyleSpecifierMinimumLineHeight, sizeof(minimumLineHeight), &minimumLineHeight},
		{kCTParagraphStyleSpecifierMaximumLineHeight, sizeof(maximumLineHeight), &maximumLineHeight}
	};	
	
	CTParagraphStyleRef ret = CTParagraphStyleCreate(settings, 11);
	if (stops) CFRelease(stops);

	return ret;
}

- (BOOL)addTabStopAtPosition:(CGFloat)position alignment:(CTTextAlignment)alignment
{
	CTTextTabRef tab = CTTextTabCreate(alignment, position, NULL);
	if(tab)
	{
		if (!_tabStops)
		{
			_tabStops = [[NSMutableArray alloc] init];
		}
		[_tabStops addObject:CFBridgingRelease(tab)];
		//CFRelease(tab);
	}
	
	return tab ? YES : NO;
}

#pragma mark HTML Encoding

// representation of this paragraph style in css (as far as possible)
- (NSString *)cssStyleRepresentation
{
	NSMutableString *retString = [NSMutableString string];
	
	switch (textAlignment) 
	{
		case kCTLeftTextAlignment:
			[retString appendString:@"text-align:left;"];
			break;
		case kCTRightTextAlignment:
			[retString appendString:@"text-align:right;"];
			break;
		case kCTCenterTextAlignment:
			[retString appendString:@"text-align:center;"];
			break;
		case kCTJustifiedTextAlignment:
			[retString appendString:@"text-align:justify;"];
			break;
		case kCTNaturalTextAlignment:
			// no output, this is default
			break;
	}
	
	if (lineHeightMultiple && lineHeightMultiple!=1.0f)
	{
		[retString appendFormat:@"line-height:%.2fem;", lineHeightMultiple];
	}

	switch (writingDirection) 
	{
		case kCTWritingDirectionRightToLeft:
			[retString appendString:@"direction:rtl;"];
			break;
		case kCTWritingDirectionLeftToRight:
			[retString appendString:@"direction:ltr;"];
			break;
		case kCTWritingDirectionNatural:
			// no output, this is default
			break;
	}	
	
	// return nil if no content
	if ([retString length])
	{
		return retString;
	}
	else
	{
		return nil;
	}
}

#pragma mark Copying

- (id)copyWithZone:(NSZone *)zone
{
	DTCoreTextParagraphStyle *newObject = [[DTCoreTextParagraphStyle allocWithZone:zone] init];
	
	newObject.firstLineIndent = self.firstLineIndent;
	newObject.defaultTabInterval = self.defaultTabInterval;
	newObject.paragraphSpacing = self.paragraphSpacing;
	newObject.paragraphSpacingBefore = self.paragraphSpacingBefore;
	newObject.lineHeightMultiple = self.lineHeightMultiple;
	newObject.minimumLineHeight = self.minimumLineHeight;
	newObject.maximumLineHeight = self.maximumLineHeight;
	newObject.headIndent = self.headIndent;
	newObject.listIndent = self.listIndent;
	newObject.textAlignment = self.textAlignment;
	newObject.writingDirection = self.writingDirection;
	newObject.tabStops = self.tabStops; // copy
	
	return newObject;
}

#pragma mark Properties

- (void)setTabStops:(NSArray *)tabStops
{
	if (tabStops != _tabStops)
	{
		_tabStops = [tabStops mutableCopy]; // keep mutability
	}
}

@synthesize firstLineIndent;
@synthesize defaultTabInterval;
@synthesize paragraphSpacingBefore;
@synthesize paragraphSpacing;
@synthesize lineHeightMultiple;
@synthesize minimumLineHeight;
@synthesize maximumLineHeight;
@synthesize headIndent;
@synthesize listIndent;
@synthesize textAlignment;
@synthesize writingDirection;
@synthesize tabStops = _tabStops;

@end
