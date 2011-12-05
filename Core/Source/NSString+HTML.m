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
#import "NSCharacterSet+HTML.h"

static NSSet *inlineTags = nil;
static NSSet *metaTags = nil;
static NSDictionary *entityLookup = nil;
static NSDictionary *entityReverseLookup = nil;

@implementation NSString (HTML)

- (NSUInteger)integerValueFromHex 
{
	NSUInteger result = 0;
	sscanf([self UTF8String], "%x", &result);
	return result;
}

- (BOOL)isInlineTag
{
	static dispatch_once_t predicate;
	
	dispatch_once(&predicate, ^{
		inlineTags = [[NSSet alloc] initWithObjects:@"font", @"b", @"strong", @"em", @"i", @"sub", @"sup",
					  @"u", @"a", @"img", @"del", @"br", @"span", @"code", nil];
			
	});
	
	return [inlineTags containsObject:[self lowercaseString]];
}

- (BOOL)isMetaTag
{
	static dispatch_once_t predicate;

	dispatch_once(&predicate, ^{
		metaTags = [[NSSet alloc] initWithObjects:@"html", @"head", @"meta", @"style", @"#COMMENT#", @"title", nil];

	});
	
	return [metaTags containsObject:[self lowercaseString]];
}

- (BOOL)isNumeric
{
	const char *s = [self UTF8String];
	
	for (size_t i=0;i<strlen(s);i++)
	{
		if ((s[i]<'0' || s[i]>'9') && (s[i] != '.'))
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
	
	return result/100.0f;
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


- (NSString *)stringByAddingHTMLEntities
{
	static dispatch_once_t predicate;
	
	dispatch_once(&predicate, ^{
		entityReverseLookup = [[NSDictionary alloc] initWithObjectsAndKeys:@"&quot;", [NSNumber numberWithInteger:0x22],
							   @"&amp;", [NSNumber numberWithInteger:0x26],
							   @"&apos;", [NSNumber numberWithInteger:0x27],
							   @"&lt;", [NSNumber numberWithInteger:0x3c],
							   @"&gt;", [NSNumber numberWithInteger:0x3e],
							   @"&nbsp;", [NSNumber numberWithInteger:0x00a0],
							   @"&iexcl;", [NSNumber numberWithInteger:0x00a1],
							   @"&cent;", [NSNumber numberWithInteger:0x00a2],
							   @"&pound;", [NSNumber numberWithInteger:0x00a3],
							   @"&curren;", [NSNumber numberWithInteger:0x00a4],
							   @"&yen;", [NSNumber numberWithInteger:0x00a5],
							   @"&brvbar;", [NSNumber numberWithInteger:0x00a6],
							   @"&sect;", [NSNumber numberWithInteger:0x00a7],
							   @"&uml;", [NSNumber numberWithInteger:0x00a8],
							   @"&copy;", [NSNumber numberWithInteger:0x00a9],
							   @"&ordf;", [NSNumber numberWithInteger:0x00aa],
							   @"&laquo;", [NSNumber numberWithInteger:0x00ab],
							   @"&not;", [NSNumber numberWithInteger:0x00ac],
							   @"&reg;", [NSNumber numberWithInteger:0x00ae],
							   @"&macr;", [NSNumber numberWithInteger:0x00af],
							   @"&deg;", [NSNumber numberWithInteger:0x00b0],
							   @"&plusmn;", [NSNumber numberWithInteger:0x00b1],
							   @"&sup2;", [NSNumber numberWithInteger:0x00b2],
							   @"&sup3;", [NSNumber numberWithInteger:0x00b3],
							   @"&acute;", [NSNumber numberWithInteger:0x00b4],
							   @"&micro;", [NSNumber numberWithInteger:0x00b5],
							   @"&para;", [NSNumber numberWithInteger:0x00b6],
							   @"&middot;", [NSNumber numberWithInteger:0x00b7],
							   @"&cedil;", [NSNumber numberWithInteger:0x00b8],
							   @"&sup1;", [NSNumber numberWithInteger:0x00b9],
							   @"&ordm;", [NSNumber numberWithInteger:0x00ba],
							   @"&raquo;", [NSNumber numberWithInteger:0x00bb],
							   @"&frac14;", [NSNumber numberWithInteger:0x00bc],
							   @"&frac12;", [NSNumber numberWithInteger:0x00bd],
							   @"&frac34;", [NSNumber numberWithInteger:0x00be],
							   @"&iquest;", [NSNumber numberWithInteger:0x00bf],
							   @"&Agrave;", [NSNumber numberWithInteger:0x00c0],
							   @"&Aacute;", [NSNumber numberWithInteger:0x00c1],
							   @"&Acirc;", [NSNumber numberWithInteger:0x00c2],
							   @"&Atilde;", [NSNumber numberWithInteger:0x00c3],
							   @"&Auml;", [NSNumber numberWithInteger:0x00c4],
							   @"&Aring;", [NSNumber numberWithInteger:0x00c5],
							   @"&AElig;", [NSNumber numberWithInteger:0x00c6],
							   @"&Ccedil;", [NSNumber numberWithInteger:0x00c7],
							   @"&Egrave;", [NSNumber numberWithInteger:0x00c8],
							   @"&Eacute;", [NSNumber numberWithInteger:0x00c9],
							   @"&Ecirc;", [NSNumber numberWithInteger:0x00ca],
							   @"&Euml;", [NSNumber numberWithInteger:0x00cb],
							   @"&Igrave;", [NSNumber numberWithInteger:0x00cc],
							   @"&Iacute;", [NSNumber numberWithInteger:0x00cd],
							   @"&Icirc;", [NSNumber numberWithInteger:0x00ce],
							   @"&Iuml;", [NSNumber numberWithInteger:0x00cf],
							   @"&ETH;", [NSNumber numberWithInteger:0x00d0],
							   @"&Ntilde;", [NSNumber numberWithInteger:0x00d1],
							   @"&Ograve;", [NSNumber numberWithInteger:0x00d2],
							   @"&Oacute;", [NSNumber numberWithInteger:0x00d3],
							   @"&Ocirc;", [NSNumber numberWithInteger:0x00d4],
							   @"&Otilde;", [NSNumber numberWithInteger:0x00d5],
							   @"&Ouml;", [NSNumber numberWithInteger:0x00d6],
							   @"&times;", [NSNumber numberWithInteger:0x00d7],
							   @"&Oslash;", [NSNumber numberWithInteger:0x00d8],
							   @"&Ugrave;", [NSNumber numberWithInteger:0x00d9],
							   @"&Uacute;", [NSNumber numberWithInteger:0x00da],
							   @"&Ucirc;", [NSNumber numberWithInteger:0x00db],
							   @"&Uuml;", [NSNumber numberWithInteger:0x00dc],
							   @"&Yacute;", [NSNumber numberWithInteger:0x00dd],
							   @"&THORN;", [NSNumber numberWithInteger:0x00de],
							   @"&szlig;", [NSNumber numberWithInteger:0x00df],
							   @"&agrave;", [NSNumber numberWithInteger:0x00e0],
							   @"&aacute;", [NSNumber numberWithInteger:0x00e1],
							   @"&acirc;", [NSNumber numberWithInteger:0x00e2],
							   @"&atilde;", [NSNumber numberWithInteger:0x00e3],
							   @"&auml;", [NSNumber numberWithInteger:0x00e4],
							   @"&aring;", [NSNumber numberWithInteger:0x00e5],
							   @"&aelig;", [NSNumber numberWithInteger:0x00e6],
							   @"&ccedil;", [NSNumber numberWithInteger:0x00e7],
							   @"&egrave;", [NSNumber numberWithInteger:0x00e8],
							   @"&eacute;", [NSNumber numberWithInteger:0x00e9],
							   @"&ecirc;", [NSNumber numberWithInteger:0x00ea],
							   @"&euml;", [NSNumber numberWithInteger:0x00eb],
							   @"&igrave;", [NSNumber numberWithInteger:0x00ec],
							   @"&iacute;", [NSNumber numberWithInteger:0x00ed],
							   @"&icirc;", [NSNumber numberWithInteger:0x00ee],
							   @"&iuml;", [NSNumber numberWithInteger:0x00ef],
							   @"&eth;", [NSNumber numberWithInteger:0x00f0],
							   @"&ntilde;", [NSNumber numberWithInteger:0x00f1],
							   @"&ograve;", [NSNumber numberWithInteger:0x00f2],
							   @"&oacute;", [NSNumber numberWithInteger:0x00f3],
							   @"&ocirc;", [NSNumber numberWithInteger:0x00f4],
							   @"&otilde;", [NSNumber numberWithInteger:0x00f5],
							   @"&ouml;", [NSNumber numberWithInteger:0x00f6],
							   @"&divide;", [NSNumber numberWithInteger:0x00f7],
							   @"&oslash;", [NSNumber numberWithInteger:0x00f8],
							   @"&ugrave;", [NSNumber numberWithInteger:0x00f9],
							   @"&uacute;", [NSNumber numberWithInteger:0x00fa],
							   @"&ucirc;", [NSNumber numberWithInteger:0x00fb],
							   @"&uuml;", [NSNumber numberWithInteger:0x00fc],
							   @"&yacute;", [NSNumber numberWithInteger:0x00fd],
							   @"&thorn;", [NSNumber numberWithInteger:0x00fe],
							   @"&yuml;", [NSNumber numberWithInteger:0x00ff],
							   @"&OElig;", [NSNumber numberWithInteger:0x0152],
							   @"&oelig;", [NSNumber numberWithInteger:0x0153],
							   @"&Scaron;", [NSNumber numberWithInteger:0x0160],
							   @"&scaron;", [NSNumber numberWithInteger:0x0161],
							   @"&Yuml;", [NSNumber numberWithInteger:0x0178],
							   @"&fnof;", [NSNumber numberWithInteger:0x0192],
							   @"&circ;", [NSNumber numberWithInteger:0x02c6],
							   @"&tilde;", [NSNumber numberWithInteger:0x02dc],
							   @"&Gamma;", [NSNumber numberWithInteger:0x0393],
							   @"&Delta;", [NSNumber numberWithInteger:0x0394],
							   @"&Theta;", [NSNumber numberWithInteger:0x0398],
							   @"&Lambda;", [NSNumber numberWithInteger:0x039b],
							   @"&Xi;", [NSNumber numberWithInteger:0x039e],
							   @"&Sigma;", [NSNumber numberWithInteger:0x03a3],
							   @"&Upsilon;", [NSNumber numberWithInteger:0x03a5],
							   @"&Phi;", [NSNumber numberWithInteger:0x03a6],
							   @"&Psi;", [NSNumber numberWithInteger:0x03a8],
							   @"&Omega;", [NSNumber numberWithInteger:0x03a9],
							   @"&alpha;", [NSNumber numberWithInteger:0x03b1],
							   @"&beta;", [NSNumber numberWithInteger:0x03b2],
							   @"&gamma;", [NSNumber numberWithInteger:0x03b3],
							   @"&delta;", [NSNumber numberWithInteger:0x03b4],
							   @"&epsilon;", [NSNumber numberWithInteger:0x03b5],
							   @"&zeta;", [NSNumber numberWithInteger:0x03b6],
							   @"&eta;", [NSNumber numberWithInteger:0x03b7],
							   @"&theta;", [NSNumber numberWithInteger:0x03b8],
							   @"&iota;", [NSNumber numberWithInteger:0x03b9],
							   @"&kappa;", [NSNumber numberWithInteger:0x03ba],
							   @"&lambda;", [NSNumber numberWithInteger:0x03bb],
							   @"&mu;", [NSNumber numberWithInteger:0x03bc],
							   @"&nu;", [NSNumber numberWithInteger:0x03bd],
							   @"&xi;", [NSNumber numberWithInteger:0x03be],
							   @"&omicron;", [NSNumber numberWithInteger:0x03bf],
							   @"&pi;", [NSNumber numberWithInteger:0x03c0],
							   @"&rho;", [NSNumber numberWithInteger:0x03c1],
							   @"&sigmaf;", [NSNumber numberWithInteger:0x03c2],
							   @"&sigma;", [NSNumber numberWithInteger:0x03c3],
							   @"&tau;", [NSNumber numberWithInteger:0x03c4],
							   @"&upsilon;", [NSNumber numberWithInteger:0x03c5],
							   @"&phi;", [NSNumber numberWithInteger:0x03c6],
							   @"&chi;", [NSNumber numberWithInteger:0x03c7],
							   @"&psi;", [NSNumber numberWithInteger:0x03c8],
							   @"&omega;", [NSNumber numberWithInteger:0x03c9],
							   @"&thetasym;", [NSNumber numberWithInteger:0x03d1],
							   @"&upsih;", [NSNumber numberWithInteger:0x03d2],
							   @"&piv;", [NSNumber numberWithInteger:0x03d6],
							   @"&ensp;", [NSNumber numberWithInteger:0x2002],
							   @"&emsp;", [NSNumber numberWithInteger:0x2003],
							   @"&thinsp;", [NSNumber numberWithInteger:0x2009],
							   @"&ndash;", [NSNumber numberWithInteger:0x2013],
							   @"&mdash;", [NSNumber numberWithInteger:0x2014],
							   @"&lsquo;", [NSNumber numberWithInteger:0x2018],
							   @"&rsquo;", [NSNumber numberWithInteger:0x2019],
							   @"&sbquo;", [NSNumber numberWithInteger:0x201a],
							   @"&ldquo;", [NSNumber numberWithInteger:0x201c],
							   @"&rdquo;", [NSNumber numberWithInteger:0x201d],
							   @"&bdquo;", [NSNumber numberWithInteger:0x201e],
							   @"&dagger;", [NSNumber numberWithInteger:0x2020],
							   @"&Dagger;", [NSNumber numberWithInteger:0x2021],
							   @"&bull;", [NSNumber numberWithInteger:0x2022],
							   @"&hellip;", [NSNumber numberWithInteger:0x2026],
							   @"&permil;", [NSNumber numberWithInteger:0x2030],
							   @"&prime;", [NSNumber numberWithInteger:0x2032],
							   @"&Prime;", [NSNumber numberWithInteger:0x2033],
							   @"&lsaquo;", [NSNumber numberWithInteger:0x2039],
							   @"&rsaquo;", [NSNumber numberWithInteger:0x203a],
							   @"&oline;", [NSNumber numberWithInteger:0x203e],
							   @"&frasl;", [NSNumber numberWithInteger:0x2044],
							   @"&euro;", [NSNumber numberWithInteger:0x20ac],
							   @"&image;", [NSNumber numberWithInteger:0x2111],
							   @"&weierp;", [NSNumber numberWithInteger:0x2118],
							   @"&real;", [NSNumber numberWithInteger:0x211c],
							   @"&trade;", [NSNumber numberWithInteger:0x2122],
							   @"&alefsym;", [NSNumber numberWithInteger:0x2135],
							   @"&larr;", [NSNumber numberWithInteger:0x2190],
							   @"&uarr;", [NSNumber numberWithInteger:0x2191],
							   @"&rarr;", [NSNumber numberWithInteger:0x2192],
							   @"&darr;", [NSNumber numberWithInteger:0x2193],
							   @"&harr;", [NSNumber numberWithInteger:0x2194],
							   @"&crarr;", [NSNumber numberWithInteger:0x21b5],
							   @"&lArr;", [NSNumber numberWithInteger:0x21d0],
							   @"&uArr;", [NSNumber numberWithInteger:0x21d1],
							   @"&rArr;", [NSNumber numberWithInteger:0x21d2],
							   @"&dArr;", [NSNumber numberWithInteger:0x21d3],
							   @"&hArr;", [NSNumber numberWithInteger:0x21d4],
							   @"&forall;", [NSNumber numberWithInteger:0x2200],
							   @"&part;", [NSNumber numberWithInteger:0x2202],
							   @"&exist;", [NSNumber numberWithInteger:0x2203],
							   @"&empty;", [NSNumber numberWithInteger:0x2205],
							   @"&nabla;", [NSNumber numberWithInteger:0x2207],
							   @"&isin;", [NSNumber numberWithInteger:0x2208],
							   @"&notin;", [NSNumber numberWithInteger:0x2209],
							   @"&ni;", [NSNumber numberWithInteger:0x220b],
							   @"&prod;", [NSNumber numberWithInteger:0x220f],
							   @"&sum;", [NSNumber numberWithInteger:0x2211],
							   @"&minus;", [NSNumber numberWithInteger:0x2212],
							   @"&lowast;", [NSNumber numberWithInteger:0x2217],
							   @"&radic;", [NSNumber numberWithInteger:0x221a],
							   @"&prop;", [NSNumber numberWithInteger:0x221d],
							   @"&infin;", [NSNumber numberWithInteger:0x221e],
							   @"&ang;", [NSNumber numberWithInteger:0x2220],
							   @"&and;", [NSNumber numberWithInteger:0x2227],
							   @"&or;", [NSNumber numberWithInteger:0x2228],
							   @"&cap;", [NSNumber numberWithInteger:0x2229],
							   @"&cup;", [NSNumber numberWithInteger:0x222a],
							   @"&int;", [NSNumber numberWithInteger:0x222b],
							   @"&there4;", [NSNumber numberWithInteger:0x2234],
							   @"&sim;", [NSNumber numberWithInteger:0x223c],
							   @"&cong;", [NSNumber numberWithInteger:0x2245],
							   @"&asymp;", [NSNumber numberWithInteger:0x2248],
							   @"&ne;", [NSNumber numberWithInteger:0x2260],
							   @"&equiv;", [NSNumber numberWithInteger:0x2261],
							   @"&le;", [NSNumber numberWithInteger:0x2264],
							   @"&ge;", [NSNumber numberWithInteger:0x2265],
							   @"&sub;", [NSNumber numberWithInteger:0x2282],
							   @"&sup;", [NSNumber numberWithInteger:0x2283],
							   @"&nsub;", [NSNumber numberWithInteger:0x2284],
							   @"&sube;", [NSNumber numberWithInteger:0x2286],
							   @"&supe;", [NSNumber numberWithInteger:0x2287],
							   @"&oplus;", [NSNumber numberWithInteger:0x2295],
							   @"&otimes;", [NSNumber numberWithInteger:0x2297],
							   @"&perp;", [NSNumber numberWithInteger:0x22a5],
							   @"&sdot;", [NSNumber numberWithInteger:0x22c5],
							   @"&lceil;", [NSNumber numberWithInteger:0x2308],
							   @"&rceil;", [NSNumber numberWithInteger:0x2309],
							   @"&lfloor;", [NSNumber numberWithInteger:0x230a],
							   @"&rfloor;", [NSNumber numberWithInteger:0x230b],
							   @"&lang;", [NSNumber numberWithInteger:0x27e8],
							   @"&rang;", [NSNumber numberWithInteger:0x27e9],
							   @"&loz;", [NSNumber numberWithInteger:0x25ca],
							   @"&spades;", [NSNumber numberWithInteger:0x2660],
							   @"&clubs;", [NSNumber numberWithInteger:0x2663],
							   @"&hearts;", [NSNumber numberWithInteger:0x2665],
							   @"&diams;", [NSNumber numberWithInteger:0x2666],
							   @"<br />", [NSNumber numberWithInteger:0x2028], 
							   nil];
	
	});
	
	NSMutableString *tmpString = [NSMutableString string];
	
	for (NSUInteger i = 0; i<[self length]; i++)
	{
		unichar oneChar = [self characterAtIndex:i];
		
		NSNumber *subKey = [NSNumber numberWithInteger:oneChar];
		NSString *entity = [entityReverseLookup objectForKey:subKey];
		
		if (entity)
		{
			[tmpString appendString:entity];
		}
		else
		{
			if (oneChar<=255)
			{
				[tmpString appendFormat:@"%C", oneChar];
			}
			else
			{
				[tmpString appendFormat:@"&#%d;", oneChar];
			}
		}
	}
	
	return tmpString;
}

- (NSString *)stringByReplacingHTMLEntities
{
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


// go remove all characters that are not valid in tag attributes
- (NSString *)stringByRemovingInvalidTagAttributeCharacters
{
	NSCharacterSet *validCharset = [NSCharacterSet tagAttributeNameCharacterSet];
	
	NSMutableString *tmpString = [NSMutableString string];
	
	for (NSUInteger i = 0; i<[self length]; i++)
	{
		unichar oneChar = [self characterAtIndex:i];
		
		if ([validCharset characterIsMember:oneChar])
		{
			[tmpString appendString:[NSString stringWithCharacters:&oneChar length:1]];
		}
	}
	
	return tmpString;
}


#pragma mark CSS

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
		return value * textSize / 100.0f;
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
	
	NSString *ret = [NSString stringWithString:CFBridgingRelease(cfStr)];
	
	CFRelease(uuid);
	// CFRelease(cfStr);
	
	return ret;
}

@end
