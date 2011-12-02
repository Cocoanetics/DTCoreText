//
//  DTCSSListStyle.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 8/11/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCSSListStyle.h"
#import "NSScanner+HTML.h"
#import "NSString+HTML.h"




@interface DTCSSListStyle ()

- (void)updateFromStyleDictionary:(NSDictionary *)styles;

@end



@implementation DTCSSListStyle
{
	BOOL _inherit;
	
	DTCSSListStyleType _type;
	DTCSSListStylePosition _position;
	
	NSString *_imageName;
}

+ (DTCSSListStyle *)listStyleWithStyles:(NSDictionary *)styles
{
	return [[DTCSSListStyle alloc] initWithStyles:styles];
}

+ (DTCSSListStyle *)decimalListStyle
{
	DTCSSListStyle *style = [[DTCSSListStyle alloc] init];
	style.type = DTCSSListStyleTypeDecimal;
	style.position = DTCSSListStylePositionOutside;
	return style;
}

+ (DTCSSListStyle *)discListStyle
{
	DTCSSListStyle *style = [[DTCSSListStyle alloc] init];
	style.type = DTCSSListStyleTypeDisc;
	style.position = DTCSSListStylePositionOutside;
	return style;
}

+ (DTCSSListStyle *)inheritedListStyle
{
	DTCSSListStyle *style = [[DTCSSListStyle alloc] init];
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


// convert string to listStyleType
+ (DTCSSListStyleType)listStyleTypeFromString:(NSString *)string
{
	if (!string)
	{
		return NSNotFound;
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
		return NSNotFound;
	}
}

+ (DTCSSListStylePosition)listStylePositionFromString:(NSString *)string
{
	if (!string)
	{
		return NSNotFound;
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
		return NSNotFound;
	}
}

// returns NO if not a valid type
- (BOOL)setTypeWithString:(NSString *)string
{
	DTCSSListStyleType type = [DTCSSListStyle listStyleTypeFromString:string];
	
	if (type == NSNotFound)
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
	
	if (position == NSNotFound)
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
	newStyle.imageName = self.imageName;
	
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
@synthesize imageName = _imageName;

@end

// TO DO: Implement image 
