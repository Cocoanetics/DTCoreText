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
        lineHeight = 0.0;
    }

    return self;
}

- (void)dealloc
{
    [tabStops release];
    
    [super dealloc];
}


- (CTParagraphStyleRef)createCTParagraphStyle
{
	CTParagraphStyleSetting settings[] = 
    {
		{kCTParagraphStyleSpecifierAlignment, sizeof(textAlignment), &textAlignment},
		{kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(firstLineIndent), &firstLineIndent},
		{kCTParagraphStyleSpecifierDefaultTabInterval, sizeof(defaultTabInterval), &defaultTabInterval},
		{kCTParagraphStyleSpecifierTabStops, sizeof(tabStops), &tabStops},
		{kCTParagraphStyleSpecifierParagraphSpacing, sizeof(paragraphSpacing), &paragraphSpacing},
		{kCTParagraphStyleSpecifierParagraphSpacingBefore, sizeof(paragraphSpacingBefore), &paragraphSpacingBefore},
		{kCTParagraphStyleSpecifierHeadIndent, sizeof(headIndent), &headIndent},
		{kCTParagraphStyleSpecifierBaseWritingDirection, sizeof(writingDirection), &writingDirection},
        {kCTParagraphStyleSpecifierLineHeightMultiple, sizeof(lineHeightMultiple), &lineHeightMultiple},
        {kCTParagraphStyleSpecifierMinimumLineHeight, sizeof(lineHeight), &lineHeight},
        {kCTParagraphStyleSpecifierMaximumLineHeight, sizeof(lineHeight), &lineHeight}
	};	
	
	return CTParagraphStyleCreate(settings, 11);
}

- (void)addTabStopAtPosition:(CGFloat)position alignment:(CTTextAlignment)alignment
{
    if (!tabStops)
    {
        tabStops = [[NSMutableArray alloc] init];
    }
    
    CTTextTabRef tab = CTTextTabCreate(alignment, position, NULL);
    [tabStops addObject:(id)tab];
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
    newObject.headIndent = self.headIndent;
    newObject.textAlignment = self.textAlignment;
    newObject.writingDirection = self.writingDirection;
    newObject.tabStops = self.tabStops; // copy
    
    return newObject;
}

#pragma mark Properties

@synthesize firstLineIndent;
@synthesize defaultTabInterval;
@synthesize paragraphSpacingBefore;
@synthesize paragraphSpacing;
@synthesize lineHeightMultiple;
@synthesize lineHeight;
@synthesize headIndent;
@synthesize textAlignment;
@synthesize writingDirection;
@synthesize tabStops;

@end
