//
//  NSCharacterSet+HTML.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/15/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "NSCharacterSet+HTML.h"
#import "DTCoreTextConstants.h"

static NSCharacterSet *_tagNameCharacterSet = nil;
static NSCharacterSet *_ignorableWhitespaceCharacterSet = nil;
static NSCharacterSet *_tagAttributeNameCharacterSet = nil;
static NSCharacterSet *_quoteCharacterSet = nil;
static NSCharacterSet *_nonQuotedAttributeEndCharacterSet = nil;
static NSCharacterSet *_cssStyleAttributeNameCharacterSet = nil;
static NSCharacterSet *_cssLengthValueCharacterSet = nil;
static NSCharacterSet *_cssLengthUnitCharacterSet = nil;



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

+ (NSCharacterSet *)ignorableWhitespaceCharacterSet
{
	static dispatch_once_t predicate;
	
	dispatch_once(&predicate, ^{
		NSMutableCharacterSet *tmpSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
		
		// remove all special unicode space characters
		[tmpSet removeCharactersInString:UNICODE_NON_BREAKING_SPACE];
		[tmpSet removeCharactersInString:UNICODE_OGHAM_SPACE_MARK];
		[tmpSet removeCharactersInString:UNICODE_MONGOLIAN_VOWEL_SEPARATOR];
		[tmpSet removeCharactersInString:UNICODE_EN_QUAD];
		[tmpSet removeCharactersInString:UNICODE_EM_QUAD];
		[tmpSet removeCharactersInString:UNICODE_EN_SPACE];
		[tmpSet removeCharactersInString:UNICODE_EM_SPACE];
		[tmpSet removeCharactersInString:UNICODE_THREE_PER_EM_SPACE];
		[tmpSet removeCharactersInString:UNICODE_FOUR_PER_EM_SPACE];
		[tmpSet removeCharactersInString:UNICODE_SIX_PER_EM_SPACE];
		[tmpSet removeCharactersInString:UNICODE_FIGURE_SPACE];
		[tmpSet removeCharactersInString:UNICODE_PUNCTUATION_SPACE];
		[tmpSet removeCharactersInString:UNICODE_THIN_SPACE];
		[tmpSet removeCharactersInString:UNICODE_HAIR_SPACE];
		[tmpSet removeCharactersInString:UNICODE_ZERO_WIDTH_SPACE];
		[tmpSet removeCharactersInString:UNICODE_NARROW_NO_BREAK_SPACE];
		[tmpSet removeCharactersInString:UNICODE_MEDIUM_MATHEMATICAL_SPACE];
		[tmpSet removeCharactersInString:UNICODE_IDEOGRAPHIC_SPACE];
		[tmpSet removeCharactersInString:UNICODE_ZERO_WIDTH_NO_BREAK_SPACE];

		_ignorableWhitespaceCharacterSet = [tmpSet copy];
	});
	
	return _ignorableWhitespaceCharacterSet;
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


+ (NSCharacterSet *)cssLengthValueCharacterSet
{
	static dispatch_once_t predicate;
	
	dispatch_once(&predicate, ^{
		_cssLengthValueCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@".0123456789"];
	});
	return _cssLengthValueCharacterSet;
}

+ (NSCharacterSet *)cssLengthUnitCharacterSet
{
	static dispatch_once_t predicate;
	
	dispatch_once(&predicate, ^{
		_cssLengthUnitCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"pxtem"];
	});
	return _cssLengthUnitCharacterSet;
}

@end
