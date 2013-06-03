//
//  DTCoreTextParagraphStyle.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 4/14/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCoreTextParagraphStyle.h"
#import "DTTextBlock.h"
#import "DTCSSListStyle.h"
#import "DTWeakSupport.h"

#if !TARGET_OS_IPHONE
#import <CommonCrypto/CommonDigest.h>
#endif

// global cache for returning previously created immutable paragraph styles
static NSCache *_CTParagraphStyleCache = nil;

// a struct that takes on all sub-values, used for fast hash
typedef struct {
	CGFloat firstLineHeadIndent;
	CGFloat defaultTabInterval;
	CGFloat paragraphSpacingBefore;
	CGFloat paragraphSpacing;
	CGFloat headIndent;
	CGFloat tailIndent;
	CGFloat lineHeightMultiple;
	CGFloat minimumLineHeight;
	CGFloat maximumLineHeight;
	NSInteger alignment; // make it full width, origin is uint8
	NSInteger baseWritingDirection; // make it full width, origin is int8
	NSUInteger tabsBlocksListsHash;
} allvalues_t;

@implementation DTCoreTextParagraphStyle
{
	CGFloat _firstLineHeadIndent;
	CGFloat _defaultTabInterval;
	CGFloat _paragraphSpacingBefore;
	CGFloat _paragraphSpacing;
	CGFloat _headIndent;
	CGFloat _tailIndent;
	CGFloat _lineHeightMultiple;
	CGFloat _minimumLineHeight;
	CGFloat _maximumLineHeight;
	
	CTTextAlignment _alignment;
	CTWritingDirection _baseWritingDirection;
	
	NSMutableArray *_tabStops;
}

+ (void)initialize
{
	_CTParagraphStyleCache = [[NSCache alloc] init];
}

+ (DTCoreTextParagraphStyle *)defaultParagraphStyle
{
	return [[DTCoreTextParagraphStyle alloc] init];
}

+ (DTCoreTextParagraphStyle *)paragraphStyleWithCTParagraphStyle:(CTParagraphStyleRef)ctParagraphStyle
{
	return [[DTCoreTextParagraphStyle alloc] initWithCTParagraphStyle:ctParagraphStyle];
}

#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES
+ (DTCoreTextParagraphStyle *)paragraphStyleWithNSParagraphStyle:(NSParagraphStyle *)paragraphStyle
{
	DTCoreTextParagraphStyle *retStyle = [[DTCoreTextParagraphStyle alloc] init];
	
	retStyle.firstLineHeadIndent = paragraphStyle.firstLineHeadIndent;
	retStyle.headIndent = paragraphStyle.headIndent;
	
	retStyle.paragraphSpacing = paragraphStyle.paragraphSpacing;
	retStyle.paragraphSpacingBefore = paragraphStyle.paragraphSpacingBefore;
	
	retStyle.lineHeightMultiple = paragraphStyle.lineHeightMultiple;
	retStyle.minimumLineHeight = paragraphStyle.minimumLineHeight;
	retStyle.maximumLineHeight = paragraphStyle.maximumLineHeight;
	
	switch(paragraphStyle.alignment)
	{
		case NSTextAlignmentLeft:
			retStyle.alignment = kCTLeftTextAlignment;
			break;
		case NSTextAlignmentRight:
			retStyle.alignment = kCTRightTextAlignment;
			break;
		case NSTextAlignmentCenter:
			retStyle.alignment = kCTCenterTextAlignment;
			break;
		case NSTextAlignmentJustified:
			retStyle.alignment = kCTJustifiedTextAlignment;
			break;
		case NSTextAlignmentNatural:
			retStyle.alignment = kCTNaturalTextAlignment;
			break;
	}
	
	switch (paragraphStyle.baseWritingDirection)
	{
		case NSWritingDirectionNatural:
			retStyle.baseWritingDirection = kCTWritingDirectionNatural;
			break;
		case NSWritingDirectionLeftToRight:
			retStyle.baseWritingDirection = kCTWritingDirectionLeftToRight;
			break;
		case NSWritingDirectionRightToLeft:
			retStyle.baseWritingDirection = kCTWritingDirectionRightToLeft;
			break;
	}
	
	return retStyle;
}
#endif

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
	}
	
	return self;
}


