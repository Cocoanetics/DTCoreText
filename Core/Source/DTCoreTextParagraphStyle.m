//
//  DTCoreTextParagraphStyle.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 4/14/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCoreTextParagraphStyle.h"

static NSCache *_paragraphStyleCache;

static dispatch_semaphore_t selfLock;

@implementation DTCoreTextParagraphStyle
{
	CGFloat _firstLineHeadIndent;
	CGFloat _defaultTabInterval;
	CGFloat _paragraphSpacingBefore;
	CGFloat _paragraphSpacing;
	CGFloat _headIndent;
	CGFloat _listIndent;
	CGFloat _lineHeightMultiple;
	CGFloat _minimumLineHeight;
	CGFloat _maximumLineHeight;
	
	CTTextAlignment _alignment;
	CTWritingDirection _baseWritingDirection;
	
	NSMutableArray *_tabStops;
}

+ (DTCoreTextParagraphStyle *)defaultParagraphStyle
{
	return [[DTCoreTextParagraphStyle alloc] init];
}

+ (NSString *)niceKeyFromParagraghStyle:(CTParagraphStyleRef)ctParagraphStyle {
	
	// this is naughty: CTParagraphStyle has a description
	NSString *key = [(__bridge id)ctParagraphStyle description];
	
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"0x[0123456789abcdef]{1,8}"
																																				 options:NSRegularExpressionCaseInsensitive
																																					 error:nil];
	
	NSString *newKey = [regex stringByReplacingMatchesInString:key 
																										 options:0 
																											 range:NSMakeRange(0, [key length]) 
																								withTemplate:@""];
	
	return newKey;	
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
		
		NSString *key = [self niceKeyFromParagraghStyle:ctParagraphStyle];
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
		_firstLineHeadIndent = 0.0;
		_defaultTabInterval = 36.0;
		_baseWritingDirection = kCTWritingDirectionNatural;
		_alignment = kCTNaturalTextAlignment;
		_lineHeightMultiple = 0.0;
		_minimumLineHeight = 0.0;
		_maximumLineHeight = 0.0;
		_paragraphSpacing = 0.0;
		_listIndent = 0;
	}
	
	return self;
}


- (id)initWithCTParagraphStyle:(CTParagraphStyleRef)ctParagraphStyle
{	
	if ((self = [super init]))
	{
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierAlignment,sizeof(_alignment), &_alignment);
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(_firstLineHeadIndent), &_firstLineHeadIndent);
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierDefaultTabInterval, sizeof(_defaultTabInterval), &_defaultTabInterval);
		
		
		__unsafe_unretained NSArray *stops; // Could use a CFArray too, leave as a reminder how to do this in the future
		if (CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierTabStops, sizeof(stops), &stops))
		{
			self.tabStops = stops;
		}
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierParagraphSpacing, sizeof(_paragraphSpacing), &_paragraphSpacing);
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierParagraphSpacingBefore,sizeof(_paragraphSpacingBefore), &_paragraphSpacingBefore);
		
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierHeadIndent, sizeof(_headIndent), &_headIndent);
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierBaseWritingDirection, sizeof(_baseWritingDirection), &_baseWritingDirection);
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierLineHeightMultiple, sizeof(_lineHeightMultiple), &_lineHeightMultiple);
		
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierMinimumLineHeight, sizeof(_minimumLineHeight), &_minimumLineHeight);
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierMaximumLineHeight, sizeof(_maximumLineHeight), &_maximumLineHeight);
		
		if (_lineHeightMultiple)
		{
			// paragraph space is pre-multiplied
			if (_paragraphSpacing)
			{
				_paragraphSpacing /= _lineHeightMultiple;
			}
			
			if (_paragraphSpacingBefore)
			{
				_paragraphSpacingBefore /= _lineHeightMultiple;
			}
		}
	}
	
	return self;
}



