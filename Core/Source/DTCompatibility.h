//
//  DTCompatibility.h
//  DTCoreText
//
//  Created by Oliver Letterer on 09.04.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

// DTColor is UIColor on iOS, NSColor on Mac
#if TARGET_OS_IPHONE
@compatibility_alias DTColor UIColor;
#else
@compatibility_alias DTColor NSColor;
#endif

// DTImage is UIImage on iOS, NSImage on Mac
#if TARGET_OS_IPHONE
@compatibility_alias DTImage UIImage;
#else
@compatibility_alias DTImage NSImage;
#endif

// DTEdgeInsets is UIEdgeInsets on iOS, NSEdgeInsets on Mac
#if TARGET_OS_IPHONE
#define DTEdgeInsets UIEdgeInsets
#define DTEdgeInsetsMake(a, b, c, d) UIEdgeInsetsMake(a, b, c, d)
#else
#define DTEdgeInsets NSEdgeInsets
#define DTEdgeInsetsMake(a, b, c, d) NSEdgeInsetsMake(a, b, c, d)
#endif
