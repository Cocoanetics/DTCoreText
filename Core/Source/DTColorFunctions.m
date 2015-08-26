//
//  DTColorFunctions.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 9/9/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTCompatibility.h"
#import "DTColorFunctions.h"


static NSDictionary *colorLookup = nil;

#pragma mark - Private Functions

NSUInteger _integerValueFromHexString(NSString *hexString);

#pragma mark - Implementations

NSUInteger _integerValueFromHexString(NSString *hexString)
{
	int result = 0;
	sscanf([hexString UTF8String], "%x", &result);
	return result;
}

DTColor *DTColorCreateWithHexString(NSString *hexString)
{
	if ([hexString length]!=6 && [hexString length]!=3)
	{
		return nil;
	}
	
	NSUInteger digits = [hexString length]/3;
	CGFloat maxValue = (digits==1)?15.0:255.0;
	
	NSUInteger redValue = _integerValueFromHexString([hexString substringWithRange:NSMakeRange(0, digits)]);
	NSUInteger greenValue = _integerValueFromHexString([hexString substringWithRange:NSMakeRange(digits, digits)]);
	NSUInteger blueValue = _integerValueFromHexString([hexString substringWithRange:NSMakeRange(2*digits, digits)]);
	
	CGFloat red = redValue/maxValue;
	CGFloat green = greenValue/maxValue;
	CGFloat blue = blueValue/maxValue;
    CGFloat alpha = 1.0;
	
#if TARGET_OS_IPHONE
	return [DTColor colorWithRed:red green:green blue:blue alpha:alpha];
#else
    CGFloat components[4] = {red, green, blue, alpha};
    return [NSColor colorWithColorSpace:[NSColorSpace genericRGBColorSpace] components:components count:4];
#endif
}