- (CTParagraphStyleRef)createCTParagraphStyle
{
	// need to multiple paragraph spacing with line height multiplier
	float tmpParagraphSpacing = _paragraphSpacing;
	float tmpParagraphSpacingBefore = _paragraphSpacingBefore;
	
	if (_lineHeightMultiple&&(_lineHeightMultiple!=1.0))
	{
		tmpParagraphSpacing *= _lineHeightMultiple;
		tmpParagraphSpacingBefore *= _lineHeightMultiple;
	}
	
	// This just makes it that much easier to track down memory issues with tabstops
	CFArrayRef stops = _tabStops ? CFArrayCreateCopy (NULL, (__bridge CFArrayRef)_tabStops) : NULL;
	
	CTParagraphStyleSetting settings[] = 
	{
		{kCTParagraphStyleSpecifierAlignment, sizeof(_alignment), &_alignment},
		{kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(_firstLineHeadIndent), &_firstLineHeadIndent},
		{kCTParagraphStyleSpecifierDefaultTabInterval, sizeof(_defaultTabInterval), &_defaultTabInterval},
		
		{kCTParagraphStyleSpecifierTabStops, sizeof(stops), &stops},
		
		{kCTParagraphStyleSpecifierParagraphSpacing, sizeof(tmpParagraphSpacing), &tmpParagraphSpacing},
		{kCTParagraphStyleSpecifierParagraphSpacingBefore, sizeof(tmpParagraphSpacingBefore), &tmpParagraphSpacingBefore},
		
		{kCTParagraphStyleSpecifierHeadIndent, sizeof(_headIndent), &_headIndent},
		{kCTParagraphStyleSpecifierBaseWritingDirection, sizeof(_baseWritingDirection), &_baseWritingDirection},
		{kCTParagraphStyleSpecifierLineHeightMultiple, sizeof(_lineHeightMultiple), &_lineHeightMultiple},
		
		{kCTParagraphStyleSpecifierMinimumLineHeight, sizeof(_minimumLineHeight), &_minimumLineHeight},
		{kCTParagraphStyleSpecifierMaximumLineHeight, sizeof(_maximumLineHeight), &_maximumLineHeight}
	};	
	
	CTParagraphStyleRef ret = CTParagraphStyleCreate(settings, 11);
	if (stops) CFRelease(stops);
	
	return ret;
}

- (void)addTabStopAtPosition:(CGFloat)position alignment:(CTTextAlignment)alignment
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
}

#pragma mark HTML Encoding

// representation of this paragraph style in css (as far as possible)
- (NSString *)cssStyleRepresentation
{
	NSMutableString *retString = [NSMutableString string];
	
	switch (_alignment) 
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
	
	if (_lineHeightMultiple && _lineHeightMultiple!=1.0f)
	{
		[retString appendFormat:@"line-height:%.2fem;", _lineHeightMultiple];
	}
	
	switch (_baseWritingDirection)
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
	
	newObject.firstLineHeadIndent = self.firstLineHeadIndent;
	newObject.defaultTabInterval = self.defaultTabInterval;
	newObject.paragraphSpacing = self.paragraphSpacing;
	newObject.paragraphSpacingBefore = self.paragraphSpacingBefore;
	newObject.lineHeightMultiple = self.lineHeightMultiple;
	newObject.minimumLineHeight = self.minimumLineHeight;
	newObject.maximumLineHeight = self.maximumLineHeight;
	newObject.headIndent = self.headIndent;
	newObject.listIndent = self.listIndent;
	newObject.alignment = self.alignment;
	newObject.baseWritingDirection = self.baseWritingDirection;
	newObject.tabStops = self.tabStops; // copy
	newObject.textLists = self.textLists; //copy
	newObject.textBlocks = self.textBlocks; //copy
	
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

@synthesize firstLineHeadIndent = _firstLineHeadIndent;
@synthesize defaultTabInterval = _defaultTabInterval;
@synthesize paragraphSpacingBefore = _paragraphSpacingBefore;
@synthesize paragraphSpacing = _paragraphSpacing;
@synthesize lineHeightMultiple = _lineHeightMultiple;
@synthesize minimumLineHeight = _minimumLineHeight;
@synthesize maximumLineHeight = _maximumLineHeight;
@synthesize headIndent = _headIndent;
@synthesize listIndent = _listIndent;
@synthesize alignment = _alignment;
@synthesize textLists;
@synthesize textBlocks;
@synthesize baseWritingDirection;
@synthesize tabStops = _tabStops;

@end
