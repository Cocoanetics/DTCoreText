//
//  NSString+HTML.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (HTML)

- (NSDictionary *)dictionaryOfAttributesFromTag;
- (NSUInteger)integerValueFromHex;

@end
