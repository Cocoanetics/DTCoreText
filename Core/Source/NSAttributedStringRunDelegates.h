//
//  NSAttributedStringRunDelegates.h
//  DTCoreText
//
//  Created by Oliver on 14.01.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCompatibility.h"

#import <CoreGraphics/CoreGraphics.h>

#if TARGET_OS_IPHONE
#import <CoreText/CoreText.h>
#elif TARGET_OS_MAC
#import <ApplicationServices/ApplicationServices.h>
#endif

void embeddedObjectDeallocCallback(void *context);
CGFloat embeddedObjectGetAscentCallback(void *context);
CGFloat embeddedObjectGetDescentCallback(void *context);
CGFloat embeddedObjectGetWidthCallback(void *context);
CTRunDelegateRef createEmbeddedObjectRunDelegate(id obj);
