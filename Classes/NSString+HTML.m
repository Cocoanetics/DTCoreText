//
//  NSString+HTML.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "NSString+HTML.h"
#import "NSScanner+HTML.h"
#import "UIColor+HTML.h"

#ifndef DT_USE_THREAD_SAFE_INITIALIZATION
#ifndef DT_USE_THREAD_SAFE_INITIALIZATION_NOT_AVAILABLE
#warning Thread safe initialization is not enabled.
#endif
#endif

static NSSet *inlineTags = nil;
static NSSet *metaTags = nil;
static NSDictionary *entityLookup = nil;

@implementation NSString (HTML)

- (NSUInteger)integerValueFromHex 
{
	NSUInteger result = 0;
	sscanf([self UTF8String], "%x", &result);
	return result;
}

- (BOOL)isInlineTag
{
#ifdef DT_USE_THREAD_SAFE_INITIALIZATION
	static dispatch_once_t predicate;
	dispatch_once(&predicate, ^{
		inlineTags = [[NSSet alloc] initWithObjects:@"font", @"b", @"strong", @"em", @"i", @"sub", @"sup",
									@"u", @"a", @"img", @"del", @"br", @"span", nil];
	});
#else
	if (!inlineTags)
	{
		inlineTags = [[NSSet alloc] initWithObjects:@"font", @"b", @"strong", @"em", @"i", @"sub", @"sup",
									@"u", @"a", @"img", @"del", @"br", @"span", nil];
	}
#endif
	
	return [inlineTags containsObject:[self lowercaseString]];
}

- (BOOL)isMetaTag
{
#ifdef DT_USE_THREAD_SAFE_INITIALIZATION
	static dispatch_once_t predicate;
	dispatch_once(&predicate, ^{
		metaTags = [[NSSet alloc] initWithObjects:@"html", @"head", @"meta", @"style", @"#COMMENT#", @"title", nil];
	});
#else
	if (!metaTags)
	{
		metaTags = [[NSSet alloc] initWithObjects:@"html", @"head", @"meta", @"style", @"#COMMENT#", @"title", nil];
	}
#endif
	
	return [metaTags containsObject:[self lowercaseString]];
}

- (BOOL)isNumeric
{
	const char *s = [self UTF8String];
	
	for (int i=0;i<strlen(s);i++)
	{
		if (s[i]<'0' || s[i]>'9')
		{
			return NO;
		}
	}
	
	return YES;
}

- (float)percentValue
{
	float result = 1;
	sscanf([self UTF8String], "%f", &result);
	
	return result/100.0;
}

- (NSString *)stringByNormalizingWhitespace
{
	NSInteger stringLength = [self length];
	
	// reserve buffer, same size as input
	unichar *buf = malloc((stringLength) * sizeof(unichar));
	
	NSInteger outputLength = 0;
	BOOL inWhite = NO;
	
	for (NSInteger i = 0; i<stringLength; i++)
	{
		unichar oneChar = [self characterAtIndex:i];
		
		// of whitespace chars only output one space for first
		if (oneChar == 32 ||    // space
				oneChar == 10 ||    // various newlines
				oneChar == 11 ||
				oneChar == 12 ||
				oneChar == 13 ||
				oneChar == (unichar)'\t' || // tab
				oneChar == (unichar)'\x85')
		{
			if (!inWhite)
			{
				buf[outputLength] = 32;
				outputLength++;
				
				inWhite = YES;
			}
		}
		else
		{
			// all other characters we simply copy
			buf[outputLength] = oneChar;
			outputLength++;
			
			inWhite = NO;
		}
	}
	
	// convert to objC-String
	NSString *retString = [NSString stringWithCharacters:buf length:outputLength];
	
	// free buffers
	free(buf);
	
	return retString;
}

- (BOOL)hasPrefixCharacterFromSet:(NSCharacterSet *)characterSet
{
	if (![self length])
	{
		return NO;
	}
	
	unichar firstChar = [self characterAtIndex:0];
	
	return [characterSet characterIsMember:firstChar];
}