DTColor *DTColorCreateWithHTMLName(NSString *name)
{
	if ([name hasPrefix:@"#"])
	{
		return DTColorCreateWithHexString([name substringFromIndex:1]);
	}
	
	if ([name hasPrefix:@"rgba"])
	{
		NSString *rgbaName = [name stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"rgba() "]];
		NSArray *rgba = [rgbaName componentsSeparatedByString:@","];
		
		if ([rgba count] != 4)
		{
			// Incorrect syntax
			return nil;
		}
		
		CGFloat red = (CGFloat)[rgba[0] floatValue] / 255;
		CGFloat green = [rgba[1] floatValue] / 255;
		CGFloat blue = [rgba[2] floatValue] / 255;
		CGFloat alpha = [rgba[3] floatValue];
		
#if TARGET_OS_IPHONE
		return [DTColor colorWithRed:red green:green blue:blue alpha:alpha];
#else
        CGFloat components[4] = {red, green, blue, alpha};
        return [NSColor colorWithColorSpace:[NSColorSpace genericRGBColorSpace] components:components count:4];
#endif
	}
	
	if([name hasPrefix:@"rgb"])
	{
		NSString * rgbName = [name stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"rbg() "]];
		NSArray* rgb = [rgbName componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
		
		if ([rgb count] != 3)
		{
			// Incorrect syntax
			return nil;
		}
		
		CGFloat red = [rgb[0] floatValue] / 255;
		CGFloat green = [rgb[1] floatValue] / 255;
		CGFloat blue = [rgb[2] floatValue] / 255;
		CGFloat alpha = 1.0;
		
#if TARGET_OS_IPHONE
		return [DTColor colorWithRed:red green:green blue:blue alpha:alpha];
#else
        CGFloat components[4] = {red, green, blue, alpha};
        return (DTColor *)[NSColor colorWithColorSpace:[NSColorSpace genericRGBColorSpace] components:components count:4];
#endif
	}
	
	static dispatch_once_t predicate;
	dispatch_once(&predicate, ^{
		colorLookup = @{@"aliceblue" : @"F0F8FF",
				@"antiquewhite" : @"FAEBD7",
				@"aqua" : @"00FFFF",
				@"aquamarine" : @"7FFFD4",
				@"azure" : @"F0FFFF",
				@"beige" : @"F5F5DC",
				@"bisque" : @"FFE4C4",
				@"black" : @"000000",
				@"blanchedalmond" : @"FFEBCD",
				@"blue" : @"0000FF",
				@"blueviolet" : @"8A2BE2",
				@"brown" : @"A52A2A",
				@"burlywood" : @"DEB887",
				@"cadetblue" : @"5F9EA0",
				@"chartreuse" : @"7FFF00",
				@"chocolate" : @"D2691E",
				@"coral" : @"FF7F50",
				@"cornflowerblue" : @"6495ED",
				@"cornsilk" : @"FFF8DC",
				@"crimson" : @"DC143C",
				@"cyan" : @"00FFFF",
				@"darkblue" : @"00008B",
				@"darkcyan" : @"008B8B",
				@"darkgoldenrod" : @"B8860B",
				@"darkgray" : @"A9A9A9",
				@"darkgrey" : @"A9A9A9",
				@"darkgreen" : @"006400",
				@"darkkhaki" : @"BDB76B",
				@"darkmagenta" : @"8B008B",
				@"darkolivegreen" : @"556B2F",
				@"darkorange" : @"FF8C00",
				@"darkorchid" : @"9932CC",
				@"darkred" : @"8B0000",
				@"darksalmon" : @"E9967A",
				@"darkseagreen" : @"8FBC8F",
				@"darkslateblue" : @"483D8B",
				@"darkslategray" : @"2F4F4F",
				@"darkslategrey" : @"2F4F4F",
				@"darkturquoise" : @"00CED1",
				@"darkviolet" : @"9400D3",
				@"deeppink" : @"FF1493",
				@"deepskyblue" : @"00BFFF",
				@"dimgray" : @"696969",
				@"dimgrey" : @"696969",
				@"dodgerblue" : @"1E90FF",
				@"firebrick" : @"B22222",
				@"floralwhite" : @"FFFAF0",
				@"forestgreen" : @"228B22",
				@"fuchsia" : @"FF00FF",
				@"gainsboro" : @"DCDCDC",
				@"ghostwhite" : @"F8F8FF",
				@"gold" : @"FFD700",
				@"goldenrod" : @"DAA520",
				@"gray" : @"808080",
				@"grey" : @"808080",
				@"green" : @"008000",
				@"greenyellow" : @"ADFF2F",
				@"honeydew" : @"F0FFF0",
				@"hotpink" : @"FF69B4",
				@"indianred" : @"CD5C5C",
				@"indigo" : @"4B0082",
				@"ivory" : @"FFFFF0",
				@"khaki" : @"F0E68C",
				@"lavender" : @"E6E6FA",
				@"lavenderblush" : @"FFF0F5",
				@"lawngreen" : @"7CFC00",
				@"lemonchiffon" : @"FFFACD",
				@"lightblue" : @"ADD8E6",
				@"lightcoral" : @"F08080",
				@"lightcyan" : @"E0FFFF",
				@"lightgoldenrodyellow" : @"FAFAD2",
				@"lightgray" : @"D3D3D3",
				@"lightgrey" : @"D3D3D3",
				@"lightgreen" : @"90EE90",
				@"lightpink" : @"FFB6C1",
				@"lightsalmon" : @"FFA07A",
				@"lightseagreen" : @"20B2AA",
				@"lightskyblue" : @"87CEFA",
				@"lightslategray" : @"778899",
				@"lightslategrey" : @"778899",
				@"lightsteelblue" : @"B0C4DE",
				@"lightyellow" : @"FFFFE0",
				@"lime" : @"00FF00",
				@"limegreen" : @"32CD32",
				@"linen" : @"FAF0E6",
				@"magenta" : @"FF00FF",
				@"maroon" : @"800000",
				@"mediumaquamarine" : @"66CDAA",
				@"mediumblue" : @"0000CD",
				@"mediumorchid" : @"BA55D3",
				@"mediumpurple" : @"9370D8",
				@"mediumseagreen" : @"3CB371",
				@"mediumslateblue" : @"7B68EE",
				@"mediumspringgreen" : @"00FA9A",
				@"mediumturquoise" : @"48D1CC",
				@"mediumvioletred" : @"C71585",
				@"midnightblue" : @"191970",
				@"mintcream" : @"F5FFFA",
				@"mistyrose" : @"FFE4E1",
				@"moccasin" : @"FFE4B5",
				@"navajowhite" : @"FFDEAD",
				@"navy" : @"000080",
				@"oldlace" : @"FDF5E6",
				@"olive" : @"808000",
				@"olivedrab" : @"6B8E23",
				@"orange" : @"FFA500",
				@"orangered" : @"FF4500",
				@"orchid" : @"DA70D6",
				@"palegoldenrod" : @"EEE8AA",
				@"palegreen" : @"98FB98",
				@"paleturquoise" : @"AFEEEE",
				@"palevioletred" : @"D87093",
				@"papayawhip" : @"FFEFD5",
				@"peachpuff" : @"FFDAB9",
				@"peru" : @"CD853F",
				@"pink" : @"FFC0CB",
				@"plum" : @"DDA0DD",
				@"powderblue" : @"B0E0E6",
				@"purple" : @"800080",
				@"red" : @"FF0000",
				@"rosybrown" : @"BC8F8F",
				@"royalblue" : @"4169E1",
				@"saddlebrown" : @"8B4513",
				@"salmon" : @"FA8072",
				@"sandybrown" : @"F4A460",
				@"seagreen" : @"2E8B57",
				@"seashell" : @"FFF5EE",
				@"sienna" : @"A0522D",
				@"silver" : @"C0C0C0",
				@"skyblue" : @"87CEEB",
				@"slateblue" : @"6A5ACD",
				@"slategray" : @"708090",
				@"slategrey" : @"708090",
				@"snow" : @"FFFAFA",
				@"springgreen" : @"00FF7F",
				@"steelblue" : @"4682B4",
				@"tan" : @"D2B48C",
				@"teal" : @"008080",
				@"thistle" : @"D8BFD8",
				@"tomato" : @"FF6347",
				@"turquoise" : @"40E0D0",
				@"violet" : @"EE82EE",
				@"wheat" : @"F5DEB3",
				@"white" : @"FFFFFF",
				@"whitesmoke" : @"F5F5F5",
				@"yellow" : @"FFFF00",
				@"yellowgreen" : @"9ACD32"};
	});
	
	NSString *hexString = colorLookup[[name lowercaseString]];
	
	return DTColorCreateWithHexString(hexString);
}

NSString *DTHexStringFromDTColor(DTColor *color)
{
	CGColorRef cgColor = [color colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]].CGColor;
	size_t count = CGColorGetNumberOfComponents(cgColor);
	const CGFloat *components = CGColorGetComponents(cgColor);

	static NSString *stringFormat = @"%02x%02x%02x";

	// Grayscale
	if (count == 2)
	{
		NSUInteger white = (NSUInteger) (components[0] * (CGFloat) 255);
		return [NSString stringWithFormat:stringFormat, white, white, white];
	}

	// RGB
	else if (count == 4)
	{
		return [NSString stringWithFormat:stringFormat,
						(NSUInteger) (components[0] * (CGFloat) 255),
						(NSUInteger) (components[1] * (CGFloat) 255),
						(NSUInteger) (components[2] * (CGFloat) 255)];
	}

	// Unsupported color space
	return nil;
}

