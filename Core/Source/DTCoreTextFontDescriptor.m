//
//  DTCoreTextFontDescriptor.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/26/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCoreTextFontDescriptor.h"
#import "DTCoreTextFontCollection.h"
#import "DTCompatibility.h"
#import "DTCoreTextConstants.h"

static NSCache *_fontCache = nil;
static NSMutableDictionary *_fontOverrides = nil;

// font family to use if no font can be found with the given font-family
static NSString *_fallbackFontFamily = @"Times New Roman";

// adds "STHeitiSC-Light" font for cascading fix on iOS 5
static BOOL _needsChineseFontCascadeFix = NO;

@interface DTCoreTextFontDescriptor ()

// gets descriptors of all available fonts from system
+ (void)_createDictionaryOfAllAvailableFontOverrideNamesWithCompletion:(void(^)(NSDictionary *dictionary))completion;

@end


@implementation DTCoreTextFontDescriptor
{
	NSString *_fontFamily;
	NSString *_fontName;
	
	CGFloat _pointSize;
	
	CTFontSymbolicTraits _stylisticTraits;
	CTFontStylisticClass _stylisticClass;
	
	BOOL _smallCapsFeature;
}

+ (void)initialize
{
	// only this class (and not subclasses) do this
	if (self != [DTCoreTextFontDescriptor class])
	{
		return;
	}
	
	_fontCache = [[NSCache alloc] init];
	
	// init/load of overrides
	_fontOverrides = [[NSMutableDictionary alloc] init];
	
	// then - if it exists - we override from the plist
	NSString *path = [[NSBundle bundleForClass:self] pathForResource:@"DTCoreTextFontOverrides" ofType:@"plist"];
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
	
#if TARGET_OS_IPHONE
	// workaround for iOS 5.x bug: global font cascade table has incorrect bold font for Chinese characters in Chinese locale
	if (NSFoundationVersionNumber < DTNSFoundationVersionNumber_iOS_6_0)
	{
		_needsChineseFontCascadeFix = YES;
	}
#endif
}

// preloads all available system fonts for faster font matching
+ (void)asyncPreloadFontLookupTable
{
	// asynchronically load all available fonts into override table
	[self _createDictionaryOfAllAvailableFontOverrideNamesWithCompletion:^(NSDictionary *dictionary) {
		
		// now we're done and we can merge the new dictionary synchronized
		
		@synchronized(_fontOverrides)
		{
			[dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *overrideFontName, BOOL *stop) {
				
				// only add the overrides where there is no previous setting, either from plist of user setting it
				if (![_fontOverrides objectForKey:key])
				{
					[_fontOverrides setObject:overrideFontName forKey:key];
				}
			}];
		}
	}];
}

// get font names of all available fonts from system 
+ (void)_createDictionaryOfAllAvailableFontOverrideNamesWithCompletion:(void(^)(NSDictionary *dictionary))completion
{
	NSParameterAssert(completion);
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		
		// get all font descriptors
		DTCoreTextFontCollection *allFonts = [DTCoreTextFontCollection availableFontsCollection];
		
		NSMutableDictionary *tmpDictionary = [NSMutableDictionary dictionaryWithCapacity:[allFonts.fontDescriptors count]];

		// sort font descriptors by name so that shorter names are preferred
		NSSortDescriptor *sort1 = [NSSortDescriptor sortDescriptorWithKey:@"fontFamily" ascending:YES];
		NSSortDescriptor *sort2 = [NSSortDescriptor sortDescriptorWithKey:@"fontName" ascending:YES];
		NSArray *sortedFonts = [[allFonts fontDescriptors] sortedArrayUsingDescriptors:[NSArray arrayWithObjects:sort1, sort2, nil]];
		
		
		for (DTCoreTextFontDescriptor *oneFontDescriptor in sortedFonts)
		{
			NSString *key = [NSString stringWithFormat:@"%@-%d-%d-override", oneFontDescriptor.fontFamily, oneFontDescriptor.boldTrait, oneFontDescriptor.italicTrait];
			
			NSString *existingOverride = [tmpDictionary objectForKey:key];
			
			if (!existingOverride)
			{
				[tmpDictionary setObject:oneFontDescriptor.fontName forKey:key];
			}
			else
			{
				// prefer fonts with shorter name, there are probably "more correct". e.g. Helvetica-Oblique instead of Helvetica-LightOblique
				if ([existingOverride length]>[oneFontDescriptor.fontName length])
				{
					[tmpDictionary setObject:oneFontDescriptor.fontName forKey:key];
				}
			}
		}
		
		completion([tmpDictionary copy]);
	});
}

