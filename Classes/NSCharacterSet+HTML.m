//
//  NSCharacterSet+HTML.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/15/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "NSCharacterSet+HTML.h"

static NSCharacterSet *_tagNameCharacterSet = nil;
static NSCharacterSet *_tagAttributeNameCharacterSet = nil;
static NSCharacterSet *_quoteCharacterSet = nil;
static NSCharacterSet *_nonQuotedAttributeEndCharacterSet = nil;

@implementation NSCharacterSet (HTML)

+ (NSCharacterSet *)tagNameCharacterSet
{
    if (!_tagNameCharacterSet)
    {
        _tagNameCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"] retain];
    }
    
    return _tagNameCharacterSet;
}

+ (NSCharacterSet *)tagAttributeNameCharacterSet
{
    if (!_tagAttributeNameCharacterSet)
    {
        _tagAttributeNameCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"-_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"] retain];
    }
    
    return _tagAttributeNameCharacterSet;
 }

+ (NSCharacterSet *)quoteCharacterSet
{
    if (!_quoteCharacterSet)
    {
        _quoteCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"'\""] retain];
    }
    
    return _quoteCharacterSet;
}

+ (NSCharacterSet *)nonQuotedAttributeEndCharacterSet
{
    if (!_nonQuotedAttributeEndCharacterSet)
    {
        NSMutableCharacterSet *tmpCharacterSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"/>"];
        [tmpCharacterSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        _nonQuotedAttributeEndCharacterSet = [tmpCharacterSet copy];
    }
    
    return _nonQuotedAttributeEndCharacterSet;
}



@end
