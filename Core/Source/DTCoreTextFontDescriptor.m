//
//  DTCoreTextFontDescriptor.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/26/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCoreTextFontDescriptor.h"

static NSCache *_fontCache = nil;
static NSMutableDictionary *_fontOverrides = nil;

static dispatch_semaphore_t fontLock;

@interface DTCoreTextFontDescriptor ()

// generated fonts are cached
+ (NSCache *)fontCache;

@end

@implementation DTCoreTextFontDescriptor
{
	NSString *fontFamily;
	NSString *fontName;
	
	CGFloat pointSize;
	
	// symbolic traits
	BOOL boldTrait;
	BOOL italicTrait;
	BOOL expandedTrait;
	BOOL condensedTrait;
	BOOL monospaceTrait;
	BOOL verticalTrait;
	BOOL UIoptimizedTrait;
	
	CTFontStylisticClass stylisticClass;
    
	BOOL smallCapsFeature;
  
	BOOL _hashSet;
	NSUInteger _hash;
}

+ (void)initialize
{
	if(self == [DTCoreTextFontDescriptor class]) {
		fontLock = dispatch_semaphore_create(1);
	}
}

+ (NSCache *)fontCache
{
	if (!_fontCache)
	{
		_fontCache = [[NSCache alloc] init];
	}

	return _fontCache;
}

+ (NSMutableDictionary *)fontOverrides
{
	if (!_fontOverrides)
	{
		_fontOverrides = [[NSMutableDictionary alloc] init];
		
		
		// see if there is an overrides table to preload
		
		NSString *path = [[NSBundle mainBundle] pathForResource:@"DTCoreTextFontOverrides" ofType:@"plist"];
		NSArray *fileArray = [NSArray arrayWithContentsOfFile:path];
		
		for (NSDictionary *oneOverride in fileArray)
		{
			NSString *fontFamily = [oneOverride objectForKey:@"FontFamily"];
			NSString *overrideFontName = [oneOverride objectForKey:@"OverrideFontName"];
			BOOL bold = [[oneOverride objectForKey:@"Bold"] boolValue];
			BOOL italic = [[oneOverride objectForKey:@"Italic"] boolValue];
			BOOL smallcaps = [[oneOverride objectForKey:@"SmallCaps"] boolValue];
			
			if (smallcaps)
			{
				[DTCoreTextFontDescriptor setSmallCapsFontName:overrideFontName forFontFamily:fontFamily bold:bold italic:italic];
			}
			else
			{
				[DTCoreTextFontDescriptor setOverrideFontName:overrideFontName forFontFamily:fontFamily bold:bold italic:italic];
			}
		}
	}
	
	return _fontOverrides;
}

+ (void)setSmallCapsFontName:(NSString *)fontName forFontFamily:(NSString *)fontFamily bold:(BOOL)bold italic:(BOOL)italic
{
	NSString *key = [NSString stringWithFormat:@"%@-%d-%d-smallcaps", fontFamily, bold, italic];
	
	[[DTCoreTextFontDescriptor fontOverrides] setObject:fontName forKey:key];
}

+ (NSString *)smallCapsFontNameforFontFamily:(NSString *)fontFamily bold:(BOOL)bold italic:(BOOL)italic
{
	NSString *key = [NSString stringWithFormat:@"%@-%d-%d-smallcaps", fontFamily, bold, italic];
	
	return [[DTCoreTextFontDescriptor fontOverrides] objectForKey:key];
}

+ (void)setOverrideFontName:(NSString *)fontName forFontFamily:(NSString *)fontFamily bold:(BOOL)bold italic:(BOOL)italic
{
	NSString *key = [NSString stringWithFormat:@"%@-%d-%d-override", fontFamily, bold, italic];
	
	[[DTCoreTextFontDescriptor fontOverrides] setObject:fontName forKey:key];
}

+ (NSString *)overrideFontNameforFontFamily:(NSString *)fontFamily bold:(BOOL)bold italic:(BOOL)italic
{
	NSString *key = [NSString stringWithFormat:@"%@-%d-%d-override", fontFamily, bold, italic];
	
	return [[DTCoreTextFontDescriptor fontOverrides] objectForKey:key];
}

