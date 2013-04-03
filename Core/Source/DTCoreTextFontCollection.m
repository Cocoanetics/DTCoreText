//
//  DTCoreTextFontCollection.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 5/23/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCoreTextFontCollection.h"
#import "DTCoreTextFontDescriptor.h"

#if TARGET_OS_IPHONE
#import <CoreText/CoreText.h>
#elif TARGET_OS_MAC
#import <ApplicationServices/ApplicationServices.h>
#endif

@interface DTCoreTextFontCollection ()

@property (nonatomic, strong) NSArray *fontDescriptors;
@property (nonatomic, strong) NSCache *fontMatchCache;

- (id)initWithAvailableFonts;

@end

static DTCoreTextFontCollection *_availableFontsCollection = nil;


@implementation DTCoreTextFontCollection
{
	NSArray *_fontDescriptors;
	NSCache *_fontMatchCache;
}

+ (DTCoreTextFontCollection *)availableFontsCollection
{
	static dispatch_once_t predicate;

	dispatch_once(&predicate, ^{
		_availableFontsCollection = [[DTCoreTextFontCollection alloc] initWithAvailableFonts];
	});
	
	return _availableFontsCollection;
}

- (id)initWithAvailableFonts
{
	self = [super init];
	
	if (self)
	{
		
	}
	
	return self;
}


- (DTCoreTextFontDescriptor *)matchingFontDescriptorForFontDescriptor:(DTCoreTextFontDescriptor *)descriptor
{
	DTCoreTextFontDescriptor *firstMatch = nil;
	NSNumber *cacheKey = [NSString stringWithFormat:@"fontFamily BEGINSWITH[cd] %@ and boldTrait == %d and italicTrait == %d", descriptor.fontFamily, descriptor.boldTrait, descriptor.italicTrait];
	
	// try cache
	firstMatch = [self.fontMatchCache objectForKey:cacheKey];
	
	if (firstMatch)
	{
		DTCoreTextFontDescriptor *retMatch = [firstMatch copy];
		retMatch.pointSize = descriptor.pointSize;
		return retMatch;
	}
	
	// need to search
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"fontFamily BEGINSWITH[cd] %@ and boldTrait == %d and italicTrait == %d", descriptor.fontFamily, descriptor.boldTrait, descriptor.italicTrait];
	
	NSArray *matchingDescriptors = [self.fontDescriptors filteredArrayUsingPredicate:predicate];
	
	//NSLog(@"%@", matchingDescriptors);
	
	if ([matchingDescriptors count])
	{
		firstMatch = [matchingDescriptors objectAtIndex:0];
		[self.fontMatchCache setObject:firstMatch forKey:cacheKey];
		
		DTCoreTextFontDescriptor *retMatch = [firstMatch copy];
		
		retMatch.pointSize = descriptor.pointSize;
		return retMatch;
	}
	
	return nil;
}

#pragma mark Properties

- (NSArray *)fontDescriptors
{
	if (!_fontDescriptors)
	{
		CTFontCollectionRef fonts = CTFontCollectionCreateFromAvailableFonts(NULL);
		
		CFArrayRef matchingFonts = CTFontCollectionCreateMatchingFontDescriptors(fonts);
		
		if (matchingFonts)
		{
			// convert all to our objects
			NSMutableArray *tmpArray = [[NSMutableArray alloc] init];
			
			for (NSInteger i=0; i<CFArrayGetCount(matchingFonts); i++)
			{
				CTFontDescriptorRef fontDesc = CFArrayGetValueAtIndex(matchingFonts, i);
				
				
				DTCoreTextFontDescriptor *desc = [[DTCoreTextFontDescriptor alloc] initWithCTFontDescriptor:fontDesc];
				[tmpArray addObject:desc];
			}
			
			CFRelease(matchingFonts);
			
			self.fontDescriptors = tmpArray;
		}
		
		CFRelease(fonts);
	}
	
	return _fontDescriptors;
}

- (NSCache *)fontMatchCache
{
	if (!_fontMatchCache)
	{
		_fontMatchCache = [[NSCache alloc] init];
	}
	
	return _fontMatchCache;
}

- (NSArray *)fontFamilyNames
{
	NSMutableArray *tmpArray = [NSMutableArray array];
	
	for (DTCoreTextFontDescriptor *oneDescriptor in [self fontDescriptors])
	{
		NSString *familyName = oneDescriptor.fontFamily;
		
		if (![tmpArray containsObject:familyName])
		{
			[tmpArray addObject:familyName];
		}
	}
	
	return [tmpArray sortedArrayUsingSelector:@selector(compare:)];
}

@synthesize fontDescriptors = _fontDescriptors;
@synthesize fontMatchCache = _fontMatchCache;

@end