- (id)initWithCTParagraphStyle:(CTParagraphStyleRef)ctParagraphStyle
{	
	if ((self = [super init]))
	{
		// text alignment
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierAlignment,sizeof(_alignment), &_alignment);
		
		// indents
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(_firstLineHeadIndent), &_firstLineHeadIndent);
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierHeadIndent, sizeof(_headIndent), &_headIndent);
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierTailIndent, sizeof(_tailIndent), &_tailIndent);
		
		// paragraph spacing
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierParagraphSpacing, sizeof(_paragraphSpacing), &_paragraphSpacing);
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierParagraphSpacingBefore,sizeof(_paragraphSpacingBefore), &_paragraphSpacingBefore);


		// tab stops
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierDefaultTabInterval, sizeof(_defaultTabInterval), &_defaultTabInterval);
		
		DT_WEAK_VARIABLE NSArray *stops; // Could use a CFArray too, leave as a reminder how to do this in the future
		if (CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierTabStops, sizeof(stops), &stops))
		{
			self.tabStops = stops;
		}
		
		
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierBaseWritingDirection, sizeof(_baseWritingDirection), &_baseWritingDirection);
		
		// line height
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierMinimumLineHeight, sizeof(_minimumLineHeight), &_minimumLineHeight);
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierMaximumLineHeight, sizeof(_maximumLineHeight), &_maximumLineHeight);

		
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierLineHeightMultiple, sizeof(_lineHeightMultiple), &_lineHeightMultiple);
		
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

// creates a fast hash for the properties
- (id <NSCopying>)_cacheKey
{
	NSMutableString *tabsBlocksListsDescription = [NSMutableString string];
	
	for (id tab in _tabStops)
	{
		CTTextTabRef tabStop = (__bridge CTTextTabRef)tab;
		
		CTTextAlignment alignment = CTTextTabGetAlignment(tabStop);
		double location = CTTextTabGetLocation(tabStop);
		
		[tabsBlocksListsDescription appendFormat:@"-tab:%d-%f", alignment, location];
	}
	
	for (DTTextBlock *textBlock in _textBlocks)
	{
		[tabsBlocksListsDescription appendFormat:@"-block:%lx", (unsigned long)[textBlock hash]];
	}
	
	for (DTCSSListStyle *listStyle in _textLists)
	{
		[tabsBlocksListsDescription appendFormat:@"-list:%lx", (unsigned long)[listStyle hash]];
	}
	
#if TARGET_OS_IPHONE
	// on iOS we use NSData's hashing function because we have less than 80 bytes (48)
	allvalues_t *allvalues = malloc(sizeof(allvalues_t)); // will not be freed
#else
	// on MAC this struct is 96 bytes, so we use CommonCrypto's MD5 to reduce from > 80 bytes to less
	allvalues_t allvalues_stack; // create tmp variable on stack 
	allvalues_t *allvalues = &allvalues_stack; // pointer so that we can use the arrow operator
#endif
	
	*allvalues = (allvalues_t){0,0,0,0,0,0,0,0,0,0,0,0};

	// pack all values in the struct
	allvalues->firstLineHeadIndent = _firstLineHeadIndent;
	allvalues->defaultTabInterval = _defaultTabInterval;
	allvalues->paragraphSpacingBefore = _paragraphSpacingBefore;
	allvalues->paragraphSpacing = _paragraphSpacing;
	allvalues->headIndent = _headIndent;
	allvalues->tailIndent = _tailIndent;
	allvalues->lineHeightMultiple = _lineHeightMultiple;
	allvalues->minimumLineHeight = _minimumLineHeight;
	allvalues->maximumLineHeight = _maximumLineHeight;
	allvalues->baseWritingDirection = _baseWritingDirection;
	allvalues->alignment = _alignment;
	allvalues->tabsBlocksListsHash = [tabsBlocksListsDescription hash];

#if TARGET_OS_IPHONE
	// wrap it in NSData
	return [NSData dataWithBytesNoCopy:allvalues length:sizeof(allvalues_t) freeWhenDone:YES];
#else
	//	Alternate Implementation using MD5
	void *digest = malloc(CC_MD5_DIGEST_LENGTH); // will not be freed
	CC_MD5(allvalues, (CC_LONG)sizeof(allvalues_t), digest);
	
	return [NSData dataWithBytesNoCopy:digest length:CC_MD5_DIGEST_LENGTH freeWhenDone:YES];
#endif
}