+ (DTCoreTextFontDescriptor *)fontDescriptorWithFontAttributes:(NSDictionary *)attributes
{
	return [[DTCoreTextFontDescriptor alloc] initWithFontAttributes:attributes];
}

+ (DTCoreTextFontDescriptor *)fontDescriptorForCTFont:(CTFontRef)ctFont
{
	return [[DTCoreTextFontDescriptor alloc] initWithCTFont:ctFont];
}

- (id)initWithFontAttributes:(NSDictionary *)attributes
{
	self = [super init];
	if (self)
	{
		[self setFontAttributes:attributes];
	}
	
	return self;
}

- (id)initWithCTFontDescriptor:(CTFontDescriptorRef)ctFontDescriptor
{
	self = [super init];
	if (self)
	{
		CFDictionaryRef dict = CTFontDescriptorCopyAttributes(ctFontDescriptor);
		
		CFDictionaryRef traitsDict = CTFontDescriptorCopyAttribute(ctFontDescriptor, kCTFontTraitsAttribute);
		CTFontSymbolicTraits traitsValue = [[(__bridge NSDictionary *)traitsDict objectForKey:(id)kCTFontSymbolicTrait] unsignedIntValue];
		CFRelease(traitsDict);
		
		self.symbolicTraits = traitsValue;
		
		[self setFontAttributes:CFBridgingRelease(dict)];
		//CFRelease(dict);
		
		// also get family name
		
		CFStringRef familyName = CTFontDescriptorCopyAttribute(ctFontDescriptor, kCTFontFamilyNameAttribute);
		self.fontFamily = CFBridgingRelease(familyName);
		//CFRelease(familyName);
	}
	
	return self;
}

- (id)initWithCTFont:(CTFontRef)ctFont
{
	self = [super init];
	if (self)
	{
		CTFontDescriptorRef fd = CTFontCopyFontDescriptor(ctFont);
		CFDictionaryRef dict = CTFontDescriptorCopyAttributes(fd);
		
		CFDictionaryRef traitsDict = CTFontDescriptorCopyAttribute(fd, kCTFontTraitsAttribute);
		CTFontSymbolicTraits traitsValue = [[(__bridge NSDictionary *)traitsDict objectForKey:(id)kCTFontSymbolicTrait] unsignedIntValue];
		CFRelease(traitsDict);
		CFRelease(fd);
		
		self.symbolicTraits = traitsValue;
		
		[self setFontAttributes:CFBridgingRelease(dict)];
		//CFRelease(dict);
		
		// also get the family while we're at it
		CFStringRef cfStr = CTFontCopyFamilyName(ctFont);
		
		if (cfStr)
		{
			self.fontFamily = CFBridgingRelease(cfStr);
			//CFRelease(cfStr);
		}
	}
	
	return self;
}



- (NSString *)description
{
	NSMutableString *string = [NSMutableString string];
	
	[string appendFormat:@"<%@ ", [self class]];
	
	
	if (self.fontName)
	{
		[string appendFormat:@"name:\'%@\' ", self.fontName];
	}
	
	if (fontFamily)
	{
		[string appendFormat:@"family:\'%@\' ", fontFamily];
	}
	
	NSMutableArray *tmpTraits = [NSMutableArray array];
	
	if (boldTrait)
	{
		[tmpTraits addObject:@"bold"];
	}
	
	if (italicTrait)
	{
		[tmpTraits addObject:@"italic"];
	}
	
	if (monospaceTrait)
	{
		[tmpTraits addObject:@"monospace"];
	}
	
	if (condensedTrait)
	{
		[tmpTraits addObject:@"condensed"];
	}
	
	if (expandedTrait)
	{
		[tmpTraits addObject:@"expanded"];
	}
	
	if (verticalTrait)
	{
		[tmpTraits addObject:@"vertical"];
	}
	
	if (UIoptimizedTrait)
	{
		[tmpTraits addObject:@"UI optimized"];
	}
	
	
	if ([tmpTraits count])
	{
		[string appendString:@"attributes:"];
		[string appendString:[tmpTraits componentsJoinedByString:@", "]];
	}
	
	
	[string appendString:@">"];
	
	return string;
}

