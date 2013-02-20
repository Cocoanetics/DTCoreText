//
//  DTCoreTextFontCollection.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 5/23/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//



@class DTCoreTextFontDescriptor;

/**
 Class representing a collection of fonts
 */

@interface DTCoreTextFontCollection : NSObject 

/**
 @name Creating Font Collections
 */

/**
 Creates a font collection with all available fonts on the system
 */
+ (DTCoreTextFontCollection *)availableFontsCollection;

/**
 @name Getting Information about Font Collections
 */

/**
 The font family names that occur in the receiver's list of fonts
 */
- (NSArray *)fontFamilyNames;

/**
 The font descriptors describing all fonts in the receiver's font collection
 */
- (NSArray *)fontDescriptors;

/**
 @name Searching for Fonts
 */

/**
 The font descriptor describing a font in the receiver's collection that matches a given descriptor
 @param descriptor The font descriptor to search for
 @returns The first found font descriptor in the font collection
 */
- (DTCoreTextFontDescriptor *)matchingFontDescriptorForFontDescriptor:(DTCoreTextFontDescriptor *)descriptor;

@end
