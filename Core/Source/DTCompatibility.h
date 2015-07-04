//
//  DTCompatibility.h
//  DTCoreText
//
//  Created by Oliver Letterer on 09.04.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#pragma mark - iOS

#if TARGET_OS_IPHONE

	// Compatibility Aliases
	#define DTColor UIColor
	#define DTImage UIImage
	#define DTFont UIFont

	// Edge Insets
	#define DTEdgeInsets UIEdgeInsets
	#define DTEdgeInsetsMake(top, left, bottom, right) UIEdgeInsetsMake(top, left, bottom, right)

	// NS-style text attributes are possible with iOS SDK 6.0 or higher
	#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_5_1
		#define DTCORETEXT_SUPPORT_NS_ATTRIBUTES 1
	#endif

	// NSParagraphStyle supports tabs as of iOS SDK 7.0 or higher
	#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_6_1
		#define DTCORETEXT_SUPPORT_NSPARAGRAPHSTYLE_TABS 1
	#endif

	// iOS before 5.0 has leak in CoreText replacing attributes
	#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_5_0
		#define DTCORETEXT_NEEDS_ATTRIBUTE_REPLACEMENT_LEAK_FIX 1
	#endif

	// iOS 7 bug (rdar://14684188) workaround, can be removed once this bug is fixed
	#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_6_1
		#define DTCORETEXT_FIX_14684188 1
	#endif

	// constant for checking for iOS 6
	#define DTNSFoundationVersionNumber_iOS_6_0  992.00

	// constant for checking for iOS 7
	#define DTNSFoundationVersionNumber_iOS_7_0  1047.00


	// runtime-check if NS-style attributes are allowed
	static inline BOOL DTCoreTextModernAttributesPossible()
	{
#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES
		if (floor(NSFoundationVersionNumber) >= DTNSFoundationVersionNumber_iOS_6_0)
		{
			return YES;
		}
#endif
		return NO;
	}

	// runtime-check if CoreText draws underlines
	static inline BOOL DTCoreTextDrawsUnderlinesWithGlyphs()
	{
		if (floor(NSFoundationVersionNumber) >= DTNSFoundationVersionNumber_iOS_7_0)
		{
			return YES;
		}
	
		return NO;
	}

#if TARGET_CPU_ARM64 || TARGET_CPU_X86_64
	#define DTNSNumberFromCGFloat(x) [NSNumber numberWithDouble:x]
#else
	#define DTNSNumberFromCGFloat(x) [NSNumber numberWithFloat:x]
#endif

#endif


#pragma mark - Mac


#if !TARGET_OS_IPHONE

	// Compatibility Aliases
	#define DTColor NSColor
	#define DTImage NSImage
	#define DTFont NSFont

	// Edge Insets
	#define DTEdgeInsets NSEdgeInsets
	#define DTEdgeInsetsMake(top, left, bottom, right) NSEdgeInsetsMake(top, left, bottom, right)

	// Mac supports NS-Style Text Attributes since 10.0
	#define DTCORETEXT_SUPPORT_NS_ATTRIBUTES 1
	#define DTCORETEXT_SUPPORT_NSPARAGRAPHSTYLE_TABS 1

	// theoretically MacOS before 10.8 might have a leak in CoreText replacing attributes
	#if __MAC_OS_X_VERSION_MIN_REQUIRED < __MAC_10_7
		#define DTCORETEXT_NEEDS_ATTRIBUTE_REPLACEMENT_LEAK_FIX 1
	#endif

	// NSValue has sizeValue on Mac, CGSizeValue on iOS
	#define CGSizeValue sizeValue

	// String functions named differently on Mac
	static inline NSString *NSStringFromCGRect(const CGRect rect)
	{
		return NSStringFromRect(NSRectFromCGRect(rect));
	}

	static inline NSString *NSStringFromCGSize(const CGSize size)
	{
		return NSStringFromSize(NSSizeFromCGSize(size));
	}

	static inline NSString *NSStringFromCGPoint(const CGPoint point)
	{
		return NSStringFromPoint(NSPointFromCGPoint(point));
	}

	// runtime-check if NS-style attributes are allowed
	static inline BOOL DTCoreTextModernAttributesPossible()
	{
		return YES;
	}

	// runtime-check if CoreText draws underlines
	static inline BOOL DTCoreTextDrawsUnderlinesWithGlyphs()
	{
		return NO;
	}

	#define DTNSNumberFromCGFloat(x) [NSNumber numberWithDouble:x]
#endif

// this enables generic ceil, floor, abs, round functions that work for 64 and 32 bit
#include <tgmath.h>
