//
//  DTCoreTextFontCollection.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 5/23/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//



@class DTCoreTextFontDescriptor;


@interface DTCoreTextFontCollection : NSObject 

+ (DTCoreTextFontCollection *)availableFontsCollection;

- (id)initWithAvailableFonts;

- (NSArray *)fontFamilyNames;
- (NSArray *)fontDescriptors;

- (DTCoreTextFontDescriptor *)matchingFontDescriptorForFontDescriptor:(DTCoreTextFontDescriptor *)descriptor;


@end
