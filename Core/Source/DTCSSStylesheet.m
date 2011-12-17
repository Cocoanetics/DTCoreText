//
//  DTCSSStylesheet.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 9/5/11.
//  Copyright (c) 2011 Drobnik.com. All rights reserved.
//

#import "DTCSSStylesheet.h"
#import "DTCSSListStyle.h"

#import "DTHTMLElement.h"
#import "NSString+HTML.h"
#import "NSScanner+HTML.h"


@interface DTCSSStylesheet ()

@property (nonatomic, strong) NSMutableDictionary *styles;

@end


@implementation DTCSSStylesheet
{
	NSMutableDictionary *_styles;
	
}

- (id)initWithStyleBlock:(NSString *)css
{
	self = [super init];
	
	if (self)
	{
		_styles	= [[NSMutableDictionary alloc] init];	
		
		[self parseStyleBlock:css];
	}
	
	return self;
}

- (id)initWithStylesheet:(DTCSSStylesheet *)stylesheet
{
	self = [super init];
	
	if (self)
	{
		[self mergeStylesheet:stylesheet];
	}
	
	return self;
}

- (NSString *)description
{
	return [_styles description];
}

- (void)uncompressShorthands:(NSMutableDictionary *)styles
{
	NSString *shortHand = [[styles objectForKey:@"list-style"] lowercaseString];
	
	if (shortHand)
	{
		[styles removeObjectForKey:@"list-style"];
		
		if ([shortHand isEqualToString:@"inherit"])
		{
			[styles setObject:@"inherit" forKey:@"list-style-type"];
			[styles setObject:@"inherit" forKey:@"list-style-position"];
			return;
		}
		
		NSArray *components = [shortHand componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		
		BOOL typeWasSet = NO;
		BOOL positionWasSet = NO;
		
		DTCSSListStyleType listStyleType = NSNotFound;
		DTCSSListStylePosition listStylePosition = NSNotFound;
		
		for (NSString *oneComponent in components)
		{
			if ([oneComponent hasPrefix:@"url"])
			{
				// list-style-image
				NSScanner *scanner = [NSScanner scannerWithString:oneComponent];
				
				if ([scanner scanCSSURL:NULL])
				{
					[styles setObject:oneComponent forKey:@"list-style-image"];
					
					continue;
				}
			}
			
			if (!typeWasSet)
			{
				// check if valid type
				listStyleType = [DTCSSListStyle listStyleTypeFromString:oneComponent];
				
				if (listStyleType != NSNotFound)
				{
					[styles setObject:oneComponent forKey:@"list-style-type"];
					
					typeWasSet = YES;
					continue;
				}
			}
			
			if (!positionWasSet)
			{
				// check if valid position
				listStylePosition = [DTCSSListStyle listStylePositionFromString:oneComponent];
				
				if (listStylePosition != NSNotFound)
				{
					[styles setObject:oneComponent forKey:@"list-style-position"];

					positionWasSet = YES;
					continue;
				}
			}
		}
		
		return;
	}
}

- (void)addStyleRule:(NSString *)rule withSelector:(NSString*)selectors
{
	NSArray *split = [selectors componentsSeparatedByString:@","];
	
	for (NSString *selector in split) 
	{
		NSString *cleanSelector = [selector stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		NSMutableDictionary *ruleDictionary = [[rule dictionaryOfCSSStyles] mutableCopy];

		// need to uncompress because otherwise we might get shorthands and non-shorthands together
		[self uncompressShorthands:ruleDictionary];
		
		NSDictionary *existingRulesForSelector = [self.styles objectForKey:cleanSelector];
		
		if (existingRulesForSelector) 
		{
			// substitute new rules over old ones
			NSMutableDictionary *tmpDict = [existingRulesForSelector mutableCopy];
			
			// append new rules
			[tmpDict addEntriesFromDictionary:ruleDictionary];

			// save it
			[self.styles setObject:tmpDict forKey:cleanSelector];
		}
		else 
		{
			[self.styles setObject:ruleDictionary forKey:cleanSelector];
		}
	}
}

- (void)parseStyleBlock:(NSString*)css
{
	int braceLevel = 0, braceMarker = 0;
	
	NSString* selector;
	
	for (int i = 0, l = [css length]; i < l; i++) {
		
		unichar c = [css characterAtIndex:i];
		
		// An opening brace! It could be the start of a new rule, or it could be a nested brace.
		
		if (c == '{') {
			
			// If we start a new rule...
			
			if (braceLevel == 0) 
			{
				// Grab the selector (we'll process it in a moment)
				selector = [css substringWithRange:NSMakeRange(braceMarker, i-braceMarker-1)];
				
				// And mark our position so we can grab the rule's CSS when it is closed
				braceMarker = i + 1;
			}
			
			// Increase the brace level.
			braceLevel += 1;
		}
		
		// A closing brace!
		else if (c == '}') 
		{
			// If we finished a rule...
			if (braceLevel == 1) 
			{
				NSString *rule = [css substringWithRange:NSMakeRange(braceMarker, i-braceMarker)];
				
				[self addStyleRule:rule withSelector: selector];
				
				braceMarker = i + 1;
			}
			
			braceLevel = MAX(braceLevel-1, 0);
		}
	}
}

- (NSDictionary *)mergedStyleDictionaryForElement:(DTHTMLElement *)element
{
	// We are going to combine all the relevant styles for this tag.
	// (Note that when styles are applied, the later styles take precedence,
	//  so the order in which we grab them matters!)

	NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
	
	// Get based on element
	NSDictionary *byTagName = [self.styles objectForKey:element.tagName];
	
	if (byTagName) 
	{
		[tmpDict addEntriesFromDictionary:byTagName];
	}
	
    // Get based on class(es)
	NSString *classString = [element attributeForKey:@"class"];
	NSArray *classes = [classString componentsSeparatedByString:@" "];
	
	for (NSString *class in classes) 
	{
		NSString *classRule = [NSString stringWithFormat:@".%@", class];
		NSString *classAndTagRule = [NSString stringWithFormat:@"%@.%@", element.tagName, class];
		
		NSDictionary *byClass = [_styles objectForKey:classRule];
		NSDictionary *byClassAndName = [_styles objectForKey:classAndTagRule];
		
		if (byClass) 
		{
			[tmpDict addEntriesFromDictionary:byClass];
		}
		
		if (byClassAndName) 
		{
			[tmpDict addEntriesFromDictionary:byClassAndName];
		}
	}
	
	// Get based on id
	NSString *idRule = [NSString stringWithFormat:@"#%@", [element attributeForKey:@"id"]];
	NSDictionary *byID = [_styles objectForKey:idRule];
	
	if (byID) 
	{
		[tmpDict addEntriesFromDictionary:byID];
	}
	
	// Get tag's local style attribute
	NSString *styleString = [element attributeForKey:@"style"];
	
	if ([styleString length])
	{
		NSMutableDictionary *localStyles = [[styleString dictionaryOfCSSStyles] mutableCopy];
		
		// need to uncompress because otherwise we might get shorthands and non-shorthands together
		[self uncompressShorthands:localStyles];
	
		[tmpDict addEntriesFromDictionary:localStyles];
	}
	
	if ([tmpDict count])
	{
		return tmpDict;
	}
	else
	{
		return nil;
	}
}

- (void)mergeStylesheet:(DTCSSStylesheet *)stylesheet
{
	[self.styles addEntriesFromDictionary:stylesheet.styles];
}


#pragma mark Properties

- (NSMutableDictionary *)styles
{
	if (!_styles)
	{
		_styles = [[NSMutableDictionary alloc] init];
	}
	
	return _styles;
}

@synthesize styles = _styles;

@end
