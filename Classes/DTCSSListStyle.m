//
//  DTCSSListStyle.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 8/11/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCSSListStyle.h"

@interface DTCSSListStyle ()

- (void)updateFromStyleDictionary:(NSDictionary *)styles;

@end



@implementation DTCSSListStyle

+ (DTCSSListStyle *)listStyleWithStyles:(NSDictionary *)styles
{
	return [[[DTCSSListStyle alloc] initWithStyles:styles] autorelease];
}

+ (DTCSSListStyle *)decimalListStyle
{
	DTCSSListStyle *style = [[[DTCSSListStyle alloc] init] autorelease];
	style.type = DTCSSListStyleTypeDecimal;
	style.position = DTCSSListStylePositionOutside;
	return style;
}

+ (DTCSSListStyle *)discListStyle
{
	DTCSSListStyle *style = [[[DTCSSListStyle alloc] init] autorelease];
	style.type = DTCSSListStyleTypeDisc;
	style.position = DTCSSListStylePositionOutside;
	return style;
}

+ (DTCSSListStyle *)inheritedListStyle
{
	DTCSSListStyle *style = [[[DTCSSListStyle alloc] init] autorelease];
	style.inherit = YES;
	return style;
}


- (id)initWithStyles:(NSDictionary *)styles
{
	self = [super init];
	
	if (self)
	{
		// default
		_position = DTCSSListStylePositionOutside; 
		
		[self updateFromStyleDictionary:styles];
	}
	
	return self;
}

// returns NO if not a valid type
- (BOOL)setTypeWithString:(NSString *)string
{
	if (!string)
	{
		return NO;
	}
	
	// always compare lower case
	string = [string lowercaseString];
	
	if ([string isEqualToString:@"inherit"])
	{
		_type = DTCSSListStyleTypeInherit;
	}
	else if ([string isEqualToString:@"none"])
	{
		_type = DTCSSListStyleTypeNone;
	}
	else if ([string isEqualToString:@"circle"])
	{
		_type = DTCSSListStyleTypeCircle;
	}		
	else if ([string isEqualToString:@"decimal"])
	{
		_type = DTCSSListStyleTypeDecimal;
	}
	else if ([string isEqualToString:@"decimal-leading-zero"])
	{
		_type = DTCSSListStyleTypeDecimalLeadingZero;
	}        
	else if ([string isEqualToString:@"disc"])
	{
		_type = DTCSSListStyleTypeDisc;
	}
	else if ([string isEqualToString:@"upper-alpha"]||[string isEqualToString:@"upper-latin"])
	{
		_type = DTCSSListStyleTypeUpperAlpha;
	}		
	else if ([string isEqualToString:@"lower-alpha"]||[string isEqualToString:@"lower-latin"])
	{
		_type = DTCSSListStyleTypeLowerAlpha;
	}		
	else if ([string isEqualToString:@"plus"])
	{
		_type = DTCSSListStyleTypePlus;
	}        
	else if ([string isEqualToString:@"underscore"])
	{
		_type = DTCSSListStyleTypeUnderscore;
	}  
	else
	{
		return NO;
	}
	
	return YES;
}

// returns NO if not a valid type
- (BOOL)setPositionWithString:(NSString *)string
{
	if (!string)
	{
		return NO;
	}
	
	// always compare lower case
	string = [string lowercaseString];
	
	if ([string isEqualToString:@"inherit"])
	{
		_position = DTCSSListStylePositionInherit;
	}
	else if ([string isEqualToString:@"inside"])
	{
		_position = DTCSSListStylePositionInside;
	}
	else if ([string isEqualToString:@"outside"])
	{
		_position = DTCSSListStylePositionOutside;
	}		
	else
	{
		return NO;
	}
	
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
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ type=%d position=%d>", NSStringFromClass([self class]), _type, _position];
}

#pragma mark Copying

- (id)copyWithZone:(NSZone *)zone
{
	DTCSSListStyle *newStyle = [[DTCSSListStyle allocWithZone:zone] init];
	newStyle.type = self.type;
	newStyle.position = self.position;
	
	return newStyle;
}
	
#pragma mark Utilities

- (NSString *)prefixWithCounter:(NSInteger)counter
{
	NSString *token = nil;
	
	switch (_type) 
	{
		case DTCSSListStyleTypeNone:
		case DTCSSListStyleTypeInherit:  // should never be called with inherit
		{
			return nil;
		}
		case DTCSSListStyleTypeCircle:
		{
			token = @"\u25e6";
			break;
		}
		case DTCSSListStyleTypeDecimal:
		{
			token = [NSString stringWithFormat:@"%d.", counter];
			break;
		}
		case DTCSSListStyleTypeDecimalLeadingZero:
		{
			token = [NSString stringWithFormat:@"%02d.", counter];
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
			char letter = 'A' + counter - 1;
			token = [NSString stringWithFormat:@"%c.", letter];
			break;
		}
		case DTCSSListStyleTypeLowerAlpha:
		case DTCSSListStyleTypeLowerLatin:
		{
			char letter = 'a' + counter - 1;
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
		return [NSString stringWithFormat:@"\x09\x09%@", token];
	}
	else
	{
		return [NSString stringWithFormat:@"\x09%@\x09", token];
	}
}

#pragma mark Properties

@synthesize inherit = _inherit;
@synthesize type = _type;
@synthesize position = _position;

@end

// TO DO: Implement image 
// TO DO: Implement position
