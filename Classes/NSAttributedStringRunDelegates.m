//
//  NSAttributedStringRunDelegates.m
//  CoreTextExtensions
//
//  Created by Oliver on 14.01.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "NSAttributedStringRunDelegates.h"


void embeddedObjectDeallocCallback(void *context)
{
    NSLog(@"Deallocation being set %@", context);
}

CGFloat embeddedObjectGetAscentCallback(void *context)
{
    NSLog(@"Ascent being set");
    return 0;
}
CGFloat embeddedObjectGetDescentCallback(void *context)
{
    NSLog(@"Descent being set");
    return 100;
}

CGFloat embeddedObjectGetWidthCallback(void *context)
{
    NSLog(@"Width being set");
    return 10;
}

CTRunDelegateRef createEmbeddedObjectRunDelegate(void *context)
{
	CTRunDelegateCallbacks callbacks;
	callbacks.version = kCTRunDelegateCurrentVersion;
	callbacks.dealloc = embeddedObjectDeallocCallback;
	callbacks.getAscent = embeddedObjectGetAscentCallback;
	callbacks.getDescent = embeddedObjectGetDescentCallback;
	callbacks.getWidth = embeddedObjectGetWidthCallback;
	return CTRunDelegateCreate(&callbacks, context);
}