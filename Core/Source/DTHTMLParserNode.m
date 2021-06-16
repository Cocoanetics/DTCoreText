//
//  DTHTMLParserNode.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 26.12.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTHTMLParserNode.h"
#import "DTHTMLParserTextNode.h"
#import <DTFoundation/DTWeakSupport.h>

@implementation DTHTMLParserNode
{
	NSString *_name;
	DT_WEAK_VARIABLE DTHTMLParserNode *_parentNode;
	NSMutableArray *_childNodes;
}


- (id)initWithName:(NSString *)name attributes:(NSDictionary *)attributes
{
	self = [super init];
	
	if (self)
	{
		_name = [name copy];
		[self setAttributes:attributes]; // property to allow overriding
	}
	
	return self;
}

- (void)addChildNode:(DTHTMLParserNode *)childNode
{
	@synchronized(self)
	{
		// first child creates array
		if (!_childNodes)
		{
			_childNodes = [[NSMutableArray alloc] init];
		}
		
		childNode.parentNode = self;
		[_childNodes addObject:childNode];
	}
}

- (void)removeChildNode:(DTHTMLParserNode *)childNode
{
	@synchronized(self)
	{
		[_childNodes removeObject:childNode];
	}
}

- (void)removeAllChildNodes
{
	@synchronized(self)
	{
		[_childNodes removeAllObjects];
	}
}

#ifndef COVERAGE
// exclude methods from coverage testing

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ name='%@'>", NSStringFromClass([self class]), _name];
}

#endif

- (void)_appendHTMLToString:(NSMutableString *)string indentLevel:(NSUInteger)indentLevel
{
	@synchronized(self)
	{
		// indent to the level
		for (NSUInteger i=0; i<indentLevel; i++)
		{
			[string appendString:@"   "];
		}
		
		// write own name tag open
		[string appendFormat:@"<%@", _name];
		
		// sort attribute names
		NSArray *sortedKeys = [_attributes.allKeys sortedArrayUsingSelector:@selector(compare:)];
		
		for (NSString *oneKey in sortedKeys)
		{
			NSString *attribute = [_attributes objectForKey:oneKey];
			[string appendFormat:@" %@=\"%@\"", oneKey, attribute];
		}
		
		if (![_childNodes count])
		{
			[string appendString:@" \\>\n"];
			return;
		}
		
		[string appendFormat:@">\n"];
		
		// output attributes
		for (DTHTMLParserNode *childNode in _childNodes)
		{
			[childNode _appendHTMLToString:string indentLevel:indentLevel+1];
		}
		
		// indent to the level
		for (NSUInteger i=0; i<indentLevel; i++)
		{
			[string appendString:@"   "];
		}
		
		// write own name tag close
		[string appendFormat:@"</%@>\n", _name];
	}
}

- (NSString *)debugDescription
{
	@synchronized(self)
	{
		NSMutableString *tmpString = [NSMutableString string];
		
		[self _appendHTMLToString:tmpString indentLevel:0];
		
		return tmpString;
	}
}

- (NSString *)text
{
	@synchronized(self)
	{
		NSMutableString *text = [NSMutableString string];
		
		for (DTHTMLParserTextNode *oneChild in self.childNodes)
		{
			if ([oneChild isKindOfClass:[DTHTMLParserTextNode class]])
			{
				[text appendString:[oneChild characters]];
			}
		}
		
		return text;
	}
}

#pragma mark - Properties

- (NSArray *)childNodes
{
	@synchronized(self)
	{
		return _childNodes;
	}
}

@synthesize name = _name;
@synthesize attributes = _attributes;
@synthesize parentNode = _parentNode;
@synthesize childNodes = _childNodes;

@end
