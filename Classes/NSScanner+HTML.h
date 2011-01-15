//
//  NSScanner+HTML.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/12/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

@interface NSScanner (HTML)

- (NSString *)peekNextTagSkippingClosingTags:(BOOL)skipClosingTags;

@end
