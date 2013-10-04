//
//  NSAttributedString+DTTextAttachment.m
//  DTCoreText
//
//  Created by Dominik Pich on 04.10.13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//
#import "DTCoreText.h"
#import "NSAttributedString+DTTextAttachment.h"

@implementation NSAttributedString (DTTextAttachment)

+ (instancetype)attributedStringWithDTTextAttachment:(DTTextAttachment*)attachment {
    NSMutableDictionary *mAttributes = [NSMutableDictionary dictionary];

    [mAttributes setObject:attachment forKey:NSAttachmentAttributeName];
    
#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES && TARGET_OS_IPHONE
    // need run delegate for sizing
    CTRunDelegateRef embeddedObjectRunDelegate = createEmbeddedObjectRunDelegate(attachment);
    [mAttributes setObject:CFBridgingRelease(embeddedObjectRunDelegate) forKey:(id)kCTRunDelegateAttributeName];
#endif
    
    NSString *s = [NSString stringWithCharacters:(unichar*)NSAttachmentCharacter length:1];
    return [[NSAttributedString alloc] initWithString:s attributes:mAttributes];
}

@end
