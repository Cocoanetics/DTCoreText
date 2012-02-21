//
//  NSAttributedString+HTML.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

@class NSAttributedString;

@interface NSAttributedString (HTML)

- (id)initWithHTML:(NSData *)data documentAttributes:(NSDictionary **)dict;
- (id)initWithHTML:(NSData *)data baseURL:(NSURL *)base documentAttributes:(NSDictionary **)dict;
- (id)initWithHTML:(NSData *)data options:(NSDictionary *)options documentAttributes:(NSDictionary **)dict;

@end
