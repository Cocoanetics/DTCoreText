//
//  NSAttributedStringRunDelegates.h
//  CoreTextExtensions
//
//  Created by Oliver on 14.01.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <CoreText/CoreText.h>

void embeddedObjectDeallocCallback(void *context);
CGFloat embeddedObjectGetAscentCallback(void *context);
CGFloat embeddedObjectGetDescentCallback(void *context);
CGFloat embeddedObjectGetWidthCallback(void *context);
CTRunDelegateRef createEmbeddedObjectRunDelegate(id obj);