#pragma mark - Global Font Overriding

+ (void)setFallbackFontFamily:(NSString *)fontFamily
{
	if (!fontFamily)
	{
		[NSException raise:DTCoreTextFontDescriptorException format:@"Fallback Font Family cannot be nil"];
	}
	
	// make sure that only valid font families can be registered
	NSDictionary *attributes = [NSDictionary dictionaryWithObject:fontFamily forKey:(id)kCTFontFamilyNameAttribute];
	CTFontDescriptorRef fontDesc = CTFontDescriptorCreateWithAttributes((__bridge CFDictionaryRef)(attributes));
	CTFontRef font = CTFontCreateWithFontDescriptor(fontDesc, 12, NULL);

	BOOL isValid = NO;
	
	if (font)
	{
		NSString *usedFontFamily = CFBridgingRelease(CTFontCopyFamilyName(font));
		
		if ([usedFontFamily isEqualToString:fontFamily])
		{
			isValid = YES;
		}
		
		CFRelease(fontDesc);
		CFRelease(font);
	}
	
	if (!isValid)
	{
		[NSException raise:DTCoreTextFontDescriptorException format:@"Fallback Font Family '%@' not registered on the system", fontFamily];
	}

	_fallbackFontFamily = [fontFamily copy];
}

+ (NSString *)fallbackFontFamily
{
	return _fallbackFontFamily;
}

+ (void)setSmallCapsFontName:(NSString *)fontName forFontFamily:(NSString *)fontFamily bold:(BOOL)bold italic:(BOOL)italic
{
	@synchronized(_fontOverrides)
	{
		NSString *key = [NSString stringWithFormat:@"%@-%d-%d-smallcaps", fontFamily, bold, italic];
		[_fontOverrides setObject:fontName forKey:key];
	}
}

+ (NSString *)smallCapsFontNameforFontFamily:(NSString *)fontFamily bold:(BOOL)bold italic:(BOOL)italic
{
	@synchronized(_fontOverrides)
	{
		NSString *key = [NSString stringWithFormat:@"%@-%d-%d-smallcaps", fontFamily, bold, italic];
		return [_fontOverrides objectForKey:key];
	}
}

+ (void)setOverrideFontName:(NSString *)fontName forFontFamily:(NSString *)fontFamily bold:(BOOL)bold italic:(BOOL)italic
{
	@synchronized(_fontOverrides)
	{
		NSString *key = [NSString stringWithFormat:@"%@-%d-%d-override", fontFamily, bold, italic];
		[_fontOverrides setObject:fontName forKey:key];
	};
}

+ (NSString *)overrideFontNameforFontFamily:(NSString *)fontFamily bold:(BOOL)bold italic:(BOOL)italic
{
	@synchronized(_fontOverrides)
	{
		NSString *key = [NSString stringWithFormat:@"%@-%d-%d-override", fontFamily, bold, italic];
		return [_fontOverrides objectForKey:key];
	}
}

#pragma mark Initializing

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
		
		// also get family name
		
		CFStringRef familyName = CTFontDescriptorCopyAttribute(ctFontDescriptor, kCTFontFamilyNameAttribute);
		self.fontFamily = CFBridgingRelease(familyName);
	}
	
	return self;
}

- (id)initWithCTFont:(CTFontRef)ctFont
{
   NSParameterAssert(ctFont);
	
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
		
		// also get the family while we're at it
		CFStringRef cfStr = CTFontCopyFamilyName(ctFont);
		
		if (cfStr)
		{
			self.fontFamily = CFBridgingRelease(cfStr);
		}
		
		// look if this has synthetic italics
		CGAffineTransform transform = CTFontGetMatrix(ctFont);
		
		if (!CGAffineTransformIsIdentity(transform))
		{
			self.italicTrait = YES;
		}
	}
	
	return self;
}

#ifndef COVERAGE
// exclude method from coverage testing

