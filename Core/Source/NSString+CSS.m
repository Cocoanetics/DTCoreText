//
//  NSString+CSS.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 31.01.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTCoreText.h"
#import "NSString+CSS.h"

@implementation NSString (CSS)

#pragma mark CSS

- (NSDictionary *)dictionaryOfCSSStyles
{
	// font-size:14px;
	NSScanner *scanner = [NSScanner scannerWithString:self];
	
	NSString *name = nil;
	NSString *value = nil;
	
	NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
	
	@autoreleasepool
	{
		while ([scanner scanCSSAttribute:&name value:&value])
		{
			[tmpDict setObject:value forKey:name];
		}
	}
	
	// converting to non-mutable costs 37.5% of method
	//	return [NSDictionary dictionaryWithDictionary:tmpDict];
	return tmpDict;
}

- (BOOL)isCSSLengthValue
{
	NSScanner *scanner = [NSScanner scannerWithString:self];
	
	NSString *numberStr;
	
	if (![scanner scanCharactersFromSet:[NSCharacterSet cssLengthValueCharacterSet] intoString:&numberStr])
	{
		return NO;
	}
	
	NSString *numberUnitStr;
	if (![scanner scanCharactersFromSet:[NSCharacterSet cssLengthUnitCharacterSet] intoString:&numberUnitStr])
	{
		return YES;
	}
	
	if ([numberUnitStr isEqualToString:@"em"] | [numberUnitStr isEqualToString:@"px"] | [numberUnitStr isEqualToString:@"pt"])
	{
		return YES;
	}
	
	return NO;
}