- (CTFontSymbolicTraits)symbolicTraits
{
	CTFontSymbolicTraits retValue = 0;
	
	
	if (boldTrait)
	{
		retValue |= kCTFontBoldTrait;
	}
	
	if (italicTrait)
	{
		retValue |= kCTFontItalicTrait;
	}
	
	if (expandedTrait)
	{
		retValue |= kCTFontExpandedTrait;
	}
	
	if (condensedTrait)
	{
		retValue |= kCTFontCondensedTrait;
	}
	
	if (monospaceTrait)
	{
		retValue |= kCTFontMonoSpaceTrait;
	}
	
	if (verticalTrait)
	{
		retValue |= kCTFontVerticalTrait;
	}
	
	if (UIoptimizedTrait)
	{
		retValue |= kCTFontUIOptimizedTrait;
	}
	
	// bundle in class
	retValue |= stylisticClass;
	
	return retValue;
}

- (NSDictionary *)fontAttributes
{
	NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
	
	NSMutableDictionary *traitsDict = [NSMutableDictionary dictionary];
	
	CTFontSymbolicTraits symbolicTraits = [self symbolicTraits];
	
	if (symbolicTraits)
	{
		[traitsDict setObject:[NSNumber numberWithUnsignedInt:symbolicTraits] forKey:(id)kCTFontSymbolicTrait];
	}
	
	if ([traitsDict count])
	{
		[tmpDict setObject:traitsDict forKey:(id)kCTFontTraitsAttribute];
	}
	
	if (fontFamily)
	{
		[tmpDict setObject:fontFamily forKey:(id)kCTFontFamilyNameAttribute];
	}
	
	if (fontName)
	{
		[tmpDict setObject:fontName forKey:(id)kCTFontNameAttribute];
	}
	
	// we need size because that's what makes a font unique, for searching it's ignored anyway
	[tmpDict setObject:[NSNumber numberWithFloat:pointSize] forKey:(id)kCTFontSizeAttribute];
	
	
	if (smallCapsFeature)
	{
		NSNumber *typeNum = [NSNumber numberWithInteger:3];
		NSNumber *selNum = [NSNumber numberWithInteger:3];
		
		NSDictionary *setting = [NSDictionary dictionaryWithObjectsAndKeys:selNum, (id)kCTFontFeatureSelectorIdentifierKey,
														 typeNum, (id)kCTFontFeatureTypeIdentifierKey, nil];
		
		NSArray *featureSettings = [NSArray arrayWithObject:setting];
		
		[tmpDict setObject:featureSettings forKey:(id)kCTFontFeatureSettingsAttribute];
	}
	
	//return [NSDictionary dictionaryWithDictionary:tmpDict];
	
	// converting to non-mutable costs 42% of entire method
	return tmpDict;
}

- (BOOL)supportsNativeSmallCaps
{
	if ([DTCoreTextFontDescriptor smallCapsFontNameforFontFamily:fontFamily bold:boldTrait italic:italicTrait])
	{
		return YES;
	}
	
	CTFontRef tmpFont = [self newMatchingFont];
	
	BOOL smallCapsSupported = NO;
	
	// check if this font supports small caps
	CFArrayRef fontFeatures = CTFontCopyFeatures(tmpFont);
	
	if (fontFeatures)
	{
		for (NSDictionary *oneFeature in (__bridge NSArray *)fontFeatures)
		{
			NSInteger featureTypeIdentifier = [[oneFeature objectForKey:(id)kCTFontFeatureTypeIdentifierKey] integerValue];
			
			if (featureTypeIdentifier == 3) // Letter Case
			{
				NSArray *featureSelectors = [oneFeature objectForKey:(id)kCTFontFeatureTypeSelectorsKey];
				
				for (NSDictionary *oneFeatureSelector in featureSelectors)
				{
					NSInteger featureSelectorIdentifier = [[oneFeatureSelector objectForKey:(id)kCTFontFeatureSelectorIdentifierKey] integerValue];
					
					if (featureSelectorIdentifier == 3) // Small Caps
					{
						// hooray, small caps supported!
						smallCapsSupported = YES;
						
						break;
					}
				}
				
				break;
			}
		}
		
		CFRelease(fontFeatures);
	}
	
	CFRelease(tmpFont);
	
	return smallCapsSupported;
}

