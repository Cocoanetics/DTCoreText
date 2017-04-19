//
//  DTCSSStylesheet.m
//  DTCoreText
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
	NSMutableDictionary *_orderedSelectorWeights;
	NSMutableArray *_orderedSelectors;
}

#pragma mark Creating Stylesheets

+ (DTCSSStylesheet *)defaultStyleSheet
{
	static DTCSSStylesheet *defaultDTCSSStylesheet = nil;
	if (defaultDTCSSStylesheet)
	{
		return defaultDTCSSStylesheet;
	}
	
	@synchronized(self)
	{
		if (!defaultDTCSSStylesheet)
		{
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
		_orderedSelectorWeights = [[NSMutableDictionary alloc] init];
		_orderedSelectors = [[NSMutableArray alloc] init];
		
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
		_orderedSelectorWeights = [[NSMutableDictionary alloc] init];
		_orderedSelectors = [[NSMutableArray alloc] init];
		
		[self mergeStylesheet:stylesheet];
	}
	
	return self;
}

#ifndef COVERAGE

- (NSString *)description
{
	return [_styles description];
	
}
#endif

#pragma mark Working with Style Blocks

- (void)_uncompressShorthands:(NSMutableDictionary *)styles
{
	// list-style shorthand
	NSString *shortHand = [[styles objectForKey:@"list-style"] lowercaseString];
	
	if (shortHand && [shortHand isKindOfClass:[NSString class]])
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
	}
	
	// font shorthand, see http://www.w3.org/TR/CSS21/fonts.html#font-shorthand
	shortHand = [styles objectForKey:@"font"];
	
	if (shortHand && [shortHand isKindOfClass:[NSString class]])
	{
		NSString *fontStyle = @"normal";
		NSArray *validFontStyles = [NSArray arrayWithObjects:@"italic", @"oblique", nil];
		
		NSString *fontVariant = @"normal";
		NSArray *validFontVariants = [NSArray arrayWithObjects:@"small-caps", nil];
		BOOL fontVariantSet = NO;
		
		NSString *fontWeight = @"normal";
		NSArray *validFontWeights = [NSArray arrayWithObjects:@"bold", @"bolder", @"lighter", @"100", @"200", @"300", @"400", @"500", @"600", @"700", @"800", @"900", nil];
		BOOL fontWeightSet = NO;
		
		NSString *fontSize = @"normal";
		NSArray *validFontSizes = [NSArray arrayWithObjects:@"xx-small", @"x-small", @"small", @"medium", @"large", @"x-large", @"xx-large", @"larger", @"smaller", nil];
		BOOL fontSizeSet = NO;
		
		NSArray *suffixesToIgnore = [NSArray arrayWithObjects:@"caption", @"icon", @"menu", @"message-box", @"small-caption", @"status-bar", @"inherit", nil];
		
		NSString *lineHeight = @"normal";
		
		NSMutableString *fontFamily = [NSMutableString string];
		
		NSArray *components = [shortHand componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		
		for (NSString *oneComponent in components)
		{
			// try font size keywords
			if ([validFontSizes containsObject:oneComponent])
			{
				fontSize = oneComponent;
				fontSizeSet = YES;
				
				continue;
			}
			
			NSInteger slashIndex = [oneComponent rangeOfString:@"/"].location;
			
			if (slashIndex != NSNotFound)
			{
				// font-size / line-height
				
				fontSize = [oneComponent substringToIndex:slashIndex];
				fontSizeSet = YES;
				
				lineHeight = [oneComponent substringFromIndex:slashIndex+1];
				
				continue;
			}
			else
			{
				// length
				if ([oneComponent hasSuffix:@"%"] || [oneComponent hasSuffix:@"em"] || [oneComponent hasSuffix:@"px"] || [oneComponent hasSuffix:@"pt"])
				{
					fontSize = oneComponent;
					fontSizeSet = YES;
					
					continue;
				}
			}
			
			if (fontSizeSet)
			{
				if ([suffixesToIgnore containsObject:oneComponent])
				{
					break;
				}
				
				// assume that this is part of font family
				if ([fontFamily length])
				{
					[fontFamily appendString:@" "];
				}
				
				[fontFamily appendString:oneComponent];
			}
			else
			{
				if (!fontWeightSet && [validFontStyles containsObject:oneComponent])
				{
					fontStyle = oneComponent;
				}
				else if (!fontVariantSet && [validFontVariants containsObject:oneComponent])
				{
					fontVariant = oneComponent;
					fontVariantSet = YES;
				}
				else if (!fontWeightSet && [validFontWeights containsObject:oneComponent])
				{
					fontWeight = oneComponent;
					fontWeightSet = YES;
				}
			}
		}
		
		[styles removeObjectForKey:@"font"];
		
		// size and family are mandatory, without them this is invalid
		if ([fontSize length] && [fontFamily length])
		{
			[styles setObject:fontStyle forKey:@"font-style"];
			[styles setObject:fontWeight forKey:@"font-weight"];
			[styles setObject:fontVariant forKey:@"font-variant"];
			[styles setObject:fontSize forKey:@"font-size"];
			[styles setObject:lineHeight forKey:@"line-height"];
			[styles setObject:fontFamily forKey:@"font-family"];
		}
	}
	
	shortHand = [styles objectForKey:@"margin"];
	
	if (shortHand && [shortHand isKindOfClass:[NSString class]])
	{
		NSArray *parts = [shortHand componentsSeparatedByString:@" "];
		
		NSString *topMargin;
		NSString *rightMargin;
		NSString *bottomMargin;
		NSString *leftMargin;
		
		if ([parts count] == 4)
		{
			topMargin = [parts objectAtIndex:0];
			rightMargin = [parts objectAtIndex:1];
			bottomMargin = [parts objectAtIndex:2];
			leftMargin = [parts objectAtIndex:3];
		}
		else if ([parts count] == 3)
		{
			topMargin = [parts objectAtIndex:0];
			rightMargin = [parts objectAtIndex:1];
			bottomMargin = [parts objectAtIndex:2];
			leftMargin = [parts objectAtIndex:1];
		}
		else if ([parts count] == 2)
		{
			topMargin = [parts objectAtIndex:0];
			rightMargin = [parts objectAtIndex:1];
			bottomMargin = [parts objectAtIndex:0];
			leftMargin = [parts objectAtIndex:1];
		}
		else
		{
			NSString *onlyValue = [parts objectAtIndex:0];
			
			topMargin = onlyValue;
			rightMargin = onlyValue;
			bottomMargin = onlyValue;
			leftMargin = onlyValue;
		}
		
		// only apply the ones where there is no previous direct setting
		
		if (![styles objectForKey:@"margin-top"])
		{
			[styles setObject:topMargin forKey:@"margin-top"];
		}
		
		if (![styles objectForKey:@"margin-right"])
		{
			[styles setObject:rightMargin forKey:@"margin-right"];
		}
		
		if (![styles objectForKey:@"margin-bottom"])
		{
			[styles setObject:bottomMargin forKey:@"margin-bottom"];
		}
		
		if (![styles objectForKey:@"margin-left"])
		{
			[styles setObject:leftMargin forKey:@"margin-left"];
		}
		
		// remove the shorthand
		[styles removeObjectForKey:@"margin"];
	}
	
	shortHand = [styles objectForKey:@"padding"];
	
	if (shortHand && [shortHand isKindOfClass:[NSString class]])
	{
		NSArray *parts = [shortHand componentsSeparatedByString:@" "];
		
		NSString *topPadding;
		NSString *rightPadding;
		NSString *bottomPadding;
		NSString *leftPadding;
		
		if ([parts count] == 4)
		{
			topPadding = [parts objectAtIndex:0];
			rightPadding = [parts objectAtIndex:1];
			bottomPadding = [parts objectAtIndex:2];
			leftPadding = [parts objectAtIndex:3];
		}
		else if ([parts count] == 3)
		{
			topPadding = [parts objectAtIndex:0];
			rightPadding = [parts objectAtIndex:1];
			bottomPadding = [parts objectAtIndex:2];
			leftPadding = [parts objectAtIndex:1];
		}
		else if ([parts count] == 2)
		{
			topPadding = [parts objectAtIndex:0];
			rightPadding = [parts objectAtIndex:1];
			bottomPadding = [parts objectAtIndex:0];
			leftPadding = [parts objectAtIndex:1];
		}
		else
		{
			NSString *onlyValue = [parts objectAtIndex:0];
			
			topPadding = onlyValue;
			rightPadding = onlyValue;
			bottomPadding = onlyValue;
			leftPadding = onlyValue;
		}
		
		// only apply the ones where there is no previous direct setting
		
		if (![styles objectForKey:@"padding-top"])
		{
			[styles setObject:topPadding forKey:@"padding-top"];
		}
		
		if (![styles objectForKey:@"padding-right"])
		{
			[styles setObject:rightPadding forKey:@"padding-right"];
		}
		
		if (![styles objectForKey:@"padding-bottom"])
		{
			[styles setObject:bottomPadding forKey:@"padding-bottom"];
		}
		
		if (![styles objectForKey:@"padding-left"])
		{
			[styles setObject:leftPadding forKey:@"padding-left"];
		}
		
		// remove the shorthand
		[styles removeObjectForKey:@"padding"];
	}

	shortHand = [styles objectForKey:@"background"];

	if (shortHand && [shortHand isKindOfClass:[NSString class]])
	{
		// ignore most tokens except background-color
		
		[styles removeObjectForKey:@"background"];
		
		NSCharacterSet *tokenDelimiters = [NSCharacterSet whitespaceAndNewlineCharacterSet];
		NSString *trimmedString = [shortHand stringByTrimmingCharactersInSet:tokenDelimiters];
		NSScanner *scanner = [NSScanner scannerWithString:trimmedString];

		while (![scanner isAtEnd])
		{
			NSString *colorName;
			if ([scanner scanHTMLColor:NULL HTMLName:&colorName])
			{
				[styles setObject:colorName forKey:@"background-color"];
				break;
			}
			[scanner scanUpToCharactersFromSet:tokenDelimiters intoString:NULL];
		}
	}
}

- (void)_addStyleRule:(NSString *)rule withSelector:(NSString*)selectors
{
	NSArray *split = [selectors componentsSeparatedByString:@","];
	
	for (NSString *selector in split)
	{
		NSString *cleanSelector = [selector stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		NSMutableDictionary *ruleDictionary = [[rule dictionaryOfCSSStyles] mutableCopy];
		
		// remove !important, we're ignoring these
		for (NSString *oneKey in [ruleDictionary allKeys])
		{
			id value = [ruleDictionary objectForKey:oneKey];
			if ([value isKindOfClass:[NSString class]])
			{
				NSRange rangeOfImportant = [value rangeOfString:@"!important" options:NSCaseInsensitiveSearch];
				
				if (rangeOfImportant.location != NSNotFound)
				{
					value = [value stringByReplacingCharactersInRange:rangeOfImportant withString:@""];
					value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
					
					[ruleDictionary setObject:value forKey:oneKey];
				}
				
			} else if ([value isKindOfClass:[NSArray class]])
			{
				NSMutableArray *newVal;
				
				for (NSUInteger i = 0; i < [(NSArray*)value count]; ++i)
				{
					NSString *s = [value objectAtIndex:i];
					
					NSRange rangeOfImportant = [s rangeOfString:@"!important" options:NSCaseInsensitiveSearch];
					
					if (rangeOfImportant.location != NSNotFound)
					{
						s = [s stringByReplacingCharactersInRange:rangeOfImportant withString:@""];
						s = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
						
						if (!newVal)
						{
							if ([value isKindOfClass:[NSMutableArray class]])
							{
								newVal = value;
							} else
							{
								newVal = [value mutableCopy];
							}
						}
						
						// replace the value that had !important with a version without it
						[newVal replaceObjectAtIndex:i withObject:s];
					}
				}
				
				if (newVal)
				{
					[ruleDictionary setObject:newVal forKey:oneKey];
				}
			}
		}
		
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
				id value = [ruleDictionary objectForKey:oneRuleKey];
				
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
			[self _addStyles:tmpDict withSelector:cleanSelector];
		}
		else
		{
			[self _addStyles:ruleDictionary withSelector:cleanSelector];
		}
	}
}


- (void)parseStyleBlock:(NSString*)css
{
	NSUInteger braceMarker = 0;
	
	NSInteger braceLevel = 0;
	
	NSString* selector;
	
	NSUInteger length = [css length];
	
	for (NSUInteger i = 0; i < length; i++)
	{
		unichar c = [css characterAtIndex:i];
		
		if (c == '/')
		{
			i++;
			
			if (i < length)
			{
				c = [css characterAtIndex:i];
				
				if (c == '*')
				{
					// skip comment until closing /
					
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
				else
				{
					// not a comment
					i--;
				}
			}
		}
		
		// An opening brace! It could be the start of a new rule, or it could be a nested brace.
		if (c == '{')
		{
			// If we start a new rule...
			
			if (braceLevel == 0)
			{
				// Grab the selector and clean up extraneous spaces (we'll process it in a moment)
				selector = [css substringWithRange:NSMakeRange(braceMarker, i-braceMarker)];
				NSArray *selectorParts = [selector componentsSeparatedByString:@" "];
				NSMutableArray *cleanSelectorParts = [NSMutableArray array];
				for (NSString *partialSelector in selectorParts)
				{
					if (partialSelector.length)
					{
						[cleanSelectorParts addObject:partialSelector];
					}
				}
				selector = [cleanSelectorParts componentsJoinedByString:@" "];
				
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
			// Skip unpaired closing brace
			else if (braceLevel < 1) {
				braceMarker += 1;	
			}
			
			braceLevel = MAX(braceLevel-1, 0);
		}
	}
}


- (void)mergeStylesheet:(DTCSSStylesheet *)stylesheet
{
	NSArray *otherStylesheetStyleKeys = stylesheet.orderedSelectors;
	
	for (NSString *oneKey in otherStylesheetStyleKeys)
	{
		NSDictionary *existingStyles = [_styles objectForKey:oneKey];
		NSDictionary *stylesToMerge = [[stylesheet styles] objectForKey:oneKey];
		if (existingStyles)
		{
			NSMutableDictionary *mutableStyles = [existingStyles mutableCopy];
			
			for (NSString *oneStyleKey in stylesToMerge)
			{
				NSString *mergingStyleString = [stylesToMerge objectForKey:oneStyleKey];
				
				[mutableStyles setObject:mergingStyleString forKey:oneStyleKey];
			}
			
			[self _addStyles:mutableStyles withSelector:oneKey];
		}
		else
		{
			// nothing to worry
			[self _addStyles:stylesToMerge withSelector:oneKey];
		}
	}
}

- (void)_addStyles:(NSDictionary *)styles withSelector:(NSString *)selector {
	[_styles setObject:styles forKey:selector];
	
	if (![_orderedSelectors containsObject:selector])
	{
		[_orderedSelectors addObject:selector];
		[_orderedSelectorWeights setObject:@([self _weightForSelector:selector]) forKey:selector];
	}
}

#pragma mark Accessing Style Information

- (NSDictionary *)mergedStyleDictionaryForElement:(DTHTMLElement *)element matchedSelectors:(NSSet * __autoreleasing*)matchedSelectors ignoreInlineStyle:(BOOL)ignoreInlineStyle
{
	// We are going to combine all the relevant styles for this tag.
	// (Note that when styles are applied, the later styles take precedence,
	//  so the order in which we grab them matters!)
	
	NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
	
	// Get based on element
	NSDictionary *byTagName = [self.styles objectForKey:element.name];
	
	if (byTagName)
	{
		[tmpDict addEntriesFromDictionary:byTagName];
	}
	
    // Get based on class(es)
	NSString *classString = [element.attributes objectForKey:@"class"];
	NSArray *classes = [classString componentsSeparatedByString:@" "];
	
	// Cascaded selectors with more than one part are sorted by specificity
	NSMutableArray *matchingCascadingSelectors = [self matchingComplexCascadingSelectorsForElement:element];
	[matchingCascadingSelectors sortUsingComparator:^NSComparisonResult(NSString *selector1, NSString *selector2)
	 {
		 NSInteger weightForSelector1 = [[_orderedSelectorWeights objectForKey:selector1] integerValue];
		 NSInteger weightForSelector2 = [[_orderedSelectorWeights objectForKey:selector2] integerValue];
		 
		 if (weightForSelector1 == weightForSelector2)
		 {
			 weightForSelector1 += [_orderedSelectors indexOfObject:selector1];
			 weightForSelector2 += [_orderedSelectors indexOfObject:selector2];
		 }
		 
		 if (weightForSelector1 > weightForSelector2)
		 {
			 return (NSComparisonResult)NSOrderedDescending;
		 }
		 
		 if (weightForSelector1 < weightForSelector2)
		 {
			 return (NSComparisonResult)NSOrderedAscending;
		 }
		 
		 return (NSComparisonResult)NSOrderedSame;
	 }];
	
	NSMutableSet *tmpMatchedSelectors;
	
	if (matchedSelectors)
	{
		tmpMatchedSelectors = [NSMutableSet set];
	}
	
	// Apply complex cascading selectors first, then apply most specific selectors
	for (NSString *cascadingSelector in matchingCascadingSelectors)
	{
		NSDictionary *byCascadingSelector = [_styles objectForKey:cascadingSelector];
		[tmpDict addEntriesFromDictionary:byCascadingSelector];
		[tmpMatchedSelectors addObject:cascadingSelector];
	}
	
	// Applied the parameter element's classes last
	for (NSString *class in classes)
	{
		NSString *classRule = [NSString stringWithFormat:@".%@", class];
		NSDictionary *byClass = [_styles objectForKey: classRule];
		
		if (byClass)
		{
			[tmpDict addEntriesFromDictionary:byClass];
			[tmpMatchedSelectors addObject:class];
		}
		
		NSString *classAndTagRule = [NSString stringWithFormat:@"%@.%@", element.name, class];
		NSDictionary *byClassAndName = [_styles objectForKey:classAndTagRule];
		
		if (byClassAndName)
		{
			[tmpDict addEntriesFromDictionary:byClassAndName];
			[tmpMatchedSelectors addObject:classAndTagRule];
		}
	}
	
	// Get based on id
	NSString *idRule = [NSString stringWithFormat:@"#%@", [element.attributes objectForKey:@"id"]];
	NSDictionary *byID = [_styles objectForKey:idRule];
	
	if (byID)
	{
		[tmpDict addEntriesFromDictionary:byID];
		[tmpMatchedSelectors addObject:idRule];
	}
	
	if (!ignoreInlineStyle)
	{
		// Get tag's local style attribute
		NSString *styleString = [element.attributes objectForKey:@"style"];
		
		if ([styleString length])
		{
			NSMutableDictionary *localStyles = [[styleString dictionaryOfCSSStyles] mutableCopy];
			
			// need to uncompress because otherwise we might get shorthands and non-shorthands together
			[self _uncompressShorthands:localStyles];
			
			[tmpDict addEntriesFromDictionary:localStyles];
		}
	}
	
	if ([tmpDict count])
	{
		if (matchedSelectors && [tmpMatchedSelectors count])
		{
			*matchedSelectors = [tmpMatchedSelectors copy];
		}
		
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

- (NSArray *)orderedSelectors
{
	return _orderedSelectors;
}

// This looks for cascaded selectors with more than one part to them
- (NSMutableArray *)matchingComplexCascadingSelectorsForElement:(DTHTMLElement *)element
{
	__block NSMutableArray *matchedSelectors = [NSMutableArray array];
	
	for (NSString *selector in _orderedSelectors)
	{
		// We only process the selector if our selector has more than 1 part to it (e.g. ".foo" would be skipped and ".foo .bar" would not)
	        if (![selector rangeOfString:@" "].length) {
        	    continue;
	        }
	        
		NSArray *selectorParts = [selector componentsSeparatedByString:@" "];
		
		if (selectorParts.count < 2)
		{
			continue;
		}
		
		DTHTMLElement *nextElement = element;
		
		// Walking up the hierarchy so start at the right side of the selector and work to the left
		// Aside: Manual for loop here is faster than for in with reverseObjectEnumerator
		for (NSUInteger j = selectorParts.count; j-- > 0;)
		{
			NSString *selectorPart = [selectorParts objectAtIndex:j];
			BOOL matched = NO;
			
			if (selectorPart.length)
			{
				while (nextElement != nil)
				{
					DTHTMLElement *currentElement = nextElement;
					
					//This must be set to advance here, above all of the breaks, so the loop properly advances.
					nextElement = currentElement.parentElement;

					if ([selectorPart characterAtIndex:0] == '#')
					{
						// If we're at an id and it doesn't match the current element then the style doesn't apply
						NSString *currentElementId = [currentElement.attributes objectForKey:@"id"];
						if (currentElementId && [[selectorPart substringFromIndex:1] isEqualToString:currentElementId])
						{
							matched = YES;
							break;
						}
					} else if ([selectorPart characterAtIndex:0] == '.')
					{
						NSString *currentElementClassesString = [currentElement.attributes objectForKey:@"class"];
						NSArray *currentElementClasses = [currentElementClassesString componentsSeparatedByString:@" "];
						for (NSString *currentElementClass in currentElementClasses)
						{
							if ([currentElementClass isEqualToString:[selectorPart substringFromIndex:1]])
							{
								matched = YES;
								break;
							}
						}
						
						if (matched)
						{
							break;
						}
					} else if ([selectorPart isEqualToString:currentElement.name] && (selectorParts.count > 1))
					{
						// This condition depends on the "if (selectorParts.count < 2)" conditional above. If that's removed, we must make sure selectorParts
						// contains > 1 item for this to be matched (we want the element name alone to be matched last).
						matched = YES;
						break;
					}
					
					// break if the right most portion of the selector doesn't match the target element
					if (!matched && ([currentElement isEqual:element])) {
						break;
					}
				}
			}
			
			if (!matched)
			{
				break;
			}
			
			//Only match if we really are on the last part of the selector and all other parts have matched so far
			if (j == 0)
			{
				if (matched && ![matchedSelectors containsObject:selector])
				{
					[matchedSelectors addObject:selector];
				}
			}
		}
	}
	
	return matchedSelectors;
}

// This computes the specificity for a given selector
- (NSUInteger)_weightForSelector:(NSString *)selector {
	if ((selector == nil) || (selector.length == 0))
	{
		return 0;
	}
	
	NSUInteger weight = 0;
	
	NSArray *selectorParts = [selector componentsSeparatedByString:@" "];
	for (NSString *selectorPart in selectorParts)
	{
		if (selectorPart.length == 0) {
			continue;
		}
		
		if ([selectorPart characterAtIndex:0] == '#')
		{
			weight += 100;
		} else if ([selectorPart characterAtIndex:0] == '.')
		{
			weight += 10;
		} else {
			weight += 1;
		}
	}
	
	return weight;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
	DTCSSStylesheet *newStylesheet = [[DTCSSStylesheet allocWithZone:zone] initWithStylesheet:self];
	
	return newStylesheet;
}

@end
