//
//  DTHTMLParserTextNode.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 26.12.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTHTMLParserTextNode.h"
#import "NSString+HTML.h"

@implementation DTHTMLParserTextNode
{
	NSString *_characters;
}

- (id)initWithCharacters:(NSString *)characters
{
	self = [super init];
	
	if (self)
	{
		self.name = @"#TEXT#";
		
		_characters = characters;
		
	}
	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ content='%@'>", NSStringFromClass([self class]), _characters];
}

- (void)_appendHTMLToString:(NSMutableString *)string indentLevel:(NSUInteger)indentLevel
{
	// indent to the level
	for (int i=0; i<indentLevel; i++)
	{
		[string appendString:@"   "];
	}
	
	[string appendFormat:@"\"%@\"\n", [_characters stringByNormalizingWhitespace]];
}

#pragma mark - Properties

@synthesize characters = _characters;

@end