- (CGFloat)pixelSizeOfCSSMeasureRelativeToCurrentTextSize:(CGFloat)textSize textScale:(CGFloat)textScale
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
		else if (ch == 'p')
		{
			if (i<stringLength)
			{
				if (_characters[i] == 'x')
				{
					// absolute pixel value gets scaled
					value *= textScale;
				}
				else if (_characters[i] == 't')
				{
					// 1 pt = 1.3333 px on Mac, so we do the same
					value *= 1.3333f;
					
					// absolute pixel value gets scaled
					value *= textScale;
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

#pragma mark - Margins / Padding

- (DTEdgeInsets)DTEdgeInsetsRelativeToCurrentTextSize:(CGFloat)textSize textScale:(CGFloat)textScale
{
	DTEdgeInsets edgeInsets = {0,0,0,0};
	
	if ([self length])
	{
		// maybe it's using the short style
		NSArray *parts = [self componentsSeparatedByString:@" "];
		
		if ([parts count] == 4)
		{
			edgeInsets.top = [[parts objectAtIndex:0] pixelSizeOfCSSMeasureRelativeToCurrentTextSize:textSize textScale:textScale];
			edgeInsets.right = [[parts objectAtIndex:1] pixelSizeOfCSSMeasureRelativeToCurrentTextSize:textSize textScale:textScale];
			edgeInsets.bottom = [[parts objectAtIndex:2] pixelSizeOfCSSMeasureRelativeToCurrentTextSize:textSize textScale:textScale];
			edgeInsets.left = [[parts objectAtIndex:3] pixelSizeOfCSSMeasureRelativeToCurrentTextSize:textSize textScale:textScale];
		}
		else if ([parts count] == 3)
		{
			edgeInsets.top = [[parts objectAtIndex:0] pixelSizeOfCSSMeasureRelativeToCurrentTextSize:textSize textScale:textScale];
			edgeInsets.right = [[parts objectAtIndex:1] pixelSizeOfCSSMeasureRelativeToCurrentTextSize:textSize textScale:textScale];
			edgeInsets.bottom = [[parts objectAtIndex:2] pixelSizeOfCSSMeasureRelativeToCurrentTextSize:textSize textScale:textScale];
			edgeInsets.left = edgeInsets.right;
		}
		else if ([parts count] == 2)
		{
			edgeInsets.top = [[parts objectAtIndex:0] pixelSizeOfCSSMeasureRelativeToCurrentTextSize:textSize textScale:textScale];
			edgeInsets.right = [[parts objectAtIndex:1] pixelSizeOfCSSMeasureRelativeToCurrentTextSize:textSize textScale:textScale];
			edgeInsets.bottom = edgeInsets.top;
			edgeInsets.left = edgeInsets.right;
		}
		else
		{
			CGFloat paddingAmount = [self pixelSizeOfCSSMeasureRelativeToCurrentTextSize:textSize textScale:textScale];
			edgeInsets = DTEdgeInsetsMake(paddingAmount, paddingAmount, paddingAmount, paddingAmount);
		}
	}
	
	return edgeInsets;
}

#pragma mark - CSS Shadows

- (NSArray *)arrayOfCSSShadowsWithCurrentTextSize:(CGFloat)textSize currentColor:(DTColor *)color
{
	NSString *trimmedString = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if ([trimmedString isEqualToString:@"none"])
	{
		return nil;
	}
	
	NSScanner *scanner = [NSScanner scannerWithString:trimmedString];
	
	NSMutableCharacterSet *tokenEndSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy];
	[tokenEndSet addCharactersInString:@","];
	
	
	NSMutableArray *tmpArray = [NSMutableArray array];
	
	while (![scanner isAtEnd])
	{
		DTColor *shadowColor = nil;
		
		NSString *offsetXString = nil;
		NSString *offsetYString = nil;
		NSString *blurString = nil;
		
		if ([scanner scanHTMLColor:&shadowColor])
		{
			// format: <color> <length> <length> <length>?
			
			if ([scanner scanUpToCharactersFromSet:tokenEndSet intoString:&offsetXString])
			{
				if ([scanner scanUpToCharactersFromSet:tokenEndSet intoString:&offsetYString])
				{
					// blur is optional
					[scanner scanUpToCharactersFromSet:tokenEndSet intoString:&blurString];
					
					
					CGFloat offset_x = [offsetXString pixelSizeOfCSSMeasureRelativeToCurrentTextSize:textSize textScale:1.0f];
					CGFloat offset_y = [offsetYString pixelSizeOfCSSMeasureRelativeToCurrentTextSize:textSize textScale:1.0f];
					CGSize offset = CGSizeMake(offset_x, offset_y);
					CGFloat blur = [blurString pixelSizeOfCSSMeasureRelativeToCurrentTextSize:textSize textScale:1.0f];
					
					NSValue *offsetValue;
#if TARGET_OS_IPHONE
					offsetValue = [NSValue valueWithCGSize:offset];
#else
					offsetValue = [NSValue valueWithSize:offset];
#endif
					
					NSDictionary *shadowDict = [NSDictionary dictionaryWithObjectsAndKeys:offsetValue, @"Offset",
														 DTNSNumberFromCGFloat(blur), @"Blur",
														 shadowColor, @"Color", nil];
					
					[tmpArray addObject:shadowDict];
				}
			}
		}
		else
		{
			// format: <length> <length> <length>? <color>?
			
			if ([scanner scanUpToCharactersFromSet:tokenEndSet intoString:&offsetXString])
			{
				if ([scanner scanUpToCharactersFromSet:tokenEndSet intoString:&offsetYString])
				{
					// blur is optional
					if (![scanner scanHTMLColor:&shadowColor])
					{
						if ([scanner scanUpToCharactersFromSet:tokenEndSet intoString:&blurString])
						{
							if (![scanner scanHTMLColor:&shadowColor])
							{
								// invalid color, we ignore this color
							}
						}
					}
					
					if (!shadowColor)
					{
						// color is same as color attribute of style
						shadowColor = color;
					}
					
					CGFloat offset_x = [offsetXString pixelSizeOfCSSMeasureRelativeToCurrentTextSize:textSize textScale:1.0f];
					CGFloat offset_y = [offsetYString pixelSizeOfCSSMeasureRelativeToCurrentTextSize:textSize textScale:1.0f];
					CGSize offset = CGSizeMake(offset_x, offset_y);
					CGFloat blur = [blurString pixelSizeOfCSSMeasureRelativeToCurrentTextSize:textSize textScale:1.0f];
					
					NSValue *offsetValue;
#if TARGET_OS_IPHONE
					offsetValue = [NSValue valueWithCGSize:offset];
#else
					offsetValue = [NSValue valueWithSize:offset];
#endif
					
					NSDictionary *shadowDict = [NSDictionary dictionaryWithObjectsAndKeys:offsetValue, @"Offset",
														 DTNSNumberFromCGFloat(blur), @"Blur",
														 shadowColor, @"Color", nil];
					
					[tmpArray addObject:shadowDict];
				}
			}
		}
		
		// now there should be a comma
		if (![scanner scanString:@"," intoString:NULL])
		{
			break;
		}
	}
	
	// only return array if not empty
	if ([tmpArray count])
	{
		return tmpArray;
	}
	
	return nil;
}

- (NSString *)stringByDecodingCSSContentAttribute
{
	NSUInteger length = [self length];
	
	unichar *characters = calloc(length, sizeof(unichar));
	unichar *final = calloc(length, sizeof(unichar));
	
	[self getCharacters:characters range:NSMakeRange(0, length)];
	
	NSUInteger outChars = 0;
	
	BOOL inEscapedSequence = NO;
	unichar decodedChar = 0;
	NSUInteger escapedCharacterCount = 0;
	
	for (NSUInteger idx=0; idx<length;idx++)
	{
		unichar character = characters[idx];
		
		if (inEscapedSequence && (escapedCharacterCount<4))
		{
			if (character=='\\')
			{
				// escaped backslash
				final[outChars++] = '\\';
				inEscapedSequence = NO;
			}
			else if ((character>='0' && character<='9') || (character>='A' && character<='F') || (character>='a' && character<='f'))
			{
				// hex digit
				decodedChar *= 16;
				
				if (character>='0' && character<='9')
				{
					decodedChar += (character - '0');
				}
				else if (character>='A' && character<='F')
				{
					decodedChar += (character - 'A' + 10);
				}
				else if (character>='a' && character<='f')
				{
					decodedChar += (character - 'a' + 10);
				}
				
				escapedCharacterCount++;
			}
			else
			{
				// illegal character following slash
				final[outChars++] = '\\';
				final[outChars++] = character;
				
				inEscapedSequence = NO;
			}
		}
		else
		{
			if (inEscapedSequence)
			{
				// output what we have decoded so far
				final[outChars++] = decodedChar;
			}
			
			if (character == '\\')
			{
				// begin of escape sequence
				decodedChar = 0;
				escapedCharacterCount = 0;
				inEscapedSequence = YES;
			}
			else
			{
				inEscapedSequence = NO;
				
				// just copy
				final[outChars++] = character;
			}
		}
	}
	
	// if string ended in escaped sequence we still need to output
	if (inEscapedSequence)
	{
		// output what we have decoded so far
		final[outChars++] = decodedChar;
	}
	
	free(characters);
	NSString *clean = [[NSString alloc] initWithCharacters:final length:outChars];
	free(final);
	
	return clean;
}

@end
