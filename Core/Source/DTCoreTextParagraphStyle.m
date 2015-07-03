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
#import "DTCoreTextFunctions.h"

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
	if ( ! paragraphStyle) {
		paragraphStyle = [NSParagraphStyle defaultParagraphStyle];
	}
	
	DTCoreTextParagraphStyle *retStyle = [[DTCoreTextParagraphStyle alloc] init];
	
	retStyle.firstLineHeadIndent = paragraphStyle.firstLineHeadIndent;
	retStyle.headIndent = paragraphStyle.headIndent;
	
	retStyle.paragraphSpacing = paragraphStyle.paragraphSpacing;
	retStyle.paragraphSpacingBefore = paragraphStyle.paragraphSpacingBefore;
	
	retStyle.lineHeightMultiple = paragraphStyle.lineHeightMultiple;
	retStyle.minimumLineHeight = paragraphStyle.minimumLineHeight;
	retStyle.maximumLineHeight = paragraphStyle.maximumLineHeight;
	
	retStyle.alignment = DTNSTextAlignmentToCTTextAlignment(paragraphStyle.alignment);
	
	switch (paragraphStyle.baseWritingDirection)
	{
		case NSWritingDirectionNatural:
		{
			retStyle.baseWritingDirection = kCTWritingDirectionNatural;
			break;
		}
			
		case NSWritingDirectionLeftToRight:
		{
			retStyle.baseWritingDirection = kCTWritingDirectionLeftToRight;
			break;
		}
		case NSWritingDirectionRightToLeft:
		{
			retStyle.baseWritingDirection = kCTWritingDirectionRightToLeft;
			break;
		}
	}
	
#if DTCORETEXT_SUPPORT_NSPARAGRAPHSTYLE_TABS
	if (NSClassFromString(@"NSTextTab") && [NSParagraphStyle instancesRespondToSelector:@selector(tabStops)])
	{
		NSArray *tabStops = [paragraphStyle valueForKey:@"tabStops"];
		
		NSMutableArray *tmpArray = [NSMutableArray array];
		
		for (NSTextTab *textTab in tabStops)
		{
			CTTextAlignment alignment = DTNSTextAlignmentToCTTextAlignment(textTab.alignment);
			CGFloat location = textTab.location;
			
			CTTextTabRef tab = CTTextTabCreate(alignment, location, NULL);
			
			if (tab)
			{
				[tmpArray addObject:(__bridge id)(tab)];
				CFRelease(tab);
			}
		}
		
		if ([tmpArray count])
		{
			retStyle.tabStops = tmpArray;
		}
	}
	
	retStyle.defaultTabInterval = paragraphStyle.defaultTabInterval;
#endif
	
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
		
		CFArrayRef stops; // Could use a CFArray too, leave as a reminder how to do this in the future
		if (CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierTabStops, sizeof(stops), &stops))
		{
			self.tabStops = (__bridge NSArray *) stops;
		}
		
		
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierBaseWritingDirection, sizeof(_baseWritingDirection), &_baseWritingDirection);
		
		// line height
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierMinimumLineHeight, sizeof(_minimumLineHeight), &_minimumLineHeight);
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierMaximumLineHeight, sizeof(_maximumLineHeight), &_maximumLineHeight);

		
		CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, kCTParagraphStyleSpecifierLineHeightMultiple, sizeof(_lineHeightMultiple), &_lineHeightMultiple);
	}
	
	return self;
}

- (CTParagraphStyleRef)createCTParagraphStyle
{
	// This just makes it that much easier to track down memory issues with tabstops
	CFArrayRef stops = _tabStops ? CFArrayCreateCopy (NULL, (__bridge CFArrayRef)_tabStops) : NULL;
	
	CTParagraphStyleSetting settings[] = 
	{
		{kCTParagraphStyleSpecifierAlignment, sizeof(_alignment), &_alignment},
		{kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(_firstLineHeadIndent), &_firstLineHeadIndent},
		{kCTParagraphStyleSpecifierDefaultTabInterval, sizeof(_defaultTabInterval), &_defaultTabInterval},
		
		{kCTParagraphStyleSpecifierTabStops, sizeof(stops), &stops},
		
		{kCTParagraphStyleSpecifierParagraphSpacing, sizeof(_paragraphSpacing), &_paragraphSpacing},
		{kCTParagraphStyleSpecifierParagraphSpacingBefore, sizeof(_paragraphSpacingBefore), &_paragraphSpacingBefore},
		
		{kCTParagraphStyleSpecifierHeadIndent, sizeof(_headIndent), &_headIndent},
		{kCTParagraphStyleSpecifierTailIndent, sizeof(_tailIndent), &_tailIndent},
		{kCTParagraphStyleSpecifierBaseWritingDirection, sizeof(_baseWritingDirection), &_baseWritingDirection},
		{kCTParagraphStyleSpecifierLineHeightMultiple, sizeof(_lineHeightMultiple), &_lineHeightMultiple},
		
		{kCTParagraphStyleSpecifierMinimumLineHeight, sizeof(_minimumLineHeight), &_minimumLineHeight},
		{kCTParagraphStyleSpecifierMaximumLineHeight, sizeof(_maximumLineHeight), &_maximumLineHeight}
	};	
	
	CTParagraphStyleRef ret = CTParagraphStyleCreate(settings, 12);
	
	if (stops)
	{
		CFRelease(stops);
	}

	return ret;
}