#pragma mark Finding Font

- (CTFontRef)newMatchingFont
{
	dispatch_semaphore_wait(fontLock, DISPATCH_TIME_FOREVER);

	NSDictionary *attributes = [self fontAttributes];
	
	NSCache *fontCache = [DTCoreTextFontDescriptor fontCache];
	NSString *cacheKey = [attributes description];
	
	CTFontRef cachedFont = (__bridge CTFontRef)[fontCache objectForKey:cacheKey];
	
	if (cachedFont)
	{
		CFRetain(cachedFont);
		dispatch_semaphore_signal(fontLock);
		return cachedFont;
	}
	
	CTFontDescriptorRef fontDesc = NULL;
	
	CTFontRef matchingFont;
	
	NSString *usedName = fontName;
	
	// override fontName if a small caps or regular override is registered
	if (fontFamily)
	{
		NSString *overrideFontName = nil;
		if (smallCapsFeature)
		{
			overrideFontName = [DTCoreTextFontDescriptor smallCapsFontNameforFontFamily:fontFamily bold:boldTrait italic:italicTrait];
		}
		else
		{
			overrideFontName = [DTCoreTextFontDescriptor overrideFontNameforFontFamily:fontFamily bold:boldTrait italic:italicTrait];
		}
    
		if (overrideFontName)
		{
			usedName = overrideFontName;
		}
	}
	
	if (usedName)
	{
		matchingFont = CTFontCreateWithName((__bridge CFStringRef)usedName, pointSize, NULL);
	}
	else
	{
		fontDesc = CTFontDescriptorCreateWithAttributes((__bridge CFDictionaryRef)attributes);
		
		if (fontFamily)
		{
			// fast font creation
			matchingFont = CTFontCreateWithFontDescriptor(fontDesc, pointSize, NULL);
		}
		else
		{
			// without font name or family we need to do expensive search
			// otherwise we always get Helvetica
			
			NSMutableSet *set = [NSMutableSet setWithObject:(id)kCTFontTraitsAttribute];
			
			if (fontFamily)
			{
				[set addObject:(id)kCTFontFamilyNameAttribute];
			}
			
			if (smallCapsFeature)
			{
				[set addObject:(id)kCTFontFeaturesAttribute];
			}
			
			CTFontDescriptorRef matchingDesc = CTFontDescriptorCreateMatchingFontDescriptor(fontDesc, (__bridge CFSetRef)set);
			
			if (matchingDesc)
			{
				matchingFont = CTFontCreateWithFontDescriptor(matchingDesc, pointSize, NULL);
				CFRelease(matchingDesc);
			}
			else 
			{
				//NSLog(@"No matches for %@", (__bridge id)fontDesc);
				matchingFont = nil;
			}
		}
		CFRelease(fontDesc);
		
	}
	
	if (matchingFont)
	{
		// cache it
		[fontCache setObject:(__bridge id)(matchingFont) forKey:cacheKey];	// if you CFBridgeRelease you get a crash
	}
	dispatch_semaphore_signal(fontLock);
	return matchingFont;
}

- (NSUInteger)hash
{
  if(_hashSet == NO) {
    // two font descriptors are equal if their attribute dictionary are the same
    _hash = [[[self fontAttributes] description] hash];
    _hashSet = YES;
    
  }
  return(_hash);
}

- (BOOL)isEqual:(id)object
{
	return (([object isKindOfClass:[DTCoreTextFontDescriptor class]]) && ([self hash] == [object hash]));
}


#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeObject:self.fontName forKey:@"FontName"];
	[encoder encodeObject:self.fontFamily forKey:@"FontFamily"];
	[encoder encodeBool:boldTrait forKey:@"BoldTrait"];
	[encoder encodeBool:italicTrait forKey:@"ItalicTrait"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super init];
	
	if (self)
	{
		self.fontName = [decoder decodeObjectForKey:@"FontName"];
		self.fontFamily = [decoder decodeObjectForKey:@"FontFamily"];
		boldTrait = [decoder decodeBoolForKey:@"BoldTrait"];
		italicTrait = [decoder decodeBoolForKey:@"ItalicTrait"];
	}
	
	return self;
}