- (NSString *)description
{
	NSMutableString *string = [NSMutableString string];
	
	[string appendFormat:@"<%@", [self class]];
	
	
	if (self.fontName)
	{
		[string appendFormat:@" name=\'%@\'", self.fontName];
	}
	
	if (_fontFamily)
	{
		[string appendFormat:@" family=\'%@\'", _fontFamily];
	}
	
	[string appendFormat:@" size:%.0f", _pointSize];
	
	NSMutableArray *tmpTraits = [NSMutableArray array];
	
	if (_stylisticTraits & kCTFontBoldTrait)
	{
		[tmpTraits addObject:@" bold"];
	}
	
	if (_stylisticTraits & kCTFontItalicTrait)
	{
		[tmpTraits addObject:@" italic"];
	}
	
	if (_stylisticTraits & kCTFontMonoSpaceTrait)
	{
		[tmpTraits addObject:@" monospace"];
	}
	
	if (_stylisticTraits & kCTFontCondensedTrait)
	{
		[tmpTraits addObject:@" condensed"];
	}
	
	if (_stylisticTraits & kCTFontExpandedTrait)
	{
		[tmpTraits addObject:@" expanded"];
	}
	
	if (_stylisticTraits & kCTFontVerticalTrait)
	{
		[tmpTraits addObject:@"vertical"];
	}
	
	if (_stylisticTraits & kCTFontUIOptimizedTrait)
	{
		[tmpTraits addObject:@" UI optimized"];
	}
	
	
	if ([tmpTraits count])
	{
		[string appendString:@" attributes="];
		[string appendString:[tmpTraits componentsJoinedByString:@", "]];
	}
	
	[string appendString:@">"];
	
	return string;
}

#endif

- (NSDictionary *)fontAttributes
{
	NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
	
	NSMutableDictionary *traitsDict = [NSMutableDictionary dictionary];
	
	CTFontSymbolicTraits theSymbolicTraits = _stylisticTraits | _stylisticClass;
	
	if (theSymbolicTraits)
	{
		[traitsDict setObject:[NSNumber numberWithUnsignedInt:theSymbolicTraits] forKey:(id)kCTFontSymbolicTrait];
	}
	
	if ([traitsDict count])
	{
		[tmpDict setObject:traitsDict forKey:(id)kCTFontTraitsAttribute];
	}
	
	if (_fontFamily)
	{
		[tmpDict setObject:_fontFamily forKey:(id)kCTFontFamilyNameAttribute];
	}
	
	if (_fontName)
	{
		[tmpDict setObject:_fontName forKey:(id)kCTFontNameAttribute];
	}
	
	// we need size because that's what makes a font unique, for searching it's ignored anyway
	[tmpDict setObject:DTNSNumberFromCGFloat(_pointSize) forKey:(id)kCTFontSizeAttribute];
	
	if (_smallCapsFeature)
	{
		NSNumber *typeNum = [NSNumber numberWithInteger:3];
		NSNumber *selNum = [NSNumber numberWithInteger:3];
		
		NSDictionary *setting = [NSDictionary dictionaryWithObjectsAndKeys:selNum, (id)kCTFontFeatureSelectorIdentifierKey,
										 typeNum, (id)kCTFontFeatureTypeIdentifierKey, nil];
		
		NSArray *featureSettings = [NSArray arrayWithObject:setting];
		
		[tmpDict setObject:featureSettings forKey:(id)kCTFontFeatureSettingsAttribute];
	}
	
	if (!self.boldTrait && _needsChineseFontCascadeFix)
	{
		CTFontDescriptorRef desc = CTFontDescriptorCreateWithNameAndSize(CFSTR("STHeitiSC-Light"), self.pointSize);
		
		[tmpDict setObject:[NSArray arrayWithObject:(__bridge_transfer id) desc] forKey:(id)kCTFontCascadeListAttribute];
	}
	
	//return [NSDictionary dictionaryWithDictionary:tmpDict];
	// converting to non-mutable costs 42% of entire method
	return tmpDict;
}

- (NSDictionary *)fontAttributesWithOverrideFontName:(NSString *)overrideFontName
{
	NSMutableDictionary *tmpAttributes = [[self fontAttributes] mutableCopy];
	
	// remove family
	[tmpAttributes removeObjectForKey:(id)kCTFontFamilyNameAttribute];
	
	// replace font name
	[tmpAttributes setObject:overrideFontName forKey:(id)kCTFontNameAttribute];
	
	return tmpAttributes;
}

- (BOOL)supportsNativeSmallCaps
{
	if ([DTCoreTextFontDescriptor smallCapsFontNameforFontFamily:_fontFamily bold:self.boldTrait italic:self.italicTrait])
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
	
	if (tmpFont)
	{
		CFRelease(tmpFont);
	}
	
	return smallCapsSupported;
}

