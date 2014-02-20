//
//  DTCSSListStyle.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 8/11/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCSSListStyle.h"

#import "DTCoreTextConstants.h"

#import "NSScanner+HTML.h"
//#import "NSString+HTML.h"




@interface DTCSSListStyle ()

- (void)updateFromStyleDictionary:(NSDictionary *)styles;

@property (nonatomic, assign) NSInteger startingItemNumber;

@end



@implementation DTCSSListStyle
{
	BOOL _inherit;
	
	DTCSSListStyleType _type;
	DTCSSListStylePosition _position;
	
	NSString *_imageName;
	NSInteger _startingItemNumber;
}

- (id)initWithStyles:(NSDictionary *)styles
{
	self = [super init];
	
	if (self)
	{
		// default
		_position = DTCSSListStylePositionOutside; 
		_startingItemNumber = 1;
		
		[self updateFromStyleDictionary:styles];
	}
	
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super init];
	if (self) {
		_inherit = [aDecoder decodeBoolForKey:@"inherit"];
		_type = [aDecoder decodeIntegerForKey:@"type"];
		_position = [aDecoder decodeIntegerForKey:@"position"];
		_imageName = [aDecoder decodeObjectForKey:@"imageName"];
		_startingItemNumber = [aDecoder decodeIntegerForKey:@"startingItemNumber"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeBool:_inherit forKey:@"inherit"];
	[aCoder encodeInteger:_type forKey:@"type"];
	[aCoder encodeInteger:_position forKey:@"position"];
	[aCoder encodeObject:_imageName forKey:@"imageName"];
	[aCoder encodeInteger:_startingItemNumber forKey:@"startingItemNumber"];
}

// convert string to listStyleType
+ (DTCSSListStyleType)listStyleTypeFromString:(NSString *)string
{
	if (!string)
	{
		return DTCSSListStyleTypeInvalid;
	}
	
	// always compare lower case
	string = [string lowercaseString];
	
	if ([string isEqualToString:@"inherit"])
	{
		return DTCSSListStyleTypeInherit;
	}
	else if ([string isEqualToString:@"none"])
	{
		return DTCSSListStyleTypeNone;
	}
	else if ([string isEqualToString:@"circle"])
	{
		return DTCSSListStyleTypeCircle;
	}	
	else if ([string isEqualToString:@"square"])
	{
		return DTCSSListStyleTypeSquare;
	}	
	else if ([string isEqualToString:@"decimal"])
	{
		return DTCSSListStyleTypeDecimal;
	}
	else if ([string isEqualToString:@"decimal-leading-zero"])
	{
		return DTCSSListStyleTypeDecimalLeadingZero;
	}        
	else if ([string isEqualToString:@"disc"])
	{
		return DTCSSListStyleTypeDisc;
	}
	else if ([string isEqualToString:@"upper-alpha"]||[string isEqualToString:@"upper-latin"])
	{
		return DTCSSListStyleTypeUpperAlpha;
	}		
	else if ([string isEqualToString:@"lower-alpha"]||[string isEqualToString:@"lower-latin"])
	{
		return DTCSSListStyleTypeLowerAlpha;
	}		
	else if ([string isEqualToString:@"plus"])
	{
		return DTCSSListStyleTypePlus;
	}        
	else if ([string isEqualToString:@"underscore"])
	{
		return DTCSSListStyleTypeUnderscore;
	}  
	else
	{
		return DTCSSListStyleTypeNone;
	}
}

+ (DTCSSListStylePosition)listStylePositionFromString:(NSString *)string
{
	if (!string)
	{
		return DTCSSListStylePositionInvalid;
	}
	
	// always compare lower case
	string = [string lowercaseString];
	
	if ([string isEqualToString:@"inherit"])
	{
		return DTCSSListStylePositionInherit;
	}
	else if ([string isEqualToString:@"inside"])
	{
		return DTCSSListStylePositionInside;
	}
	else if ([string isEqualToString:@"outside"])
	{
		return DTCSSListStylePositionOutside;
	}		
	else
	{
		return DTCSSListStylePositionInherit;
	}
}

