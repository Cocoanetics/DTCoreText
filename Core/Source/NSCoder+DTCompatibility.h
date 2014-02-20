//
//  NSCoder+DTCompatibility.h
//  DTCoreText
//
//  Created by Ryan Johnson on 14/02/19.
//  Copyright (c) 2014 Drobnik.com. All rights reserved.
//

#import "DTCompatibility.h"

@interface NSCoder (DTCompatibility)

- (void)encodeDTEdgeInsets:(DTEdgeInsets)insets forKey:(NSString *)key;
- (DTEdgeInsets)decodeDTEdgeInsetsForKey:(NSString *)key;

@end
