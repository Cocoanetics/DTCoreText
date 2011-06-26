//
//  DTCoreTextParagraphStyle.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 4/14/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCoreTextParagraphStyle.h"


@implementation DTCoreTextParagraphStyle

+ (DTCoreTextParagraphStyle *)defaultParagraphStyle
{
	return [[[DTCoreTextParagraphStyle alloc] init] autorelease];
}

+ (DTCoreTextParagraphStyle *)paragraphStyleWithCTParagraphStyle:(CTParagraphStyleRef)ctParagraphStyle
{
	return [[[DTCoreTextParagraphStyle alloc] initWithCTParagraphStyle:ctParagraphStyle] autorelease];
}

- (id)init
{
	self = [super init];
	
	if (self)
	{
		// defaults
		firstLineIndent = 0.0;
		defaultTabInterval = 36.0;
		writingDirection = kCTWritingDirectionNatural;
		textAlignment = kCTNaturalTextAlignment;
		lineHeightMultiple = 0.0;
		minimumLineHeight = 0.0;
		maximumLineHeight = 0.0;
	}
	
	return self;
}


- (id)initWithCTParagraphStyle:(CTParagraphStyleRef)ctParagraphStyle
{
	self = [super init];
	
	if (self)
	{
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierAlignment,sizeof(textAlignment), &textAlignment);
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(firstLineIndent), &firstLineIndent);
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierDefaultTabInterval, sizeof(defaultTabInterval), &defaultTabInterval);
		
		NSArray *tabStops;
		if (CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierTabStops, sizeof(tabStops), &tabStops))
		{
			self.tabStops = tabStops;
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

- (void)dealloc
{
	[_tabStops release];
	
	[super dealloc];
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
	
	CTParagraphStyleSetting settings[] = 
	{
		{kCTParagraphStyleSpecifierAlignment, sizeof(textAlignment), &textAlignment},
		{kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(firstLineIndent), &firstLineIndent},
		{kCTParagraphStyleSpecifierDefaultTabInterval, sizeof(defaultTabInterval), &defaultTabInterval},
		
		{kCTParagraphStyleSpecifierTabStops, sizeof(_tabStops), &_tabStops},
		
		{kCTParagraphStyleSpecifierParagraphSpacing, sizeof(tmpParagraphSpacing), &tmpParagraphSpacing},
		{kCTParagraphStyleSpecifierParagraphSpacingBefore, sizeof(tmpParagraphSpacingBefore), &tmpParagraphSpacingBefore},
		
		{kCTParagraphStyleSpecifierHeadIndent, sizeof(headIndent), &headIndent},
		{kCTParagraphStyleSpecifierBaseWritingDirection, sizeof(writingDirection), &writingDirection},
		{kCTParagraphStyleSpecifierLineHeightMultiple, sizeof(lineHeightMultiple), &lineHeightMultiple},
		
		{kCTParagraphStyleSpecifierMinimumLineHeight, sizeof(minimumLineHeight), &minimumLineHeight},
		{kCTParagraphStyleSpecifierMaximumLineHeight, sizeof(maximumLineHeight), &maximumLineHeight}
	};	
	
	return CTParagraphStyleCreate(settings, 11);
}

- (void)addTabStopAtPosition:(CGFloat)position alignment:(CTTextAlignment)alignment
{
	if (!_tabStops)
	{
		_tabStops = [[NSMutableArray alloc] init];
	}
	
	CTTextTabRef tab = CTTextTabCreate(alignment, position, NULL);
	[_tabStops addObject:(id)tab];
	CFRelease(tab);
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
		[_tabStops release];
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
@synthesize textAlignment;
@synthesize writingDirection;
@synthesize tabStops = _tabStops;

@end