// returns NO if not a valid type
- (BOOL)setTypeWithString:(NSString *)string
{
	DTCSSListStyleType type = [DTCSSListStyle listStyleTypeFromString:string];
	if (type == DTCSSListStyleTypeInvalid)
	{
		return NO;
	}

	_type = type;
	
	return YES;
}

// returns NO if not a valid type
- (BOOL)setPositionWithString:(NSString *)string
{
	DTCSSListStylePosition position = [DTCSSListStyle listStylePositionFromString:string];
	
	if (position == DTCSSListStylePositionInvalid)
	{
		return NO;
	}
	
	_position = position;
	return YES;
}

- (void)updateFromStyleDictionary:(NSDictionary *)styles
{
	NSString *shortHand = [[styles objectForKey:@"list-style"] lowercaseString];
	
	if (shortHand)
	{
		if ([shortHand isEqualToString:@"inherit"])
		{
			_inherit = YES;
			return;
		}
		
		NSArray *components = [shortHand componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		
		BOOL typeWasSet = NO;
		BOOL positionWasSet = NO;
		
		
		for (NSString *oneComponent in components)
		{
			if ([oneComponent hasPrefix:@"url"])
			{
				// list-style-image
				NSString *urlString;
				NSScanner *scanner = [NSScanner scannerWithString:oneComponent];
				
				if ([scanner scanCSSURL:&urlString])
				{
					self.imageName = urlString;
					continue;
				}
			}
			
			if (!typeWasSet && [self setTypeWithString:oneComponent])
			{
				typeWasSet = YES;
				continue;
			}
			
			if (!positionWasSet && [self setPositionWithString:oneComponent])
			{
				positionWasSet = YES;
				continue;
			}
		}
		
		return;
	}
	
	// not a short hand, set from individual types
	
	[self setTypeWithString:[styles objectForKey:@"list-style-type"]];
	[self setPositionWithString:[styles objectForKey:@"list-style-position"]];
	
	NSString *tmpStr =  [styles objectForKey:@"list-style-image"];
	
	if (tmpStr)
	{
		// extract just the name
		
		NSString *urlString;
		NSScanner *scanner = [NSScanner scannerWithString:tmpStr];
		
		if ([scanner scanCSSURL:&urlString])
		{
			self.imageName = urlString;
		}
	}
}

#ifndef COVERAGE
// exclude methods from coverage testing

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ %p type=%d position=%d>", NSStringFromClass([self class]), self, (int)_type, (int)_position];
}

- (NSUInteger)hash
{
	NSUInteger calcHash = 7;
	
	calcHash = calcHash*31 + [_imageName hash];
	calcHash = calcHash*31 + (NSUInteger)_type;
	calcHash = calcHash*31 + (NSUInteger)_position;
	calcHash = calcHash*31 + (NSUInteger)_startingItemNumber;
	calcHash = calcHash*31 + (NSUInteger)_inherit;
	
	return calcHash;
}

#endif

/*
 Note: this is not isEqual: because on iOS 7 -[NSMutableAttributedString initWithString:attributes:] calls this via -[NSArray isEqualToArray:]. There isEqual: needs to be returning NO, because otherwise there is some weird internal caching side effect where it reuses previous list arrays
 */
- (BOOL)isEqualToListStyle:(DTCSSListStyle *)otherListStyle
{
	if (!otherListStyle)
	{
		return NO;
	}
	
	if (otherListStyle == self)
	{
		return YES;
	}
	
	if (![otherListStyle isKindOfClass:[DTCSSListStyle class]])
	{
		return NO;
	}
	
	if (_inherit != otherListStyle->_inherit)
	{
		return NO;
	}
	
	if (_type != otherListStyle->_type)
	{
		return NO;
	}
	
	if (_position != otherListStyle->_position)
	{
		return NO;
	}
	
	if (_startingItemNumber != otherListStyle->_startingItemNumber)
	{
		return NO;
	}
	
	if (_imageName == otherListStyle->_imageName)
	{
		return YES;
	}
	
	return ([_imageName isEqualToString:otherListStyle->_imageName]);
}

