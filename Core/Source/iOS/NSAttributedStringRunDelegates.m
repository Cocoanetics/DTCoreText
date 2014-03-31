//
//  NSAttributedStringRunDelegates.m
//  DTCoreText
//
//  Created by Oliver on 14.01.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "NSAttributedStringRunDelegates.h"
#import "DTTextAttachment.h"


void embeddedObjectDeallocCallback(void *context)
{
}

CGFloat embeddedObjectGetAscentCallback(void *context)
{
	if ([(__bridge id)context isKindOfClass:[DTTextAttachment class]])
	{
		return [(__bridge DTTextAttachment *)context ascentForLayout];
	}
	return 0;
}
CGFloat embeddedObjectGetDescentCallback(void *context)
{
	if ([(__bridge id)context isKindOfClass:[DTTextAttachment class]])
	{
		return [(__bridge DTTextAttachment *)context descentForLayout];
	}
	return 0;
}

CGFloat embeddedObjectGetWidthCallback(void * context)
{
	if ([(__bridge id)context isKindOfClass:[DTTextAttachment class]])
	{
		return [(__bridge DTTextAttachment *)context displaySize].width;
	}
	return 35;
}

CTRunDelegateRef createEmbeddedObjectRunDelegate(id obj)
{
	CTRunDelegateCallbacks callbacks;
	callbacks.version = kCTRunDelegateCurrentVersion;
	callbacks.dealloc = embeddedObjectDeallocCallback;
	callbacks.getAscent = embeddedObjectGetAscentCallback;
	callbacks.getDescent = embeddedObjectGetDescentCallback;
	callbacks.getWidth = embeddedObjectGetWidthCallback;
	return CTRunDelegateCreate(&callbacks, (__bridge void *)obj);
	return NULL;
}