#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES
- (NSParagraphStyle *)NSParagraphStyle
{
	NSMutableParagraphStyle *mps = [[NSMutableParagraphStyle alloc] init];

	[mps setFirstLineHeadIndent:_firstLineHeadIndent];

	[mps setParagraphSpacing:_paragraphSpacing];
	[mps setParagraphSpacingBefore:_paragraphSpacingBefore];
	
	[mps setHeadIndent:_headIndent];
	[mps setTailIndent:_tailIndent];
	
	[mps setMinimumLineHeight:_minimumLineHeight];
	[mps setMaximumLineHeight:_maximumLineHeight];
	[mps setLineHeightMultiple:_lineHeightMultiple];
	
	[mps setAlignment:DTNSTextAlignmentFromCTTextAlignment(_alignment)];
	
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
	
#if DTCORETEXT_SUPPORT_NSPARAGRAPHSTYLE_TABS
	if (NSClassFromString(@"NSTextTab") && [NSParagraphStyle instancesRespondToSelector:@selector(tabStops)])
	{
		NSMutableArray *tabs = [NSMutableArray array];
		
		for (id object in _tabStops)
		{
			CTTextTabRef tab = (__bridge CTTextTabRef)(object);
			
			CTTextAlignment alignment = CTTextTabGetAlignment(tab);
			NSTextAlignment nsAlignment = DTNSTextAlignmentFromCTTextAlignment(alignment);
			CGFloat location = (CGFloat)CTTextTabGetLocation(tab);
			
			NSTextTab *textTab = [[NSTextTab alloc] initWithTextAlignment:nsAlignment location:location options:[NSDictionary dictionary]];
			
			if (!textTab)
			{
				break;
			}
			
			[tabs addObject:textTab];
		}
		
		if ([tabs count])
		{
			[mps setValue:tabs forKey:@"tabStops"];
		}
		
		mps.defaultTabInterval = _defaultTabInterval;
	}
#endif
	
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
	
	if (_lineHeightMultiple!=0 && _lineHeightMultiple!=1.0f)
	{
		NSNumber *number = DTNSNumberFromCGFloat(_lineHeightMultiple);
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
		NSNumber *number = DTNSNumberFromCGFloat(_paragraphSpacing);
		[retString appendFormat:@"margin-bottom:%@px;", number];
	}

	// Spacing at the top
	if (_paragraphSpacingBefore!=0.0f)
	{
		NSNumber *number = DTNSNumberFromCGFloat(_paragraphSpacingBefore);
		[retString appendFormat:@"margin-top:%@px;", number];
	}
	
	// Spacing at the left
	if (_headIndent!=0.0f)
	{
		NSNumber *number = DTNSNumberFromCGFloat(_headIndent);
		[retString appendFormat:@"margin-left:%@px;", number];
	}

	// Spacing at the right
	if (_tailIndent!=0.0f)
	{
		// tail indent is negative if from trailing margin
		NSNumber *number = DTNSNumberFromCGFloat(-_tailIndent);
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

#pragma mark - Comparing

- (BOOL)isEqual:(id)object
{
	if (object == self)
	{
		return YES;
	}
	
	if (!object)
	{
		return NO;
	}
	
	if (![object isKindOfClass:[DTCoreTextParagraphStyle class]])
	{
		return NO;
	}
	
	DTCoreTextParagraphStyle *otherStyle = object;
	
	
	if (_firstLineHeadIndent != otherStyle->_firstLineHeadIndent)
	{
		return NO;
	}
	
	if (_headIndent != otherStyle->_headIndent)
	{
		return NO;
	}

	if (_tailIndent != otherStyle->_tailIndent)
	{
		return NO;
	}
	
	if (_defaultTabInterval != otherStyle->_defaultTabInterval)
	{
		return NO;
	}
	
	if (_paragraphSpacing != otherStyle->_paragraphSpacing)
	{
		return NO;
	}
	
	if (_paragraphSpacingBefore != otherStyle->_paragraphSpacingBefore)
	{
		return NO;
	}

	if (_lineHeightMultiple != otherStyle->_lineHeightMultiple)
	{
		return NO;
	}
	
	if (_minimumLineHeight != otherStyle->_minimumLineHeight)
	{
		return NO;
	}
	
	if (_maximumLineHeight != otherStyle->_maximumLineHeight)
	{
		return NO;
	}
	
	if (_alignment != otherStyle->_alignment)
	{
		return NO;
	}
	
	if (_baseWritingDirection != otherStyle->_baseWritingDirection)
	{
		return NO;
	}
	
	if (_textLists && ![_textLists isEqualToArray:otherStyle->_textLists])
	{
		return NO;
	}

	if (_textBlocks && ![_textBlocks isEqualToArray:otherStyle->_textBlocks])
	{
		return NO;
	}
	
	if (_tabStops && ![_tabStops isEqualToArray:otherStyle->_tabStops])
	{
		return NO;
	}
	
	return YES;
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
