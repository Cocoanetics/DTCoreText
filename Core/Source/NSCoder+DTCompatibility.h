//
//  NSCoder+DTCompatibility.h
//  DTCoreText
//
//  Created by Ryan Johnson on 14/02/19.
//  Copyright (c) 2014 Drobnik.com. All rights reserved.
//

#import "DTCompatibility.h"

@interface NSCoder (DTCompatibility)

#if !TARGET_OS_IPHONE
- (void)encodeCGSize:(CGSize)size forKey:(NSString *)key;
- (CGSize)decodeCGSizeForKey:(NSString *)key;
#endif

- (void)encodeDTEdgeInsets:(DTEdgeInsets)insets forKey:(NSString *)key;
- (DTEdgeInsets)decodeDTEdgeInsetsForKey:(NSString *)key;

@end
