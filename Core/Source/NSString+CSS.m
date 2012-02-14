//
//  NSString+CSS.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 31.01.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "NSString+CSS.h"

#import "DTColor+HTML.h"

@implementation NSString (CSS)

#pragma mark CSS

- (NSDictionary *)dictionaryOfCSSStyles
{
	// font-size:14px;
	NSScanner *scanner = [NSScanner scannerWithString:self];
	
	NSString *name = nil;
	NSString *value = nil;
	
	NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
	
	while ([scanner scanCSSAttribute:&name value:&value]) 
	{
		[tmpDict setObject:value forKey:name];
	}
	
	// converting to non-mutable costs 37.5% of method	
	//	return [NSDictionary dictionaryWithDictionary:tmpDict];
	return tmpDict;
}

- (CGFloat)pixelSizeOfCSSMeasureRelativeToCurrentTextSize:(CGFloat)textSize
{
	NSUInteger stringLength = [self length];
	unichar *_characters = calloc(stringLength, sizeof(unichar));
	[self getCharacters:_characters range:NSMakeRange(0, stringLength)];
	
	CGFloat value = 0;
	
	BOOL commaSeen = NO;
	BOOL negative = NO;
	NSUInteger digitsPastComma = 0;
	
	NSUInteger i=0;
	
	for (; i<stringLength; i++)
	{
		unichar ch = _characters[i];
		
		if (ch>='0' && ch<='9')
		{
			float digit = (float)(ch-'0');
			value *= 10.0f;
			value += digit;
			
			if (commaSeen)
			{
				digitsPastComma++;
			}
		}
		else if (ch=='.')
		{
			commaSeen = YES;
		}
		else if (ch=='-') 
		{
			negative = YES;
		}
		else
		{
			// non-numeric character
			break;
		}
	}
	
	if (commaSeen)
	{
		value /= powf(10.0f, digitsPastComma);
	}
	
	// skip whitespace
	while (i<stringLength && IS_WHITESPACE(_characters[i])) 
	{
		i++;
	}
	
	if (i<stringLength)
	{
		unichar ch = _characters[i++];
		
		if (ch == '%')
		{
			// percent value
			value *= textSize / 100.0f;
		}
		else if (ch == 'e')
		{
			if (i<stringLength)
			{
				if (_characters[i] == 'm')
				{
					// em value
					value *= textSize;
				}
			}
		}
	}
	
	if (negative)
	{
		value *= -1;
	}
	
	free(_characters);
	return value;
}

- (NSArray *)arrayOfCSSShadowsWithCurrentTextSize:(CGFloat)textSize currentColor:(DTColor *)color
{
	NSArray *shadows = [self componentsSeparatedByString:@","];
	
	NSMutableArray *tmpArray = [NSMutableArray array];
	
	for (NSString *oneShadow in shadows)
	{
		NSScanner *scanner = [NSScanner scannerWithString:oneShadow];
		
		
		NSString *element = nil;
		
		if ([scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&element])
		{
			// check if first element is a color
			
			DTColor *shadowColor = [DTColor colorWithHTMLName:element];
			
			NSString *offsetXString = nil;
			NSString *offsetYString = nil;
			NSString *blurString = nil;
			NSString *colorString = nil;
			
			if (shadowColor)
			{
				// format: <color> <length> <length> <length>?
				
				if ([scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&offsetXString])
				{
					if ([scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&offsetYString])
					{
						// blur is optional
						[scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&blurString];
						
						
						CGFloat offset_x = [offsetXString pixelSizeOfCSSMeasureRelativeToCurrentTextSize:textSize];
						CGFloat offset_y = [offsetYString pixelSizeOfCSSMeasureRelativeToCurrentTextSize:textSize];
						CGSize offset = CGSizeMake(offset_x, offset_y);
						CGFloat blur = [blurString pixelSizeOfCSSMeasureRelativeToCurrentTextSize:textSize];
						
						NSDictionary *shadowDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithCGSize:offset], @"Offset",
															 [NSNumber numberWithFloat:blur], @"Blur",
															 shadowColor, @"Color", nil];
						
						[tmpArray addObject:shadowDict];
					}
				}
			}
			else 
			{
				// format: <length> <length> <length>? <color>?
				
				offsetXString = element;
				
				if ([scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&offsetYString])
				{
					// blur is optional
					if ([scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&blurString])
					{
						// check if it's a color
						shadowColor = [DTColor colorWithHTMLName:blurString];
						
						if (shadowColor)
						{
							blurString = nil;
						}
					}
					
					// color is optional, or we might already have one from the blur position
					if (!shadowColor && [scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&colorString])
					{
						shadowColor = [DTColor colorWithHTMLName:colorString];
					}
					
					// if we still don't have a color, it's the current color attributed
					if (!shadowColor) 
					{
						// color is same as color attribute of style
						shadowColor = color;
					}
					
					CGFloat offset_x = [offsetXString pixelSizeOfCSSMeasureRelativeToCurrentTextSize:textSize];
					CGFloat offset_y = [offsetYString pixelSizeOfCSSMeasureRelativeToCurrentTextSize:textSize];
					CGSize offset = CGSizeMake(offset_x, offset_y);
					CGFloat blur = [blurString pixelSizeOfCSSMeasureRelativeToCurrentTextSize:textSize];
					
					NSDictionary *shadowDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithCGSize:offset], @"Offset",
														 [NSNumber numberWithFloat:blur], @"Blur",
														 shadowColor, @"Color", nil];
					
					[tmpArray addObject:shadowDict];
					
					
				}
				
			}
		}
	}		
	
	
	return [NSArray arrayWithArray:tmpArray];
}

- (CGFloat)CSSpixelSize
{
	if ([self hasSuffix:@"px"])
	{
		return [self floatValue];
	}
	
	return [self floatValue];
}

@end
