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

#ifdef __cplusplus
extern "C" {
#endif

void embeddedObjectDeallocCallback(void *_Nullable context);
CGFloat embeddedObjectGetAscentCallback(void *_Nullable context);
CGFloat embeddedObjectGetDescentCallback(void *_Nullable context);
CGFloat embeddedObjectGetWidthCallback(void *_Nullable context);
CTRunDelegateRef _Nullable createEmbeddedObjectRunDelegate(id _Nullable obj);

#ifdef __cplusplus
}
#endif
