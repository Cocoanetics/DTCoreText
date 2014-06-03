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

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_7 || MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_7
#import "DTCoreTextMacros.h"
#import <objc/runtime.h>

static void* DTCoreTextCGColorKey = &DTCoreTextCGColorKey;
#endif // MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_7 || MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_7


#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_7
@interface NSColor (DTCoreText)
+ (NSColor *)DTCoreText_colorWithCGColor:(CGColorRef)cgColor;
- (CGColorRef)DTCoreText_CGColor DT_RETURNS_INNER_POINTER;
@end

static void DTCoreTextAddMissingSelector(Class aClass, SEL aSelector, SEL implementationSelector)
{
	Method method = class_getInstanceMethod(aClass, aSelector);
	if (method == NULL) {
		method = class_getInstanceMethod(aClass, implementationSelector);
		NSCAssert(method != NULL, @"missing implementation method");
		
		IMP methodImplementation = method_getImplementation(method);
		const char *methodTypeEncoding = method_getTypeEncoding(method);
		
#if !defined(NS_BLOCK_ASSERTIONS)
		BOOL rc = class_addMethod(aClass, aSelector, methodImplementation, methodTypeEncoding);
		NSCAssert(rc, @"failed to add missing method");
#else
		(void) class_addMethod(aClass, aSelector, methodImplementation, methodTypeEncoding);
#endif
	}
}

__attribute__((constructor))
static void DTCoreTextNSColorInitialization(void)
{
	Class NSColorClass = objc_getClass("NSColor");
	Class NSColorMetaClass = object_getClass(NSColorClass);
	DTCoreTextAddMissingSelector(NSColorMetaClass, @selector(colorWithCGColor:), @selector(DTCoreText_colorWithCGColor:));
	DTCoreTextAddMissingSelector(NSColorClass, @selector(CGColor), @selector(DTCoreText_CGColor));
}

#define colorWithCGColor	DTCoreText_colorWithCGColor
#define CGColor				DTCoreText_CGColor
#define HTML				DTCoreText
#endif // MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_7

@implementation NSColor (HTML)

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_7 || MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_7
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
	CGColorRef color = (__bridge CGColorRef)objc_getAssociatedObject(self, DTCoreTextCGColorKey);
	if (color == NULL)
	{
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		
		NSColor *selfCopy = [self colorUsingColorSpaceName:NSDeviceRGBColorSpace];
		
		CGFloat colorValues[4];
		[selfCopy getRed:&colorValues[0] green:&colorValues[1] blue:&colorValues[2] alpha:&colorValues[3]];
		
		color = CGColorCreate(colorSpace, colorValues);
		CGColorSpaceRelease(colorSpace);
		
		objc_setAssociatedObject(self, DTCoreTextCGColorKey, CFBridgingRelease(color), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	
	return color;
}
#endif // MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_7 || MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_7

@end

#endif