#pragma mark Finding Font

- (BOOL)_fontIsOblique:(CTFontRef)font
{
	NSDictionary *traits = (__bridge_transfer NSDictionary *)CTFontCopyTraits(font);
	
	CGFloat slant = [[traits objectForKey:(id)kCTFontSlantTrait] floatValue];
	BOOL hasItalicTrait = ([[traits objectForKey:(id)kCTFontSymbolicTrait] unsignedIntValue] & kCTFontItalicTrait) ==kCTFontItalicTrait;
	
	if (!hasItalicTrait || slant<0.01)
	{
		return NO;
	}
	
	// font HAS italic trait AND sufficient slant angle
	return YES;
	
}

- (CTFontRef)_findOrMakeMatchingFont
{
	CTFontDescriptorRef searchingFontDescriptor = NULL;
	CTFontDescriptorRef matchingFontDescriptor = NULL;
	CTFontRef matchingFont = NULL;
	
	// check the cache first
	NSNumber *cacheKey = [NSNumber numberWithUnsignedInteger:[self hash]];
	
	CTFontRef cachedFont = (__bridge_retained CTFontRef)[_fontCache objectForKey:cacheKey];
	
	if (cachedFont)
	{
		return cachedFont;
	}
	
	// check the override table that has all preinstalled fonts plus the ones the user registered
	NSString *overrideName = nil;
	
	if (_fontFamily)
	{
		if (_smallCapsFeature)
		{
			overrideName = [DTCoreTextFontDescriptor smallCapsFontNameforFontFamily:_fontFamily bold:self.boldTrait italic:self.italicTrait];
		}
		else
		{
			overrideName = [DTCoreTextFontDescriptor overrideFontNameforFontFamily:_fontFamily bold:self.boldTrait italic:self.italicTrait];
		}
	}
	
	// if we use the chinese font cascade fix we cannot use fast method as it does not allow specifying the custom cascade list
	BOOL useFastFontCreation = !(_needsChineseFontCascadeFix && !self.boldTrait);
	
	if (useFastFontCreation && (_fontName || overrideName))
	{
		// we can create a font directly from the name
		NSString *usedName = overrideName?overrideName:_fontName;
		
		matchingFont = CTFontCreateWithName((__bridge CFStringRef)usedName, _pointSize, NULL);
	}
	else
	{
		// we need to search for a suitable font
		
		NSDictionary *fontAttributes;
		
		if (overrideName)
		{
			fontAttributes = [self fontAttributesWithOverrideFontName:overrideName];
		}
		else
		{
			fontAttributes = [self fontAttributes];
		}
		
		// the descriptor we are looking for
		searchingFontDescriptor = CTFontDescriptorCreateWithAttributes((__bridge CFDictionaryRef)fontAttributes);
		
		// the attributes that are mandatory
		NSMutableSet *mandatoryAttributes = [NSMutableSet setWithObject:(id)kCTFontTraitsAttribute];
		
		if (_fontFamily)
		{
			[mandatoryAttributes addObject:(id)kCTFontFamilyNameAttribute];
		}
		
		if (_smallCapsFeature)
		{
			[mandatoryAttributes addObject:(id)kCTFontFeaturesAttribute];
		}
		
		// do the search
		matchingFontDescriptor = CTFontDescriptorCreateMatchingFontDescriptor(searchingFontDescriptor, (__bridge CFSetRef)mandatoryAttributes);
		
		if (!matchingFontDescriptor)
		{
			// try without traits
			NSMutableDictionary *mutableAttributes = [fontAttributes mutableCopy];
			[mutableAttributes removeObjectForKey:(id)kCTFontTraitsAttribute];
			
			CFRelease(searchingFontDescriptor);
			searchingFontDescriptor = CTFontDescriptorCreateWithAttributes((__bridge CFDictionaryRef)mutableAttributes);
			
			// do the relaxed search
			matchingFontDescriptor = CTFontDescriptorCreateMatchingFontDescriptor(searchingFontDescriptor, NULL);
		}
		
		if (!matchingFontDescriptor)
		{
			// try with fallback font family
			NSMutableDictionary *mutableAttributes = [fontAttributes mutableCopy];
			[mutableAttributes setObject:_fallbackFontFamily forKey:(id)kCTFontFamilyNameAttribute];
			
			CFRelease(searchingFontDescriptor);
			searchingFontDescriptor = CTFontDescriptorCreateWithAttributes((__bridge CFDictionaryRef)mutableAttributes);
			
			// do the relaxed search
			matchingFontDescriptor = CTFontDescriptorCreateMatchingFontDescriptor(searchingFontDescriptor, NULL);
		}
	}
	
	// any search was successful
	if (matchingFontDescriptor)
	{
		matchingFont = CTFontCreateWithFontDescriptor(matchingFontDescriptor, _pointSize, NULL);
		
		CFRelease(matchingFontDescriptor);
	}
	
	if (searchingFontDescriptor)
	{
		CFRelease(searchingFontDescriptor);
	}
	
	// check if we indeed got an oblique font if we wanted one
	if (matchingFont && self.italicTrait && ![self _fontIsOblique:matchingFont])
	{
		// need to synthesize slant
		CGAffineTransform slantMatrix = { 1, 0, 0.25, 1, 0, 0 };
		
		CTFontRef slantedFont = CTFontCreateCopyWithAttributes(matchingFont, _pointSize, &slantMatrix, NULL);
		CFRelease(matchingFont);
		
		matchingFont = slantedFont;
	}
	
	// add found font to cache
	if (matchingFont)
	{
		[_fontCache setObject:(__bridge id)(matchingFont) forKey:cacheKey];
	}
	
	return matchingFont;	// returns a +1 reference
}

