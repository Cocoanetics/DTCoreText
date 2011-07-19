//
//  NSCharacterSet+HTML.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/15/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSCharacterSet (HTML)

+ (NSCharacterSet *)tagNameCharacterSet;
+ (NSCharacterSet *)tagAttributeNameCharacterSet;
+ (NSCharacterSet *)quoteCharacterSet;
+ (NSCharacterSet *)nonQuotedAttributeEndCharacterSet;
+ (NSCharacterSet *)cssStyleAttributeNameCharacterSet;

@end
