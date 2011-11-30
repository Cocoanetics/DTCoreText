//
//  NSString+UTF8Cleaner.h
//  CoreTextExtensions
//
//  Created by John Engelhart on 6/26/11.
//  Copyright 2011 Scribd Inc. All rights reserved.
//

#import <Foundation/NSString.h>

@interface NSString (MalformedUTF8Additions)
- (id)initWithPotentiallyMalformedUTF8Data:(NSData *)data;
@end
