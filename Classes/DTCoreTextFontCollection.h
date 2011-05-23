//
//  DTCoreTextFontCollection.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 5/23/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DTCoreTextFontDescriptor;

@interface DTCoreTextFontCollection : NSObject 
{
	NSArray *_fontDescriptors;
	NSCache *fontMatchCache;
}

+ (DTCoreTextFontCollection *)availableFontsCollection;

- (id)initWithAvailableFonts;

- (DTCoreTextFontDescriptor *)matchingFontDescriptorForFontDescriptor:(DTCoreTextFontDescriptor *)descriptor;


@end
