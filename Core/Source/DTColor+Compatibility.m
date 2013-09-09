//
//  DTColor+Compatibility.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTColor+Compatibility.h"
#import "DTColorFunctions.h"

#if TARGET_OS_IPHONE

@implementation UIColor (HTML)

- (CGFloat)alphaComponent
{
	return CGColorGetAlpha(self.CGColor);
}

@end

#else

@implementation NSColor (HTML)

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_7
+ (NSColor *)colorWithCGColor:(CGColorRef)cgColor
{
	size_t count = CGColorGetNumberOfComponents(cgColor);
	const CGFloat *components = CGColorGetComponents(cgColor);
	
	// Grayscale
	if (count == 2)
	{
		return [NSColor colorWithDeviceWhite:components[0] alpha:components[1]];
	}
	
	// RGB
	else if (count == 4)
	{
		return [NSColor colorWithDeviceRed:components[0] green:components[1] blue:components[2] alpha:components[3]];
	}
	
	// neigher grayscale nor rgba
	return nil;
}

// From https://gist.github.com/1593255
- (CGColorRef)CGColor
{
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	
	NSColor *selfCopy = [self colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	
	CGFloat colorValues[4];
	[selfCopy getRed:&colorValues[0] green:&colorValues[1] blue:&colorValues[2] alpha:&colorValues[3]];
	
	CGColorRef color = CGColorCreate(colorSpace, colorValues);
	
	CGColorSpaceRelease(colorSpace);
	
	return color;
}
#endif

@end

#endif
