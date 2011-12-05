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
static NSCharacterSet *_cssStyleAttributeNameCharacterSet = nil;


@implementation NSCharacterSet (HTML)

+ (NSCharacterSet *)tagNameCharacterSet
{
	static dispatch_once_t predicate;

	dispatch_once(&predicate, ^{
		_tagNameCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"];
	});
	
	return _tagNameCharacterSet;
}

+ (NSCharacterSet *)tagAttributeNameCharacterSet
{
	static dispatch_once_t predicate;

	dispatch_once(&predicate, ^{
		_tagAttributeNameCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"-_:abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"];
	});
	
	return _tagAttributeNameCharacterSet;
}

+ (NSCharacterSet *)quoteCharacterSet
{
	static dispatch_once_t predicate;

	dispatch_once(&predicate, ^{
		_quoteCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"'\""];
	});
	
	return _quoteCharacterSet;
}

+ (NSCharacterSet *)nonQuotedAttributeEndCharacterSet
{
	static dispatch_once_t predicate;

	dispatch_once(&predicate, ^{
		NSMutableCharacterSet *tmpCharacterSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"/>"];
		[tmpCharacterSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		_nonQuotedAttributeEndCharacterSet = [tmpCharacterSet copy];
	});
	
	return _nonQuotedAttributeEndCharacterSet;
}

// NOTE: cannot contain : because otherwise this messes up parsing of CSS style attributes
+ (NSCharacterSet *)cssStyleAttributeNameCharacterSet
{
	static dispatch_once_t predicate;

	dispatch_once(&predicate, ^{
		_cssStyleAttributeNameCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"-_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"];
	});	
	return _cssStyleAttributeNameCharacterSet;
}

@end