- (CTFontRef)newMatchingFont
{
	return [self _findOrMakeMatchingFont];
}

// two font descriptors are equal if their attributes has identical hash codes
- (NSUInteger)hash
{
	NSUInteger calcHash = 7;
	
	calcHash = calcHash*31 + (NSUInteger)_pointSize;
	calcHash = calcHash*31 + (_stylisticClass | _stylisticTraits);
	calcHash = calcHash*31 + [_fontName hash];
	calcHash = calcHash*31 + [_fontFamily hash];
	
	return calcHash;
}

- (BOOL)isEqual:(id)object
{
	if (!object)
	{
		return NO;
	}
	
	if (object == self)
	{
		return YES;
	}
	
	if (![object isKindOfClass:[DTCoreTextFontDescriptor class]])
	{
		return NO;
	}
	
	DTCoreTextFontDescriptor *otherFontDescriptor = object;
	
	if (_pointSize != otherFontDescriptor->_pointSize)
	{
		return NO;
	}
	
	if (_stylisticClass != otherFontDescriptor->_stylisticClass)
	{
		return NO;
	}
	
	if (_stylisticTraits != otherFontDescriptor->_stylisticTraits)
	{
		return NO;
	}

	if (_fontName != otherFontDescriptor->_fontName)
	{
		if (![_fontName isEqualToString:_fontName])
		{
			return NO;
		}
	}
	
	if (_fontFamily != otherFontDescriptor->_fontFamily)
	{
		if (![_fontFamily isEqualToString:_fontFamily])
		{
			return NO;
		}
	}
	
	return YES;
}


#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeObject:self.fontName forKey:@"FontName"];
	[encoder encodeObject:self.fontFamily forKey:@"FontFamily"];
	[encoder encodeBool:self.boldTrait forKey:@"BoldTrait"];
	[encoder encodeBool:self.italicTrait forKey:@"ItalicTrait"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super init];
	
	if (self)
	{
		self.fontName = [decoder decodeObjectForKey:@"FontName"];
		self.fontFamily = [decoder decodeObjectForKey:@"FontFamily"];
		self.boldTrait = [decoder decodeBoolForKey:@"BoldTrait"];
		self.italicTrait = [decoder decodeBoolForKey:@"ItalicTrait"];
	}
	
	return self;
}


#pragma mark Copying

- (id)copyWithZone:(NSZone *)zone
{
	DTCoreTextFontDescriptor *newDesc = [[DTCoreTextFontDescriptor allocWithZone:zone] initWithFontAttributes:[self fontAttributes]];
	newDesc.pointSize = self.pointSize;
	if (_stylisticClass)
	{
		newDesc.stylisticClass = self.stylisticClass;
	}
	
	return newDesc;
}


#pragma mark Properties
- (void)setStylisticClass:(CTFontStylisticClass)newClass
{
	self.fontFamily = nil;
	
	_stylisticClass = newClass;
}