- (BOOL)hasSuffixCharacterFromSet:(NSCharacterSet *)characterSet
{
	if (![self length])
	{
		return NO;
	}
	
	unichar lastChar = [self characterAtIndex:[self length]-1];
	
	return [characterSet characterIsMember:lastChar];
}

- (NSString *)stringByReplacingHTMLEntities
{
#ifdef DT_USE_THREAD_SAFE_INITIALIZATION
	static dispatch_once_t predicate;
	dispatch_once(&predicate, ^{
		entityLookup = [[NSDictionary alloc] initWithObjectsAndKeys:@"\x22", @"quot",
										@"\x26", @"amp",
										@"\x27", @"apos",
										@"\x3c", @"lt",
										@"\x3e", @"gt",
										@"\u00a0", @"nbsp",
										@"\u00a1", @"iexcl",
										@"\u00a2", @"cent",
										@"\u00a3", @"pound",
										@"\u00a4", @"curren",
										@"\u00a5", @"yen",
										@"\u00a6", @"brvbar",
										@"\u00a7", @"sect",
										@"\u00a8", @"uml",
										@"\u00a9", @"copy",
										@"\u00aa", @"ordf",
										@"\u00ab", @"laquo",
										@"\u00ac", @"not",
										@"\u00ae", @"reg",
										@"\u00af", @"macr",
										@"\u00b0", @"deg",
										@"\u00b1", @"plusmn",
										@"\u00b2", @"sup2",
										@"\u00b3", @"sup3",
										@"\u00b4", @"acute",
										@"\u00b5", @"micro",
										@"\u00b6", @"para",
										@"\u00b7", @"middot",
										@"\u00b8", @"cedil",
										@"\u00b9", @"sup1",
										@"\u00ba", @"ordm",
										@"\u00bb", @"raquo",
										@"\u00bc", @"frac14",
										@"\u00bd", @"frac12",
										@"\u00be", @"frac34",
										@"\u00bf", @"iquest",
										@"\u00c0", @"Agrave",
										@"\u00c1", @"Aacute",
										@"\u00c2", @"Acirc",
										@"\u00c3", @"Atilde",
										@"\u00c4", @"Auml",
										@"\u00c5", @"Aring",
										@"\u00c6", @"AElig",
										@"\u00c7", @"Ccedil",
										@"\u00c8", @"Egrave",
										@"\u00c9", @"Eacute",
										@"\u00ca", @"Ecirc",
										@"\u00cb", @"Euml",
										@"\u00cc", @"Igrave",
										@"\u00cd", @"Iacute",
										@"\u00ce", @"Icirc",
										@"\u00cf", @"Iuml",
										@"\u00d0", @"ETH",
										@"\u00d1", @"Ntilde",
										@"\u00d2", @"Ograve",
										@"\u00d3", @"Oacute",
										@"\u00d4", @"Ocirc",
										@"\u00d5", @"Otilde",
										@"\u00d6", @"Ouml",
										@"\u00d7", @"times",
										@"\u00d8", @"Oslash",
										@"\u00d9", @"Ugrave",
										@"\u00da", @"Uacute",
										@"\u00db", @"Ucirc",
										@"\u00dc", @"Uuml",
										@"\u00dd", @"Yacute",
										@"\u00de", @"THORN",
										@"\u00df", @"szlig",
										@"\u00e0", @"agrave",
										@"\u00e1", @"aacute",
										@"\u00e2", @"acirc",
										@"\u00e3", @"atilde",
										@"\u00e4", @"auml",
										@"\u00e5", @"aring",
										@"\u00e6", @"aelig",
										@"\u00e7", @"ccedil",
										@"\u00e8", @"egrave",
										@"\u00e9", @"eacute",
										@"\u00ea", @"ecirc",
										@"\u00eb", @"euml",
										@"\u00ec", @"igrave",
										@"\u00ed", @"iacute",
										@"\u00ee", @"icirc",
										@"\u00ef", @"iuml",
										@"\u00f0", @"eth",
										@"\u00f1", @"ntilde",
										@"\u00f2", @"ograve",
										@"\u00f3", @"oacute",
										@"\u00f4", @"ocirc",
										@"\u00f5", @"otilde",
										@"\u00f6", @"ouml",
										@"\u00f7", @"divide",
										@"\u00f8", @"oslash",
										@"\u00f9", @"ugrave",
										@"\u00fa", @"uacute",
										@"\u00fb", @"ucirc",
										@"\u00fc", @"uuml",
										@"\u00fd", @"yacute",
										@"\u00fe", @"thorn",
										@"\u00ff", @"yuml",
										@"\u0152", @"OElig",
										@"\u0153", @"oelig",
										@"\u0160", @"Scaron",
										@"\u0161", @"scaron",
										@"\u0178", @"Yuml",
										@"\u0192", @"fnof",
										@"\u02c6", @"circ",
										@"\u02dc", @"tilde",
										@"\u0393", @"Gamma",
										@"\u0394", @"Delta",
										@"\u0398", @"Theta",
										@"\u039b", @"Lambda",
										@"\u039e", @"Xi",
										@"\u03a3", @"Sigma",
										@"\u03a5", @"Upsilon",
										@"\u03a6", @"Phi",
										@"\u03a8", @"Psi",
										@"\u03a9", @"Omega",
										@"\u03b1", @"alpha",
										@"\u03b2", @"beta",
										@"\u03b3", @"gamma",
										@"\u03b4", @"delta",
										@"\u03b5", @"epsilon",
										@"\u03b6", @"zeta",
										@"\u03b7", @"eta",
										@"\u03b8", @"theta",
										@"\u03b9", @"iota",
										@"\u03ba", @"kappa",
										@"\u03bb", @"lambda",
										@"\u03bc", @"mu",
										@"\u03bd", @"nu",
										@"\u03be", @"xi",
										@"\u03bf", @"omicron",
										@"\u03c0", @"pi",
										@"\u03c1", @"rho",
										@"\u03c2", @"sigmaf",
										@"\u03c3", @"sigma",
										@"\u03c4", @"tau",
										@"\u03c5", @"upsilon",
										@"\u03c6", @"phi",
										@"\u03c7", @"chi",
										@"\u03c8", @"psi",
										@"\u03c9", @"omega",
										@"\u03d1", @"thetasym",
										@"\u03d2", @"upsih",
										@"\u03d6", @"piv",
										@"\u2002", @"ensp",
										@"\u2003", @"emsp",
										@"\u2009", @"thinsp",
										@"\u2013", @"ndash",
										@"\u2014", @"mdash",
										@"\u2018", @"lsquo",
										@"\u2019", @"rsquo",
										@"\u201a", @"sbquo",
										@"\u201c", @"ldquo",
										@"\u201d", @"rdquo",
										@"\u201e", @"bdquo",
										@"\u2020", @"dagger",
										@"\u2021", @"Dagger",
										@"\u2022", @"bull",
										@"\u2026", @"hellip",
										@"\u2030", @"permil",
										@"\u2032", @"prime",
										@"\u2033", @"Prime",
										@"\u2039", @"lsaquo",
										@"\u203a", @"rsaquo",
										@"\u203e", @"oline",
										@"\u2044", @"frasl",
										@"\u20ac", @"euro",
										@"\u2111", @"image",
										@"\u2118", @"weierp",
										@"\u211c", @"real",
										@"\u2122", @"trade",
										@"\u2135", @"alefsym",
										@"\u2190", @"larr",
										@"\u2191", @"uarr",
										@"\u2192", @"rarr",
										@"\u2193", @"darr",
										@"\u2194", @"harr",
										@"\u21b5", @"crarr",
										@"\u21d0", @"lArr",
										@"\u21d1", @"uArr",
										@"\u21d2", @"rArr",
										@"\u21d3", @"dArr",
										@"\u21d4", @"hArr",
										@"\u2200", @"forall",
										@"\u2202", @"part",
										@"\u2203", @"exist",
										@"\u2205", @"empty",
										@"\u2207", @"nabla",
										@"\u2208", @"isin",
										@"\u2209", @"notin",
										@"\u220b", @"ni",
										@"\u220f", @"prod",
										@"\u2211", @"sum",
										@"\u2212", @"minus",
										@"\u2217", @"lowast",
										@"\u221a", @"radic",
										@"\u221d", @"prop",
										@"\u221e", @"infin",
										@"\u2220", @"ang",
										@"\u2227", @"and",
										@"\u2228", @"or",
										@"\u2229", @"cap",
										@"\u222a", @"cup",
										@"\u222b", @"int",
										@"\u2234", @"there4",
										@"\u223c", @"sim",
										@"\u2245", @"cong",
										@"\u2248", @"asymp",
										@"\u2260", @"ne",
										@"\u2261", @"equiv",
										@"\u2264", @"le",
										@"\u2265", @"ge",
										@"\u2282", @"sub",
										@"\u2283", @"sup",
										@"\u2284", @"nsub",
										@"\u2286", @"sube",
										@"\u2287", @"supe",
										@"\u2295", @"oplus",
										@"\u2297", @"otimes",
										@"\u22a5", @"perp",
										@"\u22c5", @"sdot",
										@"\u2308", @"lceil",
										@"\u2309", @"rceil",
										@"\u230a", @"lfloor",
										@"\u230b", @"rfloor",
										@"\u27e8", @"lang",
										@"\u27e9", @"rang",
										@"\u25ca", @"loz",
										@"\u2660", @"spades",
										@"\u2663", @"clubs",
										@"\u2665", @"hearts",
										@"\u2666", @"diams",
										nil];
	});
#else
	if (!entityLookup)
	{
		entityLookup = [[NSDictionary alloc] initWithObjectsAndKeys:@"\x22", @"quot",
										@"\x26", @"amp",
										@"\x27", @"apos",
										@"\x3c", @"lt",
										@"\x3e", @"gt",
										@"\u00a0", @"nbsp",
										@"\u00a1", @"iexcl",
										@"\u00a2", @"cent",
										@"\u00a3", @"pound",
										@"\u00a4", @"curren",
										@"\u00a5", @"yen",
										@"\u00a6", @"brvbar",
										@"\u00a7", @"sect",
										@"\u00a8", @"uml",
										@"\u00a9", @"copy",
										@"\u00aa", @"ordf",
										@"\u00ab", @"laquo",
										@"\u00ac", @"not",
										@"\u00ae", @"reg",
										@"\u00af", @"macr",
										@"\u00b0", @"deg",
										@"\u00b1", @"plusmn",
										@"\u00b2", @"sup2",
										@"\u00b3", @"sup3",
										@"\u00b4", @"acute",
										@"\u00b5", @"micro",
										@"\u00b6", @"para",
										@"\u00b7", @"middot",
										@"\u00b8", @"cedil",
										@"\u00b9", @"sup1",
										@"\u00ba", @"ordm",
										@"\u00bb", @"raquo",
										@"\u00bc", @"frac14",
										@"\u00bd", @"frac12",
										@"\u00be", @"frac34",
										@"\u00bf", @"iquest",
										@"\u00c0", @"Agrave",
										@"\u00c1", @"Aacute",
										@"\u00c2", @"Acirc",
										@"\u00c3", @"Atilde",
										@"\u00c4", @"Auml",
										@"\u00c5", @"Aring",
										@"\u00c6", @"AElig",
										@"\u00c7", @"Ccedil",
										@"\u00c8", @"Egrave",
										@"\u00c9", @"Eacute",
										@"\u00ca", @"Ecirc",
										@"\u00cb", @"Euml",
										@"\u00cc", @"Igrave",
										@"\u00cd", @"Iacute",
										@"\u00ce", @"Icirc",
										@"\u00cf", @"Iuml",
										@"\u00d0", @"ETH",
										@"\u00d1", @"Ntilde",
										@"\u00d2", @"Ograve",
										@"\u00d3", @"Oacute",
										@"\u00d4", @"Ocirc",
										@"\u00d5", @"Otilde",
										@"\u00d6", @"Ouml",
										@"\u00d7", @"times",
										@"\u00d8", @"Oslash",
										@"\u00d9", @"Ugrave",
										@"\u00da", @"Uacute",
										@"\u00db", @"Ucirc",
										@"\u00dc", @"Uuml",
										@"\u00dd", @"Yacute",
										@"\u00de", @"THORN",
										@"\u00df", @"szlig",
										@"\u00e0", @"agrave",
										@"\u00e1", @"aacute",
										@"\u00e2", @"acirc",
										@"\u00e3", @"atilde",
										@"\u00e4", @"auml",
										@"\u00e5", @"aring",
										@"\u00e6", @"aelig",
										@"\u00e7", @"ccedil",
										@"\u00e8", @"egrave",
										@"\u00e9", @"eacute",
										@"\u00ea", @"ecirc",
										@"\u00eb", @"euml",
										@"\u00ec", @"igrave",
										@"\u00ed", @"iacute",
										@"\u00ee", @"icirc",
										@"\u00ef", @"iuml",
										@"\u00f0", @"eth",
										@"\u00f1", @"ntilde",
										@"\u00f2", @"ograve",
										@"\u00f3", @"oacute",
										@"\u00f4", @"ocirc",
										@"\u00f5", @"otilde",
										@"\u00f6", @"ouml",
										@"\u00f7", @"divide",
										@"\u00f8", @"oslash",
										@"\u00f9", @"ugrave",
										@"\u00fa", @"uacute",
										@"\u00fb", @"ucirc",
										@"\u00fc", @"uuml",
										@"\u00fd", @"yacute",
										@"\u00fe", @"thorn",
										@"\u00ff", @"yuml",
										@"\u0152", @"OElig",
										@"\u0153", @"oelig",
										@"\u0160", @"Scaron",
										@"\u0161", @"scaron",
										@"\u0178", @"Yuml",
										@"\u0192", @"fnof",
										@"\u02c6", @"circ",
										@"\u02dc", @"tilde",
										@"\u0393", @"Gamma",
										@"\u0394", @"Delta",
										@"\u0398", @"Theta",
										@"\u039b", @"Lambda",
										@"\u039e", @"Xi",
										@"\u03a3", @"Sigma",
										@"\u03a5", @"Upsilon",
										@"\u03a6", @"Phi",
										@"\u03a8", @"Psi",
										@"\u03a9", @"Omega",
										@"\u03b1", @"alpha",
										@"\u03b2", @"beta",
										@"\u03b3", @"gamma",
										@"\u03b4", @"delta",
										@"\u03b5", @"epsilon",
										@"\u03b6", @"zeta",
										@"\u03b7", @"eta",
										@"\u03b8", @"theta",
										@"\u03b9", @"iota",
										@"\u03ba", @"kappa",
										@"\u03bb", @"lambda",
										@"\u03bc", @"mu",
										@"\u03bd", @"nu",
										@"\u03be", @"xi",
										@"\u03bf", @"omicron",
										@"\u03c0", @"pi",
										@"\u03c1", @"rho",
										@"\u03c2", @"sigmaf",
										@"\u03c3", @"sigma",
										@"\u03c4", @"tau",
										@"\u03c5", @"upsilon",
										@"\u03c6", @"phi",
										@"\u03c7", @"chi",
										@"\u03c8", @"psi",
										@"\u03c9", @"omega",
										@"\u03d1", @"thetasym",
										@"\u03d2", @"upsih",
										@"\u03d6", @"piv",
										@"\u2002", @"ensp",
										@"\u2003", @"emsp",
										@"\u2009", @"thinsp",
										@"\u2013", @"ndash",
										@"\u2014", @"mdash",
										@"\u2018", @"lsquo",
										@"\u2019", @"rsquo",
										@"\u201a", @"sbquo",
										@"\u201c", @"ldquo",
										@"\u201d", @"rdquo",
										@"\u201e", @"bdquo",
										@"\u2020", @"dagger",
										@"\u2021", @"Dagger",
										@"\u2022", @"bull",
										@"\u2026", @"hellip",
										@"\u2030", @"permil",
										@"\u2032", @"prime",
										@"\u2033", @"Prime",
										@"\u2039", @"lsaquo",
										@"\u203a", @"rsaquo",
										@"\u203e", @"oline",
										@"\u2044", @"frasl",
										@"\u20ac", @"euro",
										@"\u2111", @"image",
										@"\u2118", @"weierp",
										@"\u211c", @"real",
										@"\u2122", @"trade",
										@"\u2135", @"alefsym",
										@"\u2190", @"larr",
										@"\u2191", @"uarr",
										@"\u2192", @"rarr",
										@"\u2193", @"darr",
										@"\u2194", @"harr",
										@"\u21b5", @"crarr",
										@"\u21d0", @"lArr",
										@"\u21d1", @"uArr",
										@"\u21d2", @"rArr",
										@"\u21d3", @"dArr",
										@"\u21d4", @"hArr",
										@"\u2200", @"forall",
										@"\u2202", @"part",
										@"\u2203", @"exist",
										@"\u2205", @"empty",
										@"\u2207", @"nabla",
										@"\u2208", @"isin",
										@"\u2209", @"notin",
										@"\u220b", @"ni",
										@"\u220f", @"prod",
										@"\u2211", @"sum",
										@"\u2212", @"minus",
										@"\u2217", @"lowast",
										@"\u221a", @"radic",
										@"\u221d", @"prop",
										@"\u221e", @"infin",
										@"\u2220", @"ang",
										@"\u2227", @"and",
										@"\u2228", @"or",
										@"\u2229", @"cap",
										@"\u222a", @"cup",
										@"\u222b", @"int",
										@"\u2234", @"there4",
										@"\u223c", @"sim",
										@"\u2245", @"cong",
										@"\u2248", @"asymp",
										@"\u2260", @"ne",
										@"\u2261", @"equiv",
										@"\u2264", @"le",
										@"\u2265", @"ge",
										@"\u2282", @"sub",
										@"\u2283", @"sup",
										@"\u2284", @"nsub",
										@"\u2286", @"sube",
										@"\u2287", @"supe",
										@"\u2295", @"oplus",
										@"\u2297", @"otimes",
										@"\u22a5", @"perp",
										@"\u22c5", @"sdot",
										@"\u2308", @"lceil",
										@"\u2309", @"rceil",
										@"\u230a", @"lfloor",
										@"\u230b", @"rfloor",
										@"\u27e8", @"lang",
										@"\u27e9", @"rang",
										@"\u25ca", @"loz",
										@"\u2660", @"spades",
										@"\u2663", @"clubs",
										@"\u2665", @"hearts",
										@"\u2666", @"diams",
										nil];
	}
#endif
	
	NSScanner *scanner = [NSScanner scannerWithString:self];
	[scanner setCharactersToBeSkipped:nil];
	
	NSMutableString *output = [NSMutableString string];
	
	
	while (![scanner isAtEnd])
	{
		NSString *scanned = nil;
		
		if ([scanner scanUpToString:@"&" intoString:&scanned])
		{
			[output appendString:scanned];
		}
		
		if ([scanner scanString:@"&" intoString:NULL])
		{
			NSString *afterAmpersand = nil;
			if ([scanner scanUpToString:@";" intoString:&afterAmpersand]) 
			{
				if ([scanner scanString:@";" intoString:NULL])
				{
					if ([afterAmpersand hasPrefix:@"#"] && [afterAmpersand length]<6)
					{
						NSInteger i = [[afterAmpersand substringFromIndex:1] integerValue];
						[output appendFormat:@"%C", i];
					}
					else 
					{
						NSString *converted = [entityLookup objectForKey:afterAmpersand];
						
						if (converted)
						{
							[output appendString:converted];
						}
						else 
						{
							// not a valid sequence
							[output appendString:@"&"];
							[output appendString:afterAmpersand];
							[output appendString:@";"];
						}
					}
					
				}
				else 
				{
					// no semicolon 
					[output appendString:@"&"];
					[output appendString:afterAmpersand];
				}
			}
		}
	}
	
	
	return [NSString stringWithString:output];
}

