//
//  NSAttributedString+SmallCaps.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 31.01.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSAttributedString (SmallCaps)

// utilities
+ (NSAttributedString *)synthesizedSmallCapsAttributedStringWithText:(NSString *)text attributes:(NSDictionary *)attributes;

@end