- (void)setFontAttributes:(NSDictionary *)attributes
{
	if (!attributes)
	{
		self.fontFamily = nil;
		self.fontName = nil;
		self.pointSize = 12;
		
		_stylisticTraits = 0;
		_stylisticClass = 0;
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
		_pointSize = [pointNum floatValue];
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

- (CTFontSymbolicTraits)symbolicTraits
{
	// symbolic traits include both stylistic traits as well as stylistic class
	return _stylisticTraits | _stylisticClass;
}

- (void)setSymbolicTraits:(CTFontSymbolicTraits)theSymbolicTraits
{
	// symbolic traits include both stylistic traits as well as stylistic class
	_stylisticTraits = theSymbolicTraits & ~kCTFontClassMaskTrait;
	_stylisticClass = theSymbolicTraits & kCTFontClassMaskTrait;
}

// a representation of this font in CSS style
- (NSString *)cssStyleRepresentation
{
	NSMutableString *retString = [NSMutableString string];
	
	if (_fontFamily)
	{
		[retString appendFormat:@"font-family:'%@';", _fontFamily];
	}
	
	[retString appendFormat:@"font-size:%.0fpx;", _pointSize];
	
	if (self.italicTrait)
	{
		[retString appendString:@"font-style:italic;"];
	}
	
	if (self.boldTrait)
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

- (void)setBoldTrait:(BOOL)boldTrait
{
	if (boldTrait)
	{
		_stylisticTraits |= kCTFontBoldTrait;
	}
	else
	{
		_stylisticTraits &= ~kCTFontBoldTrait;
	}
}

- (BOOL)boldTrait
{
	return (_stylisticTraits & kCTFontBoldTrait)!=0;
}

- (void)setItalicTrait:(BOOL)italicTrait
{
	if (italicTrait)
	{
		_stylisticTraits |= kCTFontItalicTrait;
	}
	else
	{
		_stylisticTraits &= ~kCTFontItalicTrait;
	}
}

- (BOOL)italicTrait
{
	return (_stylisticTraits & kCTFontItalicTrait)!=0;
}

- (void)setExpandedTrait:(BOOL)expandedTrait
{
	if (expandedTrait)
	{
		_stylisticTraits |= kCTFontExpandedTrait;
	}
	else
	{
		_stylisticTraits &= ~kCTFontExpandedTrait;
	}
}

- (BOOL)expandedTrait
{
	return (_stylisticTraits & kCTFontExpandedTrait)!=0;
}

- (void)setCondensedTrait:(BOOL)condensedTrait
{
	if (condensedTrait)
	{
		_stylisticTraits |= kCTFontCondensedTrait;
	}
	else
	{
		_stylisticTraits &= ~kCTFontCondensedTrait;
	}
}

- (BOOL)condensedTrait
{
	return (_stylisticTraits & kCTFontCondensedTrait)!=0;
}

- (void)setMonospaceTrait:(BOOL)monospaceTrait
{
	if (monospaceTrait)
	{
		_stylisticTraits |= kCTFontMonoSpaceTrait;
	}
	else
	{
		_stylisticTraits &= ~kCTFontMonoSpaceTrait;
	}
}

- (BOOL)monospaceTrait
{
	return (_stylisticTraits & kCTFontMonoSpaceTrait)!=0;
}

- (void)setVerticalTrait:(BOOL)verticalTrait
{
	if (verticalTrait)
	{
		_stylisticTraits |= kCTFontVerticalTrait;
	}
	else
	{
		_stylisticTraits &= ~kCTFontVerticalTrait;
	}
}

- (BOOL)verticalTrait
{
	return (_stylisticTraits & kCTFontVerticalTrait)!=0;
}

- (void)setUIoptimizedTrait:(BOOL)UIoptimizedTrait
{
	if (UIoptimizedTrait)
	{
		_stylisticTraits |= kCTFontUIOptimizedTrait;
	}
	else
	{
		_stylisticTraits &= ~kCTFontUIOptimizedTrait;
	}
}

- (BOOL)UIoptimizedTrait
{
	return (_stylisticTraits & kCTFontUIOptimizedTrait)!=0;
}

- (void)setPointSize:(CGFloat)pointSize
{
	_pointSize = round(pointSize);
}

@synthesize fontFamily = _fontFamily;
@synthesize fontName = _fontName;
@synthesize pointSize = _pointSize;

@synthesize symbolicTraits;

@synthesize stylisticClass = _stylisticClass;
@synthesize smallCapsFeature = _smallCapsFeature;

@end