- (CTParagraphStyleRef)createCTParagraphStyle
{
	id cacheKey = [self _cacheKey];
	
	CTParagraphStyleRef cachedParagraphStyle = CFBridgingRetain([_CTParagraphStyleCache objectForKey:cacheKey]);
	
	if (cachedParagraphStyle)
	{
		return cachedParagraphStyle; // +1 reference
	}
	
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
		{kCTParagraphStyleSpecifierTailIndent, sizeof(_tailIndent), &_tailIndent},
		{kCTParagraphStyleSpecifierBaseWritingDirection, sizeof(_baseWritingDirection), &_baseWritingDirection},
		{kCTParagraphStyleSpecifierLineHeightMultiple, sizeof(_lineHeightMultiple), &_lineHeightMultiple},
		
		{kCTParagraphStyleSpecifierMinimumLineHeight, sizeof(_minimumLineHeight), &_minimumLineHeight},
		{kCTParagraphStyleSpecifierMaximumLineHeight, sizeof(_maximumLineHeight), &_maximumLineHeight}
	};	
	
	CTParagraphStyleRef ret = CTParagraphStyleCreate(settings, 12);
	if (stops) CFRelease(stops);

	// cache it for next time
	[_CTParagraphStyleCache setObject:(__bridge id)ret forKey:cacheKey];
	
	return ret;
}