#pragma mark Copying

- (id)copyWithZone:(NSZone *)zone
{
	DTCSSListStyle *newStyle = [[DTCSSListStyle allocWithZone:zone] init];
	newStyle.type = self.type;
	newStyle.position = self.position;
	newStyle.imageName = self.imageName;
	newStyle.startingItemNumber = self.startingItemNumber;
	
	return newStyle;
}
	
#pragma mark Utilities

- (NSString *)prefixWithCounter:(NSInteger)counter
{
	NSString *token = nil;
	
	DTCSSListStyleType listStyleType = _type;
	
	if (self.imageName)
	{
		listStyleType = DTCSSListStyleTypeImage;
	}
	
	
	switch (listStyleType) 
	{
		case DTCSSListStyleTypeNone:
		case DTCSSListStyleTypeInherit:  // should never be called with inherit
		case DTCSSListStyleTypeInvalid:  
		{
			return nil;
		}
		case DTCSSListStyleTypeImage:
		{
			token = UNICODE_OBJECT_PLACEHOLDER;
			break;
		}
		case DTCSSListStyleTypeCircle:
		{
			token = @"\u25e6";
			break;
		}
		case DTCSSListStyleTypeSquare:
		{
			token = @"\u25aa";
			break;
		}
		case DTCSSListStyleTypeDecimal:
		{
			token = [NSString stringWithFormat:@"%d.", (int)counter];
			break;
		}
		case DTCSSListStyleTypeDecimalLeadingZero:
		{
			token = [NSString stringWithFormat:@"%02d.", (int)counter];
			break;
		}
		case DTCSSListStyleTypeDisc:
		{
			token = @"\u2022";
			break;
		}
		case DTCSSListStyleTypeUpperAlpha:
		case DTCSSListStyleTypeUpperLatin:
		{
			char letter = 'A' + (char)(counter - 1);
			token = [NSString stringWithFormat:@"%c.", letter];
			break;
		}
		case DTCSSListStyleTypeLowerAlpha:
		case DTCSSListStyleTypeLowerLatin:
		{
			char letter = 'a' + (char)(counter - 1);
			token = [NSString stringWithFormat:@"%c.", letter];
			break;
		}
		case DTCSSListStyleTypePlus:
		{
			token = @"+";
			break;
		}
		case DTCSSListStyleTypeUnderscore:
		{
			token = @"_";
		}
	}	
	
	if (_position == DTCSSListStylePositionInside)
	{
		// iOS needs second tab, Mac ignores position outside
#if TARGET_OS_IPHONE		
		return [NSString stringWithFormat:@"\x09\x09%@", token];
#else
		return [NSString stringWithFormat:@"\x09%@\x09", token];
#endif
	}
	else
	{
		return [NSString stringWithFormat:@"\x09%@\x09", token];
	}
}

- (BOOL)isOrdered
{
	switch (_type) 
	{
		case DTCSSListStyleTypeDecimal:
		case DTCSSListStyleTypeDecimalLeadingZero:
		case DTCSSListStyleTypeUpperAlpha:
		case DTCSSListStyleTypeUpperLatin:
		case DTCSSListStyleTypeLowerAlpha:
		case DTCSSListStyleTypeLowerLatin:
			return YES;
			
		default:
			return NO;
	}
}

#pragma mark Properties

@synthesize inherit = _inherit;
@synthesize type = _type;
@synthesize position = _position;
@synthesize imageName = _imageName;
@synthesize startingItemNumber = _startingItemNumber;

@end

// TO DO: Implement image 