#pragma mark Copying

- (id)copyWithZone:(NSZone *)zone
{
	DTCoreTextFontDescriptor *newDesc = [[DTCoreTextFontDescriptor allocWithZone:zone] initWithFontAttributes:[self fontAttributes]];
	newDesc.pointSize = self.pointSize;
	if (stylisticClass)
	{
		newDesc.stylisticClass = self.stylisticClass;
	}
	
	return newDesc;
}


#pragma mark Properties
- (void)setStylisticClass:(CTFontStylisticClass)newClass
{
	self.fontFamily = nil;
	
	stylisticClass = newClass;
}


- (void)setFontAttributes:(NSDictionary *)attributes
{
	if (!attributes) 
	{
		self.fontFamily = nil;
		self.fontName = nil;
		self.pointSize = 12;
		self.symbolicTraits = 0;
	
		boldTrait = NO;
		italicTrait = NO;
		expandedTrait = NO;
		condensedTrait = NO;
		monospaceTrait = NO;
		verticalTrait = NO;
		UIoptimizedTrait = NO;
	}
	
	NSDictionary *traitsDict = [attributes objectForKey:(id)kCTFontTraitsAttribute];
	
	if (traitsDict)
	{
		CTFontSymbolicTraits traitsValue = [[traitsDict objectForKey:(id)kCTFontSymbolicTrait ] unsignedIntValue];
		self.symbolicTraits = traitsValue;
	}
	
	NSNumber *pointNum = [attributes objectForKey:(id)kCTFontSizeAttribute];
	if (pointNum)
	{
		pointSize = [pointNum floatValue];
	}
	
	NSString *family = [attributes objectForKey:(id)kCTFontFamilyNameAttribute];
	
	if (family)
	{
		self.fontFamily = family;
	}
	
	NSString *name = [attributes objectForKey:(id)kCTFontNameAttribute];
	
	if (name)
	{
		self.fontName = name;
	}
}

- (void)setSymbolicTraits:(CTFontSymbolicTraits)symbolicTraits
{
	if (symbolicTraits & kCTFontBoldTrait)
	{
		boldTrait = YES;
	}
	
	if (symbolicTraits & kCTFontItalicTrait)
	{
		italicTrait = YES;
	}
	
	if (symbolicTraits & kCTFontExpandedTrait)
	{
		expandedTrait = YES;
	}
	
	if (symbolicTraits & kCTFontCondensedTrait)
	{
		condensedTrait = YES;
	}
	
	if (symbolicTraits & kCTFontMonoSpaceTrait)
	{
		monospaceTrait = YES;
	}
	
	if (symbolicTraits & kCTFontVerticalTrait)
	{
		verticalTrait = YES;
	}
	
	if (symbolicTraits & kCTFontUIOptimizedTrait)
	{
		UIoptimizedTrait = YES;
	}
	
	// stylistic class is bundled in the traits
	stylisticClass = symbolicTraits & kCTFontClassMaskTrait;   
}


// a representation of this font in CSS style
- (NSString *)cssStyleRepresentation
{
	NSMutableString *retString = [NSMutableString string];
	
	if (fontFamily)
	{
		[retString appendFormat:@"font-family:'%@';", fontFamily];
	}
	
	[retString appendFormat:@"font-size:%.0fpx;", pointSize];
	
	if (italicTrait)
	{
		[retString appendString:@"font-style:italic;"];
	}
	
	if (boldTrait)
	{
		[retString appendString:@"font-weight:bold;"];
	}

	// return nil if no content
	if ([retString length])
	{
		return retString;
	}
	else
	{
		return nil;
	}
}

@synthesize fontFamily;
@synthesize fontName;

@synthesize pointSize;
@synthesize boldTrait;
@synthesize italicTrait;
@synthesize expandedTrait;
@synthesize condensedTrait;
@synthesize monospaceTrait;
@synthesize verticalTrait;
@synthesize UIoptimizedTrait;

@synthesize symbolicTraits;

@synthesize stylisticClass;
@synthesize smallCapsFeature;

@end