#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES
- (NSParagraphStyle *)NSParagraphStyle
{
	NSMutableParagraphStyle *mps = [[NSMutableParagraphStyle alloc] init];

	[mps setFirstLineHeadIndent:_firstLineHeadIndent];

	// _defaultTabInterval not supported

	[mps setParagraphSpacing:_paragraphSpacing];
	[mps setParagraphSpacingBefore:_paragraphSpacingBefore];
	
	[mps setHeadIndent:_headIndent];
	[mps setTailIndent:_tailIndent];
	
	[mps setMinimumLineHeight:_minimumLineHeight];
	[mps setMaximumLineHeight:_maximumLineHeight];
	
	switch(_alignment)
	{
		case kCTLeftTextAlignment:
		{
			[mps setAlignment:NSTextAlignmentLeft];
			break;
		}
			
		case kCTRightTextAlignment:
		{
			[mps setAlignment:NSTextAlignmentRight];
			break;
		}
			
		case kCTCenterTextAlignment:
		{
			[mps setAlignment:NSTextAlignmentCenter];
			break;
		}
			
		case kCTJustifiedTextAlignment:
		{
			[mps setAlignment:NSTextAlignmentJustified];
			break;
		}
			
		case kCTNaturalTextAlignment:
		{
			[mps setAlignment:NSTextAlignmentNatural];
			break;
		}
	}
	
	switch (_baseWritingDirection)
	{
		case  kCTWritingDirectionNatural:
		{
			[mps setBaseWritingDirection:NSWritingDirectionNatural];
			break;
		}
			
		case  kCTWritingDirectionLeftToRight:
		{
			[mps setBaseWritingDirection:NSWritingDirectionLeftToRight];
			break;
		}
			
		case  kCTWritingDirectionRightToLeft:
		{
			[mps setBaseWritingDirection:NSWritingDirectionRightToLeft];
			break;
		}
	}

	// _tap stops not supported
	return (NSParagraphStyle *)mps;
}
#endif

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
		NSNumber *number = [NSNumber numberWithFloat:_lineHeightMultiple];
		[retString appendFormat:@"line-height:%@em;", number];
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
	
	// Spacing at the bottom
	if (_paragraphSpacing!=0.0f)
	{
		NSNumber *number = [NSNumber numberWithFloat:_paragraphSpacing];
		[retString appendFormat:@"margin-bottom:%@px;", number];
	}

	// Spacing at the top
	if (_paragraphSpacingBefore!=0.0f)
	{
		NSNumber *number = [NSNumber numberWithFloat:_paragraphSpacingBefore];
		[retString appendFormat:@"margin-top:%@px;", number];
	}
	
	// Spacing at the left
	if (_headIndent!=0.0f)
	{
		NSNumber *number = [NSNumber numberWithFloat:_headIndent];
		[retString appendFormat:@"margin-left:%@px;", number];
	}

	// Spacing at the right
	if (_tailIndent!=0.0f)
	{
		// tail indent is negative if from trailing margin
		NSNumber *number = [NSNumber numberWithFloat:-_tailIndent];
		[retString appendFormat:@"margin-right:%@px;", number];
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
	newObject.tailIndent = self.tailIndent;
	newObject.defaultTabInterval = self.defaultTabInterval;
	newObject.paragraphSpacing = self.paragraphSpacing;
	newObject.paragraphSpacingBefore = self.paragraphSpacingBefore;
	newObject.lineHeightMultiple = self.lineHeightMultiple;
	newObject.minimumLineHeight = self.minimumLineHeight;
	newObject.maximumLineHeight = self.maximumLineHeight;
	newObject.headIndent = self.headIndent;
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

- (void)setFirstLineHeadIndent:(CGFloat)firstLineHeadIndent
{
	if (_firstLineHeadIndent != firstLineHeadIndent)
	{
		_firstLineHeadIndent = firstLineHeadIndent;
	}
}

- (void)setDefaultTabInterval:(CGFloat)defaultTabInterval
{
	if (_defaultTabInterval != defaultTabInterval)
	{
		_defaultTabInterval = defaultTabInterval;
	}
}

- (void)setParagraphSpacingBefore:(CGFloat)paragraphSpacingBefore
{
	if (_paragraphSpacingBefore != paragraphSpacingBefore)
	{
		_paragraphSpacingBefore = paragraphSpacingBefore;
	}
}

- (void)setParagraphSpacing:(CGFloat)paragraphSpacing
{
	if (_paragraphSpacing != paragraphSpacing)
	{
		_paragraphSpacing = paragraphSpacing;
	}
}

- (void)setLineHeightMultiple:(CGFloat)lineHeightMultiple
{
	if (_lineHeightMultiple != lineHeightMultiple)
	{
		_lineHeightMultiple = lineHeightMultiple;
	}
}

- (void)setMinimumLineHeight:(CGFloat)minimumLineHeight
{
	if (_minimumLineHeight != minimumLineHeight)
	{
		_minimumLineHeight = minimumLineHeight;
	}
}

- (void)setMaximumLineHeight:(CGFloat)maximumLineHeight
{
	if (_maximumLineHeight != maximumLineHeight)
	{
		_maximumLineHeight = maximumLineHeight;
	}
}

- (void)setHeadIndent:(CGFloat)headIndent
{
	if (_headIndent != headIndent)
	{
		_headIndent = headIndent;
	}
}

- (void)setTailIndent:(CGFloat)tailIndent
{
	if (_tailIndent != tailIndent)
	{
		_tailIndent = tailIndent;
	}
}

- (void)setAlignment:(CTTextAlignment)alignment
{
	if (_alignment != alignment)
	{
		_alignment = alignment;
	}
}

- (void)setTextLists:(NSArray *)textLists
{
	if (_textLists != textLists)
	{
		_textLists = [textLists copy];
	}
}

- (void)setTextBlocks:(NSArray *)textBlocks
{
	if (_textBlocks != textBlocks)
	{
		_textBlocks = [textBlocks copy];
	}
}

- (void)setBaseWritingDirection:(CTWritingDirection)baseWritingDirection
{
	if (_baseWritingDirection != baseWritingDirection)
	{
		_baseWritingDirection = baseWritingDirection;
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
@synthesize tailIndent = _tailIndent;
@synthesize alignment = _alignment;
@synthesize textLists = _textLists;
@synthesize textBlocks = _textBlocks;
@synthesize baseWritingDirection = _baseWritingDirection;
@synthesize tabStops = _tabStops;

@end
