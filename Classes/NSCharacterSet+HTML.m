//
//  NSCharacterSet+HTML.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/15/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "NSCharacterSet+HTML.h"

#ifndef DT_USE_THREAD_SAFE_INITIALIZATION
#ifndef DT_USE_THREAD_SAFE_INITIALIZATION_NOT_AVAILABLE
#warning Thread safe initialization is not enabled.
#endif
#endif

static NSCharacterSet *_tagNameCharacterSet = nil;
static NSCharacterSet *_tagAttributeNameCharacterSet = nil;
static NSCharacterSet *_quoteCharacterSet = nil;
static NSCharacterSet *_nonQuotedAttributeEndCharacterSet = nil;

@implementation NSCharacterSet (HTML)

+ (NSCharacterSet *)tagNameCharacterSet
{
#ifdef DT_USE_THREAD_SAFE_INITIALIZATION
	static dispatch_once_t predicate;
	dispatch_once(&predicate, ^{
		_tagNameCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"] retain];
	});
#else
	if (!_tagNameCharacterSet)
	{
		_tagNameCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"] retain];
	}
#endif
	
	return _tagNameCharacterSet;
}

+ (NSCharacterSet *)tagAttributeNameCharacterSet
{
#ifdef DT_USE_THREAD_SAFE_INITIALIZATION
	static dispatch_once_t predicate;
	dispatch_once(&predicate, ^{
		_tagAttributeNameCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"-_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"] retain];
	});
#else
	if (!_tagAttributeNameCharacterSet)
	{
		_tagAttributeNameCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"-_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"] retain];
	}
#endif
	
	return _tagAttributeNameCharacterSet;
}

+ (NSCharacterSet *)quoteCharacterSet
{
#ifdef DT_USE_THREAD_SAFE_INITIALIZATION
	static dispatch_once_t predicate;
	dispatch_once(&predicate, ^{
		_quoteCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"'\""] retain];
	});
#else
	if (!_quoteCharacterSet)
	{
		_quoteCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"'\""] retain];
	}
#endif
	
	return _quoteCharacterSet;
}

+ (NSCharacterSet *)nonQuotedAttributeEndCharacterSet
{
#ifdef DT_USE_THREAD_SAFE_INITIALIZATION
	static dispatch_once_t predicate;
	dispatch_once(&predicate, ^{
		NSMutableCharacterSet *tmpCharacterSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"/>"];
		[tmpCharacterSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		_nonQuotedAttributeEndCharacterSet = [tmpCharacterSet copy];
	});
#else
	if (!_nonQuotedAttributeEndCharacterSet)
	{
		NSMutableCharacterSet *tmpCharacterSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"/>"];
		[tmpCharacterSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		_nonQuotedAttributeEndCharacterSet = [tmpCharacterSet copy];
	}
#endif
	
	return _nonQuotedAttributeEndCharacterSet;
}



@end