- (NSDictionary *)dictionaryOfCSSStyles
{
	// font-size:14px;
	NSScanner *scanner = [NSScanner scannerWithString:self];
	
	NSString *name = nil;
	NSString *value = nil;
	
	NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
	
	while ([scanner scanCSSAttribute:&name value:&value]) 
	{
		[tmpDict setObject:value forKey:name];
	}
	
	// converting to non-mutable costs 37.5% of method	
	//	return [NSDictionary dictionaryWithDictionary:tmpDict];
	return tmpDict;
}

- (CGFloat)pixelSizeOfCSSMeasureRelativeToCurrentTextSize:(CGFloat)textSize
{
	float value = textSize;
	sscanf([self UTF8String], "%f", &value);
	
	if ([self hasSuffix:@"em"])
	{
		return value * textSize;
	}
	else if ([self hasSuffix:@"%"])
	{
		return value * textSize / 100.0;
	}
	
	// everything else interpret as pixels
	return value;
}

- (NSArray *)arrayOfCSSShadowsWithCurrentTextSize:(CGFloat)textSize currentColor:(UIColor *)color
{
	NSArray *shadows = [self componentsSeparatedByString:@","];
	
	NSMutableArray *tmpArray = [NSMutableArray array];
	
	for (NSString *oneShadow in shadows)
	{
		NSScanner *scanner = [NSScanner scannerWithString:oneShadow];
		
		
		NSString *element = nil;
		
		if ([scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&element])
		{
			// check if first element is a color
			
			UIColor *shadowColor = [UIColor colorWithHTMLName:element];
			
			NSString *offsetXString = nil;
			NSString *offsetYString = nil;
			NSString *blurString = nil;
			NSString *colorString = nil;
			
			if (shadowColor)
			{
				// format: <color> <length> <length> <length>?
				
				if ([scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&offsetXString])
				{
					if ([scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&offsetYString])
					{
						// blur is optional
						[scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&blurString];
						
						
						CGFloat offset_x = [offsetXString pixelSizeOfCSSMeasureRelativeToCurrentTextSize:textSize];
						CGFloat offset_y = [offsetYString pixelSizeOfCSSMeasureRelativeToCurrentTextSize:textSize];
						CGSize offset = CGSizeMake(offset_x, offset_y);
						CGFloat blur = [blurString pixelSizeOfCSSMeasureRelativeToCurrentTextSize:textSize];
						
						NSDictionary *shadowDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithCGSize:offset], @"Offset",
																				[NSNumber numberWithFloat:blur], @"Blur",
																				shadowColor, @"Color", nil];
						
						[tmpArray addObject:shadowDict];
					}
				}
			}
			else 
			{
				// format: <length> <length> <length>? <color>?
				
				offsetXString = element;
				
				if ([scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&offsetYString])
				{
					// blur is optional
					if ([scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&blurString])
					{
						// check if it's a color
						shadowColor = [UIColor colorWithHTMLName:blurString];
						
						if (shadowColor)
						{
							blurString = nil;
						}
					}
					
					// color is optional, or we might already have one from the blur position
					if (!shadowColor && [scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&colorString])
					{
						shadowColor = [UIColor colorWithHTMLName:colorString];
					}
					
					// if we still don't have a color, it's the current color attributed
					if (!shadowColor) 
					{
						// color is same as color attribute of style
						shadowColor = color;
					}
					
					CGFloat offset_x = [offsetXString pixelSizeOfCSSMeasureRelativeToCurrentTextSize:textSize];
					CGFloat offset_y = [offsetYString pixelSizeOfCSSMeasureRelativeToCurrentTextSize:textSize];
					CGSize offset = CGSizeMake(offset_x, offset_y);
					CGFloat blur = [blurString pixelSizeOfCSSMeasureRelativeToCurrentTextSize:textSize];
					
					NSDictionary *shadowDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithCGSize:offset], @"Offset",
																			[NSNumber numberWithFloat:blur], @"Blur",
																			shadowColor, @"Color", nil];
					
					[tmpArray addObject:shadowDict];
					
					
				}
				
			}
		}
	}		
	
	
	return [NSArray arrayWithArray:tmpArray];
}

- (CGFloat)CSSpixelSize
{
	if ([self hasSuffix:@"px"])
	{
		return [self floatValue];
	}
	
	return [self floatValue];
}

#pragma mark Utility
+ (NSString *)guid
{
	CFUUIDRef uuid = CFUUIDCreate(NULL);
	CFStringRef cfStr = CFUUIDCreateString(NULL, uuid);
	
	NSString *ret = [NSString stringWithString:(NSString *)cfStr];
	
	CFRelease(uuid);
	CFRelease(cfStr);
	
	return ret;
}

@end
