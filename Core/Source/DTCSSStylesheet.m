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
#import "NSScanner+HTML.h"
#import "NSString+CSS.h"
#import "NSString+HTML.h"


// external symbols generated via custom build rule and xxd
extern unsigned char default_css[];
extern unsigned int default_css_len;


@implementation DTCSSStylesheet
{
	NSMutableDictionary *_styles;
}

#pragma mark Creating Stylesheets

+ (DTCSSStylesheet *)defaultStyleSheet
{
	static DTCSSStylesheet *defaultDTCSSStylesheet = nil;
	if (defaultDTCSSStylesheet != nil) {
		return defaultDTCSSStylesheet;
	}
	
	@synchronized(self) {
		if (defaultDTCSSStylesheet == nil) {
			// get the data from the external symbol
			NSData *data = [NSData dataWithBytes:default_css length:default_css_len];
			NSString *cssString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
			
			defaultDTCSSStylesheet = [[DTCSSStylesheet alloc] initWithStyleBlock:cssString];
		}
	}
	return defaultDTCSSStylesheet;
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
		_styles	= [[NSMutableDictionary alloc] init];	

		[self mergeStylesheet:stylesheet];
	}
	
	return self;
}

- (NSString *)description
{
	return [_styles description];
}

#pragma mark Working with Style Blocks

- (void)_uncompressShorthands:(NSMutableDictionary *)styles
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
		
		DTCSSListStyleType listStyleType = DTCSSListStyleTypeNone;
		DTCSSListStylePosition listStylePosition = DTCSSListStylePositionInherit;
		
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
				
				if (listStyleType != DTCSSListStyleTypeInvalid)
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
				
				if (listStylePosition != DTCSSListStylePositionInvalid)
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

- (void)_addStyleRule:(NSString *)rule withSelector:(NSString*)selectors
{
	NSArray *split = [selectors componentsSeparatedByString:@","];
	
	for (NSString *selector in split) 
	{
		NSString *cleanSelector = [selector stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		NSMutableDictionary *ruleDictionary = [[rule dictionaryOfCSSStyles] mutableCopy];

		// need to uncompress because otherwise we might get shorthands and non-shorthands together
		[self _uncompressShorthands:ruleDictionary];

		// check if there is a pseudo selector
		NSRange colonRange = [cleanSelector rangeOfString:@":"];
		NSString *pseudoSelector = nil;
		
		if (colonRange.length==1)
		{
			pseudoSelector = [cleanSelector substringFromIndex:colonRange.location+1];
			cleanSelector = [cleanSelector substringToIndex:colonRange.location];
			
			// prefix all rules with the pseudo-selector
			for (NSString *oneRuleKey in [ruleDictionary allKeys])
			{
				// remove double quotes 
				NSString *value = [ruleDictionary objectForKey:oneRuleKey];
				
				if ([value hasPrefix:@"\""] && [value hasSuffix:@"\""])
				{
					// treat as HTML string, remove quotes
					NSRange range = NSMakeRange(1, [value length]-2);
					
					value = [[value substringWithRange:range] stringByAddingHTMLEntities];
				}
				
				// prefix key with the pseudo selector
				NSString *prefixedKey = [NSString stringWithFormat:@"%@:%@", pseudoSelector, oneRuleKey];
				[ruleDictionary setObject:value forKey:prefixedKey];
				[ruleDictionary removeObjectForKey:oneRuleKey];
			}
		}
		
		NSDictionary *existingRulesForSelector = [_styles objectForKey:cleanSelector];
		
		if (existingRulesForSelector) 
		{
			// substitute new rules over old ones
			NSMutableDictionary *tmpDict = [existingRulesForSelector mutableCopy];
			
			// append new rules
			[tmpDict addEntriesFromDictionary:ruleDictionary];

			// save it
			[_styles setObject:tmpDict forKey:cleanSelector];
		}
		else 
		{
			[_styles setObject:ruleDictionary forKey:cleanSelector];
		}
	}
}


- (void)parseStyleBlock:(NSString*)css
{
	NSUInteger braceLevel = 0, braceMarker = 0;
	
	NSString* selector;
	
	NSUInteger length = [css length];
	
	for (NSUInteger i = 0; i < length; i++) {
		
		unichar c = [css characterAtIndex:i];
		
		if (c == '/')
		{
			i++;
			// skip until closing /
			
			for (; i < length; i++)
			{
				if ([css characterAtIndex:i] == '/')
				{
					break;
				}
			}
			
			if (i < length)
			{
				braceMarker = i+1;
				continue;
			}
			else
			{
				// end of string
				return;
			}
		}
		
		
		// An opening brace! It could be the start of a new rule, or it could be a nested brace.
		if (c == '{') {
			
			// If we start a new rule...
			
			if (braceLevel == 0) 
			{
				// Grab the selector (we'll process it in a moment)
				selector = [css substringWithRange:NSMakeRange(braceMarker, i-braceMarker)];
				
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
				
				[self _addStyleRule:rule withSelector: selector];
				
				braceMarker = i + 1;
			}
			
			braceLevel = MAX(braceLevel-1, 0ul);
		}
	}
}


- (void)mergeStylesheet:(DTCSSStylesheet *)stylesheet
{
	[_styles addEntriesFromDictionary:[stylesheet styles]];
}

#pragma mark Accessing Style Information

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
		[self _uncompressShorthands:localStyles];
		
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

- (NSDictionary *)styles
{
	return _styles;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
	DTCSSStylesheet *newStylesheet = [[DTCSSStylesheet allocWithZone:zone] initWithStylesheet:self];
	
	return newStylesheet;
}

@end
