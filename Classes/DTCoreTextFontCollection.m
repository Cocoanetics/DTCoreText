//
//  DTCoreTextFontCollection.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 5/23/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCoreTextFontCollection.h"
#import "DTCoreTextFontDescriptor.h"

#import <CoreText/CoreText.h>

static NSArray *_allFonts = nil;


@implementation DTCoreTextFontCollection

+ (NSArray *)availableFonts
{
	if (!_allFonts)
	{
		CTFontCollectionRef fonts = CTFontCollectionCreateFromAvailableFonts((CFDictionaryRef)[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:(id)kCTFontCollectionRemoveDuplicatesOption]);
		
		CFArrayRef matchingFonts = CTFontCollectionCreateMatchingFontDescriptors(fonts);
		
		// convert all to our objects
		
		NSMutableArray *tmpArray = [[NSMutableArray alloc] init];
		
		for (NSInteger i=0; i<CFArrayGetCount(matchingFonts); i++)
		{
			CTFontDescriptorRef fontDesc = CFArrayGetValueAtIndex(matchingFonts, i);
			
			DTCoreTextFontDescriptor *desc = [[DTCoreTextFontDescriptor alloc] initWithCTFontDescriptor:fontDesc];
			[tmpArray addObject:desc];
			[desc release];
		}
		
		_allFonts = [[NSArray alloc] initWithArray:tmpArray];		
		[tmpArray release];
	}
	
	return _allFonts;
}

@end
